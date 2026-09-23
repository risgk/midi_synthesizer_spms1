#!/bin/sh
# Builds the PC simulator from spms1_main.c into build/sim_spinel: gcc from MinGW (run in Git Bash) on
# Windows, clang on macOS. Re-run Spinel first after changing any .rb.
set -e
cd "$(dirname "$0")/.."
mkdir -p build/sim_spinel

case "$(uname -s)" in
  MINGW*|MSYS*)
    exe=build/sim_spinel/spms1_sim.exe
    libs="-lwinmm"
    strip_unused="-Wl,--gc-sections"
    ;;
  Darwin)
    exe=build/sim_spinel/spms1_sim
    libs="-framework CoreMIDI -framework CoreFoundation"
    strip_unused="-Wl,-dead_strip"
    ;;
  *)
    echo "Windows or macOS only" >&2
    exit 1
    ;;
esac

cc=${CC:-cc}
command -v "$cc" > /dev/null || cc=gcc

# The runtime is built as the sketch has it, warnings included, so they are not shown.
for src in spms1_main.c sp_*.c re_*.c; do
  "$cc" -O2 -w -ffunction-sections -fdata-sections -include sim_spinel/host_compat.h -I. \
    -c "$src" -o "build/sim_spinel/$(basename "$src" .c).o"
done
"$cc" -O2 -Wall -Wno-deprecated-declarations -c sim_spinel/spms1_sim.c -o build/sim_spinel/spms1_sim_host.o
"$cc" -o "$exe" build/sim_spinel/*.o $libs -lm $strip_unused

echo "Built $exe"
