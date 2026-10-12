#!/bin/sh
# Renders the same patch and score with Spinel's output (sim_render) and with CRuby running
# spms1_main.rb itself (sim_cruby/spms1_render.rb), and compares the two (sim_cruby/spms1_compare.rb).
# Where they part, the C that Spinel made does not do what the Ruby says.
#
#   sh sim_render/compare_with_cruby.sh [--patch FILE] [--score FILE] [--seconds N]
#
# Build sim_render first (sh sim_render/build.sh). The WAV files go to build/sim_render.
set -e
cd "$(dirname "$0")/.."

exe=build/sim_render/spms1_render
[ -x "$exe" ] || exe=build/sim_render/spms1_render.exe
if [ ! -x "$exe" ]; then
  echo "Build sim_render first: sh sim_render/build.sh" >&2
  exit 1
fi

"$exe" "$@" --out build/sim_render/compare_spinel.wav
ruby sim_cruby/spms1_render.rb "$@" --out build/sim_render/compare_cruby.wav
ruby sim_cruby/spms1_compare.rb build/sim_render/compare_spinel.wav build/sim_render/compare_cruby.wav
