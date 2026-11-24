#!/bin/sh
# Makes two changes to the spms1_main.c Spinel writes, which sim_render/build.sh and
# sim_spinel/build.sh make right after Spinel:
#
#   sh spinel_mcu/after_spinel.sh spms1/spms1_main.c
#
# 1. Declares its ffi_func externs under their own names again, as Spinel did before Release
#    2026.10.25, and calls them so. Spinel now declares each one under a private name
#    (sp_ffi_f30_set_bus_signal) that an asm label binds to the symbol. That keeps it from
#    conflicting with a header's own prototype, but it is no longer the function spms1_bus.h,
#    spms1_dsp.h and the other headers spinel_rt_mcu_cold.h includes define static inline: the call
#    goes out to a symbol nothing defines, and is not inlined. Under its own name the extern
#    declaration follows the static inline definition, takes its internal linkage, and the call is
#    inlined, as the per-sample bus reads and writes need.
# 2. Names Spinel's own .rb files (builtins/enumerator.rb, ...) in the #line directives from the
#    folder of Spinel's, where Spinel writes them in full (/home/me/spinel/bin/../builtins/...),
#    so that the file is the same whoever makes it.
#
# A spms1_main.c already changed is left as it is.
set -e
f=${1:?usage: sh spinel_mcu/after_spinel.sh spms1/spms1_main.c}
sed -E -e 's/ __asm__\(SP_FFI_SYM\("[A-Za-z_0-9]+"\)\)//' -e 's/\bsp_ffi_f[0-9]+_([A-Za-z_])/\1/g' \
  -e 's|^(#line [0-9]+ ")[^"]*/(builtins/[^"/]+\.rb")|\1\2|' "$f" > "$f.tmp"
mv "$f.tmp" "$f"
