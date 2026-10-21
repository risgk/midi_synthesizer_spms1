#!/bin/sh
# Compares two builds of the sketch for what a Spinel release can change unnoticed: the synth core
# in RAM, and the RAM and flash the whole firmware takes. A larger core runs more instructions a
# sample and takes RAM from the heap; neither shows in the sound.
#
#   sh spinel_mcu/size_report.sh BEFORE.elf AFTER.elf
#
# The .elf files are the ones the Arduino build leaves (arduino-cli compile --output-dir DIR puts
# "spms1.ino.elf" in DIR). Prints a Markdown table, and a line starting with "WARNING" for
# each thing that grew by more than the limit (SPMS1_SIZE_LIMIT_PERCENT, default 2). Exits with 0
# either way: growth is for a person to judge, not a failure.
#
# Needs arm-none-eabi-nm and arm-none-eabi-size: from the PATH, or from the Arduino-Pico core.

set -eu

[ $# -eq 2 ] || { echo "usage: size_report.sh BEFORE.elf AFTER.elf" >&2; exit 1; }
before=$1
after=$2
limit=${SPMS1_SIZE_LIMIT_PERCENT:-2}

tool() {
  if command -v "arm-none-eabi-$1" > /dev/null 2>&1; then echo "arm-none-eabi-$1"; return; fi
  for d in "$HOME/.arduino15" "$HOME/Library/Arduino15" "${LOCALAPPDATA:-/nonexistent}/Arduino15"; do
    for t in "$d"/packages/rp2040/tools/pqt-gcc/*/bin/arm-none-eabi-"$1"*; do
      [ -x "$t" ] && { echo "$t"; return; }
    done
  done
  echo "size_report.sh: arm-none-eabi-$1 not found (on the PATH or in the Arduino-Pico core)" >&2
  exit 1
}
NM=$(tool nm)
SIZE=$(tool size)

# The size of a symbol, in bytes (0 if it is not there)
symbol_size() {
  v=$("$NM" -S "$1" | awk -v s="$2" '$4 == s { print $2; exit }')
  [ -n "$v" ] && printf '%d\n' "0x$v" || echo 0
}

# The size of a section, in bytes (0 if it is not there)
section_size() {
  "$SIZE" -A "$1" | awk -v s="$2" '$1 == s { print $2; found = 1; exit } END { if (!found) print 0 }'
}

measure() {
  case "$2" in
    core) symbol_size "$1" Spms1_main ;;
    ram) echo $(( $(section_size "$1" .data) + $(section_size "$1" .bss) )) ;;
    flash) echo $(( $(section_size "$1" .text) + $(section_size "$1" .rodata) )) ;;
  esac
}

echo "| | Before | After | Change |"
echo "|---|---:|---:|---:|"
warnings=
for what in core ram flash; do
  case "$what" in
    core) label='Synth core in RAM (Spms1_main)' ;;
    ram) label='RAM, static (.data + .bss)' ;;
    flash) label='Flash (.text + .rodata)' ;;
  esac
  b=$(measure "$before" "$what")
  a=$(measure "$after" "$what")
  d=$((a - b))
  if [ "$b" -gt 0 ]; then
    pct=$(awk -v a="$a" -v b="$b" 'BEGIN { printf "%+.1f", (a - b) * 100.0 / b }')
  else
    pct='n/a'
  fi
  echo "| $label | $b | $a | $d ($pct%) |"
  if [ "$b" -gt 0 ] && [ $((d * 100)) -gt $((b * limit)) ]; then
    warnings="${warnings}WARNING: $label grew by $d bytes ($pct%), more than $limit%
"
  fi
done
[ "$(measure "$after" core)" -gt 0 ] ||
  warnings="${warnings}WARNING: Spms1_main is not in $after (renamed or no longer in RAM?)
"
printf '%s' "$warnings"
