#!/usr/bin/env python3
# Load estimate for SPMS-1 (type-2): runs Spms1_main from the sketch's RP2350 ELF in Unicorn, an
# instruction emulator (Cortex-M33, Thumb-2 and the FPU), and counts the instructions each audio
# buffer takes between the start_debug_measure and stop_debug_measure calls the main loop makes
# around it -- the span the device's Debug Print measures -- and turns them into cycles and time
# by a first-order Cortex-M33 cost model (see cost below).
#
#   python3 sim_load/spms1_load_estimate.py ELF [--buffers N] [--skip N] [--note N] [--gate 0|1]
#                                           [--mhz F] [--profile]
#
# The instruction count is exact for the code as built; the cycles are an estimate, which a
# measurement on the device can calibrate. Needs: pip install unicorn capstone pyelftools numpy
import sys, struct, argparse, bisect
from elftools.elf.elffile import ELFFile
from unicorn import *
from unicorn.arm_const import *
from capstone import *
from capstone.arm import *

ap = argparse.ArgumentParser(description='Estimate the per-buffer load of the SPMS-1 (type-2) sketch')
ap.add_argument('elf', help='the sketch ELF, e.g. build/sim_load/spms1.ino.elf')
ap.add_argument('--buffers', type=int, default=12, help='buffers to run in all')
ap.add_argument('--skip', type=int, default=4, help='buffers left out of the statistics (warm-up)')
ap.add_argument('--note', type=int, default=69, help='the note held (MIDI note number)')
ap.add_argument('--gate', type=int, default=1, help='1 to hold the note, 0 for none')
ap.add_argument('--mhz', type=float, default=153.6, help='system clock, the sketch\'s 153.6 MHz by default')
ap.add_argument('--profile', action='store_true', help='print the functions the measured buffers spend the most cycles in')
args = ap.parse_args()

f = open(args.elf, 'rb')
elf = ELFFile(f)
syms = {}
symlist = []
for sec in elf.iter_sections():
    if sec.name == '.symtab':
        for s in sec.iter_symbols():
            if s['st_info']['type'] == 'STT_FUNC' and s['st_value']:
                syms[s.name] = s['st_value'] & ~1
                symlist.append((s['st_value'] & ~1, s['st_size'], s.name))
symlist.sort()
symaddrs = [a for a, _, _ in symlist]
def sym_of(addr):
    i = bisect.bisect_right(symaddrs, addr) - 1
    if i >= 0:
        a, size, n = symlist[i]
        if addr < a + max(size, 2):
            return n
    return '?'

mu = Uc(UC_ARCH_ARM, UC_MODE_THUMB | UC_MODE_MCLASS)
# Flash (XIP), SRAM, and the peripheral, SIO and PPB regions mapped as plain memory, so that a
# stray access reads or writes something rather than faulting.
for base, size in [(0x10000000, 0x01000000), (0x20000000, 0x00100000), (0x40000000, 0x00200000),
                   (0x50000000, 0x00200000), (0xd0000000, 0x00010000), (0xe0000000, 0x00100000)]:
    mu.mem_map(base, size)
for seg in elf.iter_segments():
    if seg['p_type'] != 'PT_LOAD':
        continue
    data = seg.data()
    for addr in {seg['p_paddr'], seg['p_vaddr']}:
        try:
            mu.mem_write(addr, data)
            if seg['p_memsz'] > seg['p_filesz'] and addr == seg['p_vaddr']:
                mu.mem_write(addr + seg['p_filesz'], b'\0' * (seg['p_memsz'] - seg['p_filesz']))
        except UcError:
            pass
# Spinlocks read as acquired.
mu.mem_write(0xd0000100, b'\x01\0\0\0' * 32)
# FPU on: CPACR CP10/CP11 full access.
mu.mem_write(0xe000ed88, struct.pack('<I', 0xf << 20))

STACK_TOP = 0x20080000 - 0x100
mu.reg_write(UC_ARM_REG_SP, STACK_TOP)
RET_MAGIC = 0x10fffff0
mu.mem_write(RET_MAGIC, b'\xfe\xe7')  # b .

md = Cs(CS_ARCH_ARM, CS_MODE_THUMB | CS_MODE_MCLASS | CS_MODE_V8)
md.detail = True

# Cortex-M33 cost model, cycles per instruction, first-order: 1 for most, 2 for a single load, one
# more per register for a multiple load or store, 3 for a fused or chained floating-point multiply-
# add, 6 for an integer divide and 14 for a floating-point divide or square root, and 2 more after
# a taken branch for the pipeline refill. No wait states: Spms1_main runs from SRAM, and the few
# helpers it calls in flash stay in the XIP cache.
def cost(insn):
    m = insn.mnemonic.split('.')[0]
    if m in ('vdiv', 'vsqrt'):
        return 14
    if m in ('sdiv', 'udiv'):
        return 6
    if m in ('ldm', 'ldmia', 'ldmdb', 'stm', 'stmia', 'stmdb', 'push', 'pop', 'vpush', 'vpop', 'vldmia', 'vstmia', 'vldmdb', 'vstmdb', 'vldm', 'vstm'):
        regs = sum(1 for op in insn.operands if op.type == ARM_OP_REG)
        if m in ('ldm', 'ldmia', 'ldmdb', 'stm', 'stmia', 'stmdb', 'vldm', 'vstm', 'vldmia', 'vstmia', 'vldmdb', 'vstmdb'):
            regs -= 1
        return 1 + max(regs, 1)
    if m.startswith('ld') or m.startswith('vldr'):
        return 2
    if m in ('vmla', 'vmls', 'vfma', 'vfms', 'vnmla', 'vnmls'):
        return 3
    return 1

insn_cache = {}
def decode(addr, size):
    c = insn_cache.get(addr)
    if c is None:
        code = bytes(mu.mem_read(addr, size))
        insn = next(md.disasm(code, addr), None)
        c = (cost(insn) if insn else 1, insn.mnemonic if insn else '?')
        insn_cache[addr] = c
    return c

state = {'measuring': False, 'n': 0, 'cyc': 0, 'last_end': None, 'buffers': [], 'prof': {}}
stubs = {}

def ret(uc, value=None):
    if value is not None:
        uc.reg_write(UC_ARM_REG_R0, value & 0xffffffff)
    lr = uc.reg_read(UC_ARM_REG_LR)
    uc.reg_write(UC_ARM_REG_PC, lr | 1)

def stub_start_debug(uc):
    state['measuring'] = True
    state['n'] = 0
    state['cyc'] = 0
    state['prof'] = {}
    ret(uc)
def stub_stop_debug(uc):
    state['measuring'] = False
    state['buffers'].append((state['n'], state['cyc'], dict(state['prof'])))
    if len(state['buffers']) >= args.buffers:
        uc.emu_stop()
    ret(uc)
def stub_void(uc):
    ret(uc)

def stub_note_pitch(uc): ret(uc, args.note)
def stub_note_state(uc): ret(uc, args.gate)

for name, fn in [('start_debug_measure', stub_start_debug), ('stop_debug_measure', stub_stop_debug),
                 ('write_to_audio_buffer', stub_void), ('start_audio', stub_void), ('stop_audio', stub_void),
                 ('get_midi_note_on_pitch', stub_note_pitch), ('get_midi_note_on_state', stub_note_state)]:
    if name in syms:
        stubs[syms[name]] = fn

# Library helpers that run on the RP2350's coprocessors, which Unicorn lacks, are computed here
# instead: the double-precision ones of the pico SDK (the DCP) and the float maths it wraps. The
# sketch uses floats throughout and calls them only while it sets up, but should one run inside a
# measured buffer it is counted at the cycles given, a rough figure for each, and listed.
import math
import numpy as np
def f32(x): return struct.unpack('<f', struct.pack('<I', x & 0xffffffff))[0]
def bits32(v): return struct.unpack('<I', struct.pack('<f', float(np.float32(v))))[0]
def f64(lo, hi): return struct.unpack('<d', struct.pack('<II', lo & 0xffffffff, hi & 0xffffffff))[0]
def ret64(uc, v):
    lo, hi = struct.unpack('<II', struct.pack('<d', v))
    uc.reg_write(UC_ARM_REG_R1, hi)
    ret(uc, lo)
def regs(uc, n): return [uc.reg_read(r) for r in (UC_ARM_REG_R0, UC_ARM_REG_R1, UC_ARM_REG_R2, UC_ARM_REG_R3)[:n]]
def sint(x, bits): return x - (1 << bits) if x >> (bits - 1) else x
def dargs(uc):
    a, b, c, d = regs(uc, 4)
    return f64(a, b), f64(c, d)
def safe(fn, *a):
    try:
        return fn(*a)
    except (ValueError, OverflowError, ZeroDivisionError):
        return float('nan')
def sincosf(uc):
    x = f32(regs(uc, 1)[0])
    s_ptr, c_ptr = regs(uc, 3)[1:3]
    uc.mem_write(s_ptr, struct.pack('<I', bits32(math.sin(x))))
    uc.mem_write(c_ptr, struct.pack('<I', bits32(math.cos(x))))
    ret(uc)
helpers = {
    '__wrap_powf': (lambda uc: ret(uc, bits32(safe(math.pow, f32(regs(uc, 2)[0]), f32(regs(uc, 2)[1])))), 150),
    '__wrap_logf': (lambda uc: ret(uc, bits32(safe(math.log, f32(regs(uc, 1)[0])))), 100),
    '__wrap_tanf': (lambda uc: ret(uc, bits32(math.tan(f32(regs(uc, 1)[0])))), 100),
    '__wrap_sinf': (lambda uc: ret(uc, bits32(math.sin(f32(regs(uc, 1)[0])))), 80),
    '__wrap_cosf': (lambda uc: ret(uc, bits32(math.cos(f32(regs(uc, 1)[0])))), 80),
    '__wrap_sincosf': (sincosf, 120),
    '__wrap_exp': (lambda uc: ret64(uc, safe(math.exp, dargs(uc)[0])), 200),
    '__wrap_log': (lambda uc: ret64(uc, safe(math.log, dargs(uc)[0])), 200),
    '__wrap___aeabi_dadd': (lambda uc: ret64(uc, sum(dargs(uc))), 10),
    '__wrap___aeabi_dsub': (lambda uc: ret64(uc, dargs(uc)[0] - dargs(uc)[1]), 10),
    '__wrap___aeabi_dmul': (lambda uc: ret64(uc, dargs(uc)[0] * dargs(uc)[1]), 10),
    '__wrap___aeabi_ddiv': (lambda uc: ret64(uc, safe(lambda a, b: a / b, *dargs(uc))), 30),
    '__wrap___aeabi_d2f': (lambda uc: ret(uc, bits32(dargs(uc)[0])), 5),
    '__wrap___aeabi_i2d': (lambda uc: ret64(uc, float(sint(regs(uc, 1)[0], 32))), 5),
    '__wrap___aeabi_ui2d': (lambda uc: ret64(uc, float(regs(uc, 1)[0])), 5),
    '__wrap___aeabi_l2d': (lambda uc: ret64(uc, float(sint(regs(uc, 2)[0] | regs(uc, 2)[1] << 32, 64))), 8),
    '__wrap___aeabi_ul2d': (lambda uc: ret64(uc, float(regs(uc, 2)[0] | regs(uc, 2)[1] << 32)), 8),
    '__wrap___aeabi_d2iz': (lambda uc: ret(uc, int(dargs(uc)[0])), 5),
    '__wrap___aeabi_d2uiz': (lambda uc: ret(uc, int(dargs(uc)[0])), 5),
    '__wrap___aeabi_dcmpeq': (lambda uc: ret(uc, int(dargs(uc)[0] == dargs(uc)[1])), 5),
    '__wrap___aeabi_dcmplt': (lambda uc: ret(uc, int(dargs(uc)[0] < dargs(uc)[1])), 5),
    '__wrap___aeabi_dcmple': (lambda uc: ret(uc, int(dargs(uc)[0] <= dargs(uc)[1])), 5),
    '__wrap___aeabi_dcmpgt': (lambda uc: ret(uc, int(dargs(uc)[0] > dargs(uc)[1])), 5),
    '__wrap___aeabi_dcmpge': (lambda uc: ret(uc, int(dargs(uc)[0] >= dargs(uc)[1])), 5),
    '__wrap___aeabi_dcmpun': (lambda uc: ret(uc, int(math.isnan(dargs(uc)[0]) or math.isnan(dargs(uc)[1]))), 5),
}
def d2lz(uc):
    v = int(dargs(uc)[0]) & 0xffffffffffffffff
    uc.reg_write(UC_ARM_REG_R1, v >> 32)
    ret(uc, v & 0xffffffff)
helpers['__wrap___aeabi_d2lz'] = (d2lz, 8)
helper_calls = {}
def make_helper(name, fn, cycles):
    def run(uc):
        if state['measuring']:
            state['cyc'] += cycles
            helper_calls[name] = helper_calls.get(name, 0) + 1
        fn(uc)
    return run
for name, (fn, cycles) in helpers.items():
    if name in syms:
        stubs[syms[name]] = make_helper(name, fn, cycles)

# The hardware is stood in for: the audio output and the debug timer by the stubs above, and the
# locks by returning at once, as a single core with nothing else running never waits for one.
for name, a in syms.items():
    if 'mutex' in name:
        stubs.setdefault(a, stub_void)

def hook_code(uc, addr, size, _):
    fn = stubs.get(addr)
    if fn:
        fn(uc)
        return
    if state['measuring']:
        c, m = decode(addr, size)
        last = state['last_end']
        if last is not None and last != addr:
            state['cyc'] += 2  # the branch before this instruction was taken
        state['n'] += 1
        state['cyc'] += c
        state['last_end'] = addr + size
        if args.profile:
            s = sym_of(addr)
            p = state['prof']
            p[s] = p.get(s, 0) + c
    else:
        state['last_end'] = None

mu.hook_add(UC_HOOK_CODE, hook_code)

main = syms['Spms1_main']
mu.reg_write(UC_ARM_REG_LR, RET_MAGIC | 1)
mu.reg_write(UC_ARM_REG_R0, 0)
mu.reg_write(UC_ARM_REG_R1, 0)

try:
    mu.emu_start(main | 1, RET_MAGIC, count=2_000_000_000)
except UcError as e:
    pc = mu.reg_read(UC_ARM_REG_PC)
    print('emulation stopped: %s at 0x%08x (%s)' % (e, pc, sym_of(pc)), file=sys.stderr)
    sys.exit(1)

bufs = state['buffers'][args.skip:]
if not bufs:
    print('no buffers measured', file=sys.stderr)
    sys.exit(1)
ns = [b[0] for b in bufs]
cs = [b[1] for b in bufs]
budget_us = 64 / 48000 * 1e6
avg_c = sum(cs) / len(cs)
print('buffers measured: %d (after %d warm-up)' % (len(bufs), args.skip))
print('instructions per buffer: min %d, avg %.0f, max %d' % (min(ns), sum(ns) / len(ns), max(ns)))
print('estimated cycles per buffer: min %d, avg %.0f, max %d' % (min(cs), avg_c, max(cs)))
print('estimated time per buffer at %.1f MHz: avg %.0f us, max %.0f us, of %.0f us (%.0f%% / %.0f%%)' % (
    args.mhz, avg_c / args.mhz, max(cs) / args.mhz, budget_us, 100 * avg_c / args.mhz / budget_us, 100 * max(cs) / args.mhz / budget_us))
print('per sample: %.0f instructions, %.0f cycles' % (sum(ns) / len(ns) / 64, avg_c / 64))
if helper_calls:
    print('library helpers called inside measured buffers (counted at a rough cost):')
    for k, v in sorted(helper_calls.items()):
        print('  %s: %d' % (k, v))
if args.profile:
    tot = {}
    for b in bufs:
        for k, v in b[2].items():
            tot[k] = tot.get(k, 0) + v
    allc = sum(tot.values())
    for k, v in sorted(tot.items(), key=lambda kv: -kv[1])[:15]:
        print('  %5.1f%%  %s' % (100 * v / allc, k))
