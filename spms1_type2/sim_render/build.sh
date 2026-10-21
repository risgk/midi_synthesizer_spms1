#!/bin/sh
# Builds the offline renderer into build/sim_render: cc (gcc or clang) on Linux and macOS, gcc from
# MinGW (run in Git Bash) on Windows. Nothing but the C library is needed.
#
#   sh sim_render/build.sh [--no-spinel]
#
# First regenerates spms1_main.c from the .rb files with Spinel, found on the PATH or, on Windows,
# inside WSL, as sim_spinel/build.sh does. This writes the sketch's own spms1_main.c, the one the
# device is built from. --no-spinel, or no Spinel to be found, builds the spms1_main.c already there.
set -e
cd "$(dirname "$0")/.."
mkdir -p build/sim_render

use_spinel=1
for arg in "$@"; do
  case "$arg" in
    --no-spinel) use_spinel=0 ;;
    *) echo "usage: sh sim_render/build.sh [--no-spinel]" >&2; exit 1 ;;
  esac
done

case "$(uname -s)" in
  MINGW*|MSYS*)
    exe=build/sim_render/spms1_render.exe
    strip_unused="-Wl,--gc-sections"
    ;;
  Darwin)
    exe=build/sim_render/spms1_render
    strip_unused="-Wl,-dead_strip"
    ;;
  *)
    exe=build/sim_render/spms1_render
    strip_unused="-Wl,--gc-sections"
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

# The runtime is built as the sketch has it, warnings included, so they are not shown, with the
# same compatibility header as the PC simulator, and with the check for dropped GC roots (see
# sp_gc.h), which the sketch leaves out. Its objects are rebuilt only when their source or
# any header is newer; spms1_main.c always is.
newest_header=$(ls -t spms1/*.h sim_spinel/host_compat.h | head -n 1)
for src in spms1/spms1_main.c spms1/sp_*.c spms1/re_*.c; do
  obj="build/sim_render/$(basename "$src" .c).o"
  if [ "$src" = spms1/spms1_main.c ] || [ ! -f "$obj" ] || [ "$src" -nt "$obj" ] || [ "$newest_header" -nt "$obj" ]; then
    "$cc" -O2 -w -ffunction-sections -fdata-sections -include sim_spinel/host_compat.h -Ispms1 \
      -DSP_GC_ROOT_OVERFLOW_CHECK -c "$src" -o "$obj"
  fi
done
"$cc" -O2 -Wall -Ispms1 -c sim_render/spms1_render.c -o build/sim_render/spms1_render_host.o
"$cc" -o "$exe" build/sim_render/*.o -lm $strip_unused

echo "Built $exe"
