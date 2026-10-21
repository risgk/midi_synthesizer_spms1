#!/bin/sh
# Builds the sketch for the Raspberry Pi Pico 2 with arduino-cli, as the GitHub Actions workflow
# does, into build/sim_load, and estimates its load per audio buffer with spms1_load_estimate.py.
#
#   sh sim_load/estimate.sh [--elf FILE] [options of spms1_load_estimate.py]
#
# --elf FILE skips the build and estimates that ELF instead, e.g. one built from another commit.
# Needs arduino-cli with the "Raspberry Pi Pico/RP2040/RP2350" core and the MIDI Library (see the
# README), python3, and: pip install unicorn capstone pyelftools numpy
set -e
cd "$(dirname "$0")/.."

elf=
if [ "$1" = "--elf" ]; then
  elf="$2"
  shift 2
fi
if [ -z "$elf" ]; then
  mkdir -p build/sim_load
  arduino-cli compile --fqbn 'rp2040:rp2040:rpipico2:usbstack=tinyusb' \
    --output-dir build/sim_load spms1 ${SPMS1_ARDUINO_CLI_FLAGS} >/dev/null
  elf=build/sim_load/spms1.ino.elf
fi
exec python3 sim_load/spms1_load_estimate.py "$elf" "$@"
