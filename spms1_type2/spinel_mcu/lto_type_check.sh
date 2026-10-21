#!/bin/sh
# Checks that every function and variable of the runtime has the same type wherever it is declared.
#
# The MCU changes make Float float: the runtime in sp_float, and the generated code with
# #define double float at the end of spinel_rt.h (see spinel_mcu/spinel_mcu.patch). A function
# declared with float on one side and double on the other is a bug nothing in a normal build
# notices: when the runtime too was made float with that #define, sp_float_shortest and
# sp_read_float were like that, and Float#to_s printed garbage. A link with -flto compares the
# declarations across all the files, and -Wlto-type-mismatch reports those that differ.
#
#   sh spinel_mcu/lto_type_check.sh
#
# Builds spms1/spms1_main.c, the runtime in spms1 and sim_render's own file with gcc (-flto), as sim_render does,
# into build/lto_type_check, and exits with 1 on a mismatch, or on a pointer passed as another
# type (the address of a float where a double is written). Needs gcc with LTO (on Linux, as in the
# GitHub Actions workflow; clang has no such check).

set -eu

cd "$(dirname "$0")/.."
out=build/lto_type_check
mkdir -p "$out"
rm -f "$out"/*.o
cc=${CC:-gcc}
log="$out/log.txt"
: > "$log"

for src in spms1/spms1_main.c spms1/sp_*.c spms1/re_*.c; do
  "$cc" -O1 -flto -include sim_spinel/host_compat.h -Ispms1 -c "$src" -o "$out/$(basename "$src" .c).o" 2>> "$log"
done
"$cc" -O1 -flto -Ispms1 -c sim_render/spms1_render.c -o "$out/spms1_render_host.o" 2>> "$log"
"$cc" -O1 -flto -Wlto-type-mismatch -o "$out/spms1_render" "$out"/*.o -lm 2>> "$log"

bad=0
if grep -q 'incompatible-pointer-types' "$log"; then
  echo "Pointers passed as another type:"
  grep -A2 'incompatible-pointer-types' "$log" | sed 's/^/  /'
  bad=1
fi
if grep -q 'Wlto-type-mismatch' "$log"; then
  echo "Declared with different types in different files:"
  grep "type of '" "$log" | sed -E "s/.*type of '([^']+)'.*/  \1/" | sort -u
  bad=1
fi
if [ $bad -ne 0 ]; then
  echo "(the whole output is in $log)"
  exit 1
fi
echo "Types agree across spms1_main.c, the runtime and sim_render"
