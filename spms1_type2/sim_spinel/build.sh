#!/bin/sh
# Builds the PC simulator into build/sim_spinel: gcc from MinGW (run in Git Bash) on Windows,
# clang on macOS, cc (gcc or clang) on Linux.
#
#   sh sim_spinel/build.sh [--no-spinel]
#
# First regenerates spms1_main.c from the .rb files with Spinel, found on the PATH or, on Windows,
# inside WSL. This writes the sketch's own spms1_main.c, the one the device is built from.
# --no-spinel, or no Spinel to be found, builds the spms1_main.c already there.
set -e
cd "$(dirname "$0")/.."
mkdir -p build/sim_spinel

use_spinel=1
for arg in "$@"; do
  case "$arg" in
    --no-spinel) use_spinel=0 ;;
    *) echo "usage: sh sim_spinel/build.sh [--no-spinel]" >&2; exit 1 ;;
  esac
done

case "$(uname -s)" in
  MINGW*|MSYS*)
    exe=build/sim_spinel/spms1_sim.exe
    libs="-lwinmm -Wl,-Bstatic -lwinpthread -Wl,-Bdynamic"
    strip_unused="-Wl,--gc-sections"
    ;;
  Darwin)
    exe=build/sim_spinel/spms1_sim
    libs="-framework CoreMIDI -framework CoreFoundation"
    strip_unused="-Wl,-dead_strip"
    ;;
  Linux)
    exe=build/sim_spinel/spms1_sim
    libs="-ldl -lpthread"
    strip_unused="-Wl,--gc-sections"
    ;;
  *)
    echo "Windows, macOS or Linux only" >&2
    exit 1
    ;;
esac

# Spinel runs in a scratch directory on copies under the same names, so that the #line directives
# in its output name the files as a run in the sketch folder, spms1, would. The type seeds in
# spms1/sig go with them; spms1/sig/spms1_filter.rbs says why they are needed.
spinel_script='set -e; dir=$1; tmp=$(mktemp -d); cp "$dir"/spms1_*.rb "$tmp"/; cp -R "$dir"/sig "$tmp"/; cd "$tmp"; spinel spms1_main.rb -c --rbs sig; cp spms1_main.c "$dir"/; rm -rf "$tmp"'
if [ "$use_spinel" = 1 ]; then
  if command -v spinel > /dev/null 2>&1; then
    bash -c "$spinel_script" _ "$(pwd)/spms1"
  elif command -v wsl.exe > /dev/null 2>&1 && wsl.exe -e bash -lc 'command -v spinel' > /dev/null 2>&1; then
    MSYS_NO_PATHCONV=1 wsl.exe -e bash -lc "$spinel_script" _ "$(wsl.exe -e wslpath -a "$(pwd -W)/spms1" | tr -d '\r')"
  else
    echo "Spinel not found; building the spms1_main.c already in spms1" >&2
  fi
fi

cc=${CC:-cc}
command -v "$cc" > /dev/null || cc=gcc

# The runtime is built as the sketch has it, warnings included, so they are not shown. Its objects
# are rebuilt only when their source or any header is newer; spms1_main.c always is.
newest_header=$(ls -t spms1/*.h sim_spinel/host_compat.h | head -n 1)
for src in spms1/spms1_main.c spms1/sp_*.c spms1/re_*.c; do
  obj="build/sim_spinel/$(basename "$src" .c).o"
  if [ "$src" = spms1/spms1_main.c ] || [ ! -f "$obj" ] || [ "$src" -nt "$obj" ] || [ "$newest_header" -nt "$obj" ]; then
    "$cc" -O2 -w -ffunction-sections -fdata-sections -include sim_spinel/host_compat.h -Ispms1 \
      -c "$src" -o "$obj"
  fi
done
"$cc" -O2 -Wall -Wno-deprecated-declarations -Ispms1 -c sim_spinel/spms1_sim.c -o build/sim_spinel/spms1_sim_host.o
"$cc" -o "$exe" build/sim_spinel/*.o $libs -lm $strip_unused

echo "Built $exe"
