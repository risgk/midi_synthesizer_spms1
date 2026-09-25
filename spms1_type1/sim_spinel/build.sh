#!/bin/sh
# Builds the PC simulator into build/sim_spinel: gcc from MinGW (run in Git Bash) on Windows,
# clang on macOS.
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

# Spinel runs in a scratch directory on copies under the same names, so that the #line directives
# in its output name the files as a run in this folder would.
spinel_script='set -e; dir=$1; tmp=$(mktemp -d); cp "$dir"/spms1_*.rb "$tmp"/; cd "$tmp"; spinel spms1_main.rb -c; cp spms1_main.c "$dir"/; rm -rf "$tmp"'
if [ "$use_spinel" = 1 ]; then
  if command -v spinel > /dev/null 2>&1; then
    bash -c "$spinel_script" _ "$(pwd)"
  elif command -v wsl.exe > /dev/null 2>&1 && wsl.exe -e bash -lc 'command -v spinel' > /dev/null 2>&1; then
    MSYS_NO_PATHCONV=1 wsl.exe -e bash -lc "$spinel_script" _ "$(wsl.exe -e wslpath -a "$(pwd -W)" | tr -d '\r')"
  else
    echo "Spinel not found; building the spms1_main.c already here" >&2
  fi
fi

cc=${CC:-cc}
command -v "$cc" > /dev/null || cc=gcc

# The runtime is built as the sketch has it, warnings included, so they are not shown. Its objects
# are rebuilt only when their source or any header is newer; spms1_main.c always is.
newest_header=$(ls -t *.h sim_spinel/host_compat.h | head -n 1)
for src in spms1_main.c sp_*.c re_*.c; do
  obj="build/sim_spinel/$(basename "$src" .c).o"
  if [ "$src" = spms1_main.c ] || [ ! -f "$obj" ] || [ "$src" -nt "$obj" ] || [ "$newest_header" -nt "$obj" ]; then
    "$cc" -O2 -w -ffunction-sections -fdata-sections -include sim_spinel/host_compat.h -I. \
      -c "$src" -o "$obj"
  fi
done
"$cc" -O2 -Wall -Wno-deprecated-declarations -c sim_spinel/spms1_sim.c -o build/sim_spinel/spms1_sim_host.o
"$cc" -o "$exe" build/sim_spinel/*.o $libs -lm $strip_unused

echo "Built $exe"
