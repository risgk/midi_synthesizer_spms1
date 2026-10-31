#!/usr/bin/env python3
# Load estimate for SPMS-1 (type-2): runs Spms1_main from the sketch's RP2350 ELF in Unicorn, an
# instruction emulator (Cortex-M33, Thumb-2 and the FPU), and counts the instructions each audio
# buffer takes between the start_debug_measure and stop_debug_measure calls the main loop makes
# around it -- the span the device's Debug Print measures -- and turns them into cycles and time
# by a first-order Cortex-M33 cost model (see cost below).
#
#   python3 sim_load/spms1_load_estimate.py ELF [--buffers N] [--skip N] [--note N] [--gate 0|1]
#                                           [--patch FILE] [--score FILE] [--per-buffer]
#                                           [--mhz F] [--profile] [--modules] [--lines N]
#
# --patch and --score take the files sim_render takes (see sim_render/examples): the patch as MIDI
# bytes in hex, applied before the first buffer, and the score, MIDI bytes in hex at a time in
# seconds, each applied before the buffer that time falls in (48 kHz, 64 samples a buffer). They
# reach the tables the sketch's MIDI handlers fill (the CC values, the NRPN table and the run
# order's writes, Pitch Bend) and the note the stubs give, as spms1_midi_state.h handles them; Note
# On and Off move the note from --note and --gate. --per-buffer prints each measured buffer.
# --lines N prints the N source lines the measured buffers spend the most cycles in, by the line
# table of the debug info: the .rb lines Spinel's #line directives name, or the C runtime's.
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
ap.add_argument('--patch', help='a patch, MIDI bytes in hex (as sim_render --patch), applied before the first buffer')
ap.add_argument('--score', help='MIDI bytes in hex at times in seconds (as sim_render --score), each before its buffer')
ap.add_argument('--per-buffer', action='store_true', help='print the instructions and cycles of each measured buffer')
ap.add_argument('--mhz', type=float, default=153.6, help='system clock, the sketch\'s 153.6 MHz by default')
ap.add_argument('--profile', action='store_true', help='print the functions the measured buffers spend the most cycles in')
ap.add_argument('--modules', action='store_true', help='print the load of each module, also with its share of the common part (from the debug info)')
ap.add_argument('--lines', type=int, default=0, help='print the N source lines the measured buffers spend the most cycles in (from the debug info)')
args = ap.parse_args()

f = open(args.elf, 'rb')
elf = ELFFile(f)
syms = {}
objs = {}
symlist = []
for sec in elf.iter_sections():
    if sec.name == '.symtab':
        for s in sec.iter_symbols():
            if s['st_info']['type'] == 'STT_FUNC' and s['st_value']:
                syms[s.name] = s['st_value'] & ~1
                symlist.append((s['st_value'] & ~1, s['st_size'], s.name))
            elif s['st_info']['type'] == 'STT_OBJECT' and s['st_value']:
                objs[s.name] = s['st_value']
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

state = {'measuring': False, 'n': 0, 'cyc': 0, 'last_end': None, 'buffers': [], 'prof': {}, 'lines': {}}
stubs = {}

def ret(uc, value=None):
    if value is not None:
        uc.reg_write(UC_ARM_REG_R0, value & 0xffffffff)
    lr = uc.reg_read(UC_ARM_REG_LR)
    uc.reg_write(UC_ARM_REG_PC, lr | 1)

# --patch and --score: the MIDI the sketch's handlers would have taken (spms1_midi_state.h), written
# into its tables in the emulated RAM. The note is the stubs' (below), from --note and --gate.
SAMPLE_RATE, BUFFER_WORDS = 48000, 64
NRPN_SIZE, NRPN_MSB_BASE, NRPN_SYSTEM_MSB, RUN_ORDER_SIZE, NO_NOTE = 640, 112, 117, 32, 0xFF
def hex_bytes(text):
    return [int(b, 16) for b in text.split(';', 1)[0].replace(',', ' ').split()]
events = []  # (buffer, order, bytes)
if args.patch:
    events += [(0, i, hex_bytes(line)) for i, line in enumerate(open(args.patch))]
if args.score:
    for i, line in enumerate(open(args.score)):
        line = line.split(';', 1)[0].strip()
        if line:
            t, _, rest = line.partition(' ')
            events.append((int(float(t) * SAMPLE_RATE) // BUFFER_WORDS, len(events) + i, hex_bytes(rest)))
events.sort()
midi = {'status': 0, 'data': [], 'msb': [0] * 16, 'lsb': [0] * 16, 'selected': [0] * 16,
        'note': [args.note] * 16, 'on': [args.gate] * 16, 'prev': [NO_NOTE] * 16}
def mem_u8(name, index, value): mu.mem_write(objs[name] + index, bytes([value & 0xff]))
def mem_read_u32(name, index): return struct.unpack('<I', bytes(mu.mem_read(objs[name] + 4 * index, 4)))[0]
def mem_u32(name, index, value): mu.mem_write(objs[name] + 4 * index, struct.pack('<I', value & 0xffffffff))
def set_nrpn(ch, index, value):
    if 0 <= index < NRPN_SIZE:
        mem_u8('g_midi_nrpn_values', ch * NRPN_SIZE + index, value)
        if index < RUN_ORDER_SIZE:
            writes = mem_read_u32('g_midi_run_order_writes', ch) + 1
            mem_u32('g_midi_run_order_writes', ch, writes)
            mem_u32('g_midi_run_order_written', ch * RUN_ORDER_SIZE + index, writes)
def note_off(ch, pitch):
    if pitch == midi['note'][ch]:
        if midi['prev'][ch] != NO_NOTE:
            midi['note'][ch], midi['prev'][ch] = midi['prev'][ch], NO_NOTE
        else:
            midi['on'][ch] = 0
    elif pitch == midi['prev'][ch]:
        midi['prev'][ch] = NO_NOTE
def message(status, d1, d2):
    ch, kind = status & 0x0F, status & 0xF0
    if kind == 0x80 or (kind == 0x90 and d2 == 0):
        note_off(ch, d1)
    elif kind == 0x90:
        if not midi['on'][ch]:
            midi['prev'][ch] = NO_NOTE
        elif d1 != midi['note'][ch]:
            midi['prev'][ch] = midi['note'][ch]
        midi['note'][ch], midi['on'][ch] = d1, 1
    elif kind == 0xB0 and d1 < 120:
        mem_u8('g_midi_cc_values', ch * 128 + d1, d2)
        if d1 == 99:
            midi['msb'][ch], midi['selected'][ch] = d2, 1
        elif d1 == 98:
            midi['lsb'][ch], midi['selected'][ch] = d2, 1
        elif d1 in (100, 101):
            midi['selected'][ch] = 0
        elif d1 == 6 and midi['selected'][ch] and NRPN_MSB_BASE <= midi['msb'][ch] != NRPN_SYSTEM_MSB:
            set_nrpn(ch, ((midi['msb'][ch] - NRPN_MSB_BASE) << 7) | midi['lsb'][ch], d2)
    elif kind == 0xE0:
        mu.mem_write(objs['g_midi_pitch_bend'] + 2 * ch, struct.pack('<h', ((d2 << 7) | d1) - 8192))
def midi_byte(b):
    if b >= 0xF8:
        return
    if b >= 0x80:
        midi['status'], midi['data'] = (b if b < 0xF0 else 0), []
        return
    if midi['status']:
        midi['data'].append(b)
        length = 1 if (midi['status'] & 0xE0) == 0xC0 else 2
        if len(midi['data']) == length:
            message(midi['status'], midi['data'][0], midi['data'][1] if length == 2 else 0)
            midi['data'] = []

def stub_start_debug(uc):
    while events and events[0][0] <= len(state['buffers']):
        for b in events.pop(0)[2]:
            midi_byte(b)
    state['measuring'] = True
    state['n'] = 0
    state['cyc'] = 0
    state['prof'] = {}
    ret(uc)
def stub_stop_debug(uc):
    state['measuring'] = False
    state['buffers'].append((state['n'], state['cyc'], dict(state['prof'])))
    if len(state['buffers']) <= args.skip:
        state['lines'] = {}  # the warm-up left out
    if len(state['buffers']) >= args.buffers:
        uc.emu_stop()
    ret(uc)
def stub_void(uc):
    ret(uc)

def stub_note_pitch(uc): ret(uc, midi['note'][regs(uc, 1)[0] & 15])
def stub_note_state(uc): ret(uc, midi['on'][regs(uc, 1)[0] & 15])

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
            c_taken = c + 2
        else:
            c_taken = c
        state['n'] += 1
        state['cyc'] += c
        state['last_end'] = addr + size
        if args.modules:
            modules_hook(uc, addr, size, c_taken)
        if args.lines:
            lc = state['lines']
            lc[addr] = lc.get(addr, 0) + c_taken
        if args.profile:
            s = sym_of(addr)
            p = state['prof']
            p[s] = p.get(s, 0) + c
    else:
        state['last_end'] = None

# --modules: the load of each module. The cycles of its methods inlined into Spms1_main (process,
# its outputs, smooth_parameters; their spans from the debug info) are its own; and by the run, the
# code from the dispatch of the run order (the jump table of `case module_id`) to its last own or bus
# write instruction (the bus reads of its inputs and the writes of its outputs) is its share of the
# common part, with the rest of the dispatch loop (the code after it that the modules share) split
# evenly over them; from the output of a sample (audio_buffer_l[i] = ...) to the dispatch of the
# first module of the next (the loop of the samples, MIDI, the CCs, smooth_parameters) is the common
# part left, but the methods of a module there (smooth_parameters) are its own.
if args.modules:
    import os, re
    def die_name(die):
        for _ in range(5):
            n = die.attributes.get('DW_AT_name')
            if n:
                return n.value.decode()
            o = die.attributes.get('DW_AT_abstract_origin') or die.attributes.get('DW_AT_specification')
            if not o:
                return '?'
            die = die.get_DIE_from_attribute(o.name)
        return '?'
    dw = elf.get_dwarf_info()
    rl = dw.range_lists()
    def die_ranges(die, cu):
        a = die.attributes
        if 'DW_AT_low_pc' in a and 'DW_AT_high_pc' in a:
            lo = a['DW_AT_low_pc'].value
            hi = a['DW_AT_high_pc'].value
            return [(lo, hi if a['DW_AT_high_pc'].form == 'DW_FORM_addr' else lo + hi)]
        out = []
        if 'DW_AT_ranges' in a:
            base = cu.get_top_DIE().attributes.get('DW_AT_low_pc')
            base = base.value if base else 0
            for e in rl.get_range_list_at_offset(a['DW_AT_ranges'].value, cu=cu):
                if hasattr(e, 'base_address'):
                    base = e.base_address
                elif hasattr(e, 'begin_offset'):
                    out.append((e.begin_offset + base, e.end_offset + base))
        return out
    span_of = {}  # address -> name of the method inlined into Spms1_main at its top level
    for cu in dw.iter_CUs():
        for top in cu.iter_DIEs():
            if top.tag == 'DW_TAG_subprogram' and die_name(top) == 'Spms1_main' and die_ranges(top, cu):
                def walk(die):
                    for ch in die.iter_children():
                        if ch.tag == 'DW_TAG_inlined_subroutine':
                            name = die_name(ch)
                            for lo, hi in die_ranges(ch, cu):
                                for a in range(lo & ~1, hi, 2):
                                    span_of.setdefault(a, name)
                        elif ch.tag == 'DW_TAG_lexical_block':
                            walk(ch)
                walk(top)
    # The modules of the dispatch, by their ids, as patch_gen writes them in spms1_main.rb
    src = open(os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'spms1', 'spms1_main.rb')).read()
    classes = dict(re.findall(r'^(\w+) = (\w+)\.new\(', src, re.M))
    dispatch_ids = [(int(i), v) for i, v in re.findall(r'^\s*when (\d+) # MODULE_\w+\n\s*(?:signals\[\d+\] = )?(\w+)\.', src, re.M)]
    dispatch_ids.sort()
    jump = {}  # jump table instruction -> index register
    def jump_index_reg(addr, size):
        if addr not in jump:
            insn = next(md.disasm(bytes(mu.mem_read(addr, size)), addr), None)
            reg = None
            if insn and insn.mnemonic in ('tbb', 'tbh'):
                reg = insn.operands[0].mem.index
            jump[addr] = reg
        return jump[addr]
    mstate = {'tbb': {}, 'dispatch': None, 'module': None, 'pending': [], 'left': 0}
    own, shared_own, common, tails = {}, {}, {}, {}
    def modules_hook(uc, addr, size, c):
        reg = jump_index_reg(addr, size)
        if len(state['buffers']) < args.skip:
            if reg is not None:  # the warm-up finds the dispatch: the jump table of the most indices
                mstate['tbb'].setdefault(addr, set()).add(uc.reg_read(reg))
            return
        if mstate['dispatch'] is None:  # the jump tables of as many indices as the modules (GCC may copy the loop)
            mstate['dispatch'] = {a: dict(zip(sorted(v), [m for _, m in dispatch_ids]))
                                  for a, v in mstate['tbb'].items() if len(v) == len(dispatch_ids)}
        if addr in mstate['dispatch']:
            m = mstate['module']
            for a, cc in mstate['pending']:  # the tail of the module before: its dispatch loop
                tails.setdefault(a, {})
                tails[a][m] = tails[a].get(m, 0) + cc
            mstate['pending'] = []
            mstate['module'] = mstate['dispatch'][addr].get(uc.reg_read(reg))
        m = mstate['module']
        name = span_of.get(addr)
        if m is None:  # out of the dispatch loop: from the output of a sample to the first module of the next
            mstate['left'] += c
            return
        if name == 'sp_FloatArray_set':  # the output of the sample (audio_buffer_l[i] = ...): out of the loop
            for a, cc in mstate['pending']:
                tails.setdefault(a, {})
                tails[a][m] = tails[a].get(m, 0) + cc
            mstate['pending'] = []
            mstate['module'] = None
            mstate['left'] += c
            return
        cls = name and re.match(r'sp_([A-Z]\w*?)_', name)
        if cls and cls.group(1) in classes.values():
            if m and classes[m] == cls.group(1):
                own[m] = own.get(m, 0) + c
            else:  # e.g. smooth_parameters, before the dispatch
                shared_own[cls.group(1)] = shared_own.get(cls.group(1), 0) + c
            anchor = True
        else:
            anchor = name == 'sp_SignalBus__lb_rb_set'
            mstate['pending'].append((addr, c))
        if anchor and m:
            for a, cc in mstate['pending']:
                common[m] = common.get(m, 0) + cc
            mstate['pending'] = []
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
if args.per_buffer:
    for i, (n, c, _) in enumerate(bufs):
        print('  buffer %d: %d instructions, %d cycles, %.0f us' % (args.skip + i, n, c, c / args.mhz))
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

if args.lines:
    import os
    # Each address to the row of the line table it falls in: the rows sorted by address, the last
    # at or below it.
    rows = []
    for cu in elf.get_dwarf_info().iter_CUs():
        lp = elf.get_dwarf_info().line_program_for_CU(cu)
        if lp is None:
            continue
        files = lp['file_entry']
        base = 1 if lp.header['version'] < 5 else 0
        for e in lp.get_entries():
            st = e.state
            if st is None:
                continue
            if st.end_sequence:
                rows.append((st.address, None))
                continue
            fe = files[st.file - base]
            rows.append((st.address, '%s:%d' % (os.path.basename(fe.name.decode()), st.line)))
    rows.sort(key=lambda r: r[0])
    row_addrs = [r[0] for r in rows]
    # A line of the runtime (a C header) or of Dsp is told by the .rb line it was inlined at: the
    # call sites of the inlined subroutines around the address, innermost first, up to the first
    # in another .rb file.
    inl = []  # (low, high, the call sites from the innermost out)
    dwi = elf.get_dwarf_info()
    rlists = dwi.range_lists()
    for cu in dwi.iter_CUs():
        lp = dwi.line_program_for_CU(cu)
        if lp is None:
            continue
        fes = lp['file_entry']
        fbase = 1 if lp.header['version'] < 5 else 0
        def walk(die, sites):
            for ch in die.iter_children():
                s = sites
                if ch.tag == 'DW_TAG_inlined_subroutine' and 'DW_AT_call_file' in ch.attributes:
                    fn = os.path.basename(fes[ch.attributes['DW_AT_call_file'].value - fbase].name.decode())
                    s = ['%s:%d' % (fn, ch.attributes['DW_AT_call_line'].value)] + sites
                    a = ch.attributes
                    spans = []
                    if 'DW_AT_low_pc' in a and 'DW_AT_high_pc' in a:
                        lo = a['DW_AT_low_pc'].value
                        hi = a['DW_AT_high_pc'].value
                        spans.append((lo, hi if a['DW_AT_high_pc'].form == 'DW_FORM_addr' else lo + hi))
                    elif 'DW_AT_ranges' in a:
                        base = cu.get_top_DIE().attributes.get('DW_AT_low_pc')
                        base = base.value if base else 0
                        for e in rlists.get_range_list_at_offset(a['DW_AT_ranges'].value, cu=cu):
                            if hasattr(e, 'base_address'):
                                base = e.base_address
                            elif hasattr(e, 'begin_offset'):
                                spans.append((e.begin_offset + base, e.end_offset + base))
                    for lo, hi in spans:
                        inl.append((lo, hi, s))
                if ch.has_children:
                    walk(ch, s)
        walk(cu.get_top_DIE(), [])
    def caller(a, k):
        best = None
        for lo, hi, s in inl:
            if lo <= a < hi and (best is None or hi - lo < best[1] - best[0]):
                best = (lo, hi, s)
        if not best:
            return k
        for site in best[2]:
            if site.endswith('.h', 0, site.rfind(':')) or site.startswith('spms1_dsp.rb') or site.startswith('sp_'):
                continue
            return '%s <- %s' % (k, site)
        return k
    by_line = {}
    for a, cc in state['lines'].items():
        i = bisect.bisect_right(row_addrs, a) - 1
        k = rows[i][1] if i >= 0 and rows[i][1] else '?'
        if k.split(':')[0].endswith('.h') or k.startswith('spms1_dsp.rb'):
            k = caller(a, k)
        by_line[k] = by_line.get(k, 0) + cc
    allc = sum(by_line.values())
    print('source lines, per buffer:')
    for k, v in sorted(by_line.items(), key=lambda kv: -kv[1])[:args.lines]:
        print('  %5.1f%% %6.1f us  %s' % (100 * v / allc, v / len(bufs) / args.mhz, k))

if args.modules:
    for a, cc in mstate['pending']:
        mstate['left'] += cc
    ran = [v for _, v in dispatch_ids if own.get(v)]
    dispatch = sum(sum(t.values()) for t in tails.values() if len(t) > 1)
    left = mstate['left'] + sum(sum(t.values()) for t in tails.values() if len(t) <= 1)
    for cls, cc in shared_own.items():  # by the instances of the class
        insts = [m for m in ran if classes[m] == cls]
        for m in insts:
            own[m] += cc / len(insts)
    def us(c): return c / len(bufs) / args.mhz
    def pct(c): return 100 * us(c) / budget_us
    def with_common(m): return own[m] + common.get(m, 0) + dispatch / len(ran)
    print('modules, per buffer of %.0f us: own, and with its share of the common part (its bus reads and writes, and the dispatch)' % budget_us)
    for m in sorted(ran, key=lambda m: -with_common(m)):
        print('  %-10s %5.1f%% (%4.0f us)  %5.1f%% (%4.0f us)' % ('%s %s' % (classes[m], m.rsplit('_', 1)[1]), pct(own[m]), us(own[m]), pct(with_common(m)), us(with_common(m))))
    print('  %-10s %5.1f%% (%4.0f us), not of a module (the output, the loop of the samples, MIDI, the CCs)' % ('common', pct(left), us(left)))
