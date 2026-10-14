#!/bin/sh
# Keeps the Spinel runtime in the sketch folder in step with a Spinel release.
#
# The runtime files (sp_*.[ch], re_*.[ch], spinel_rt.h, mruby_shim.h) are all of Spinel's lib
# (lib/*.[ch] and lib/regexp/*.[ch]) as released. Each one changed for the MCU sits next to its
# released copy, "NAME.orig", and the changes are kept as one patch, "spinel_mcu/spinel_mcu.patch".
# The MCU's own additions live in "spinel_rt_mcu_*.h", which spinel_rt.h includes, so the patch
# stays small. The files that need POSIX are left out whole with SPINEL_BARE_METAL (sp_types.h).
#
# A derived file is a released file with a patch of its own, kept apart from the released one
# rather than in it: "sp_cold_bare_metal.c" is "sp_cold.c" with
# "spinel_mcu/sp_cold_bare_metal.patch" applied, built instead of it for the MCU. update and check
# make and check it as they do the runtime files, and save writes its patch too.
#
#   sh spinel_mcu/update.sh update TAG [--spinel DIR]
#       Takes release TAG: copies its runtime files in, applies the patch to them, and names the
#       release in the READMEs. A hunk that no longer applies is left in NAME.rej, to be carried
#       over by hand; then "save". Files the release adds to its lib are copied in too, and
#       listed: one that needs POSIX is to be left out with SPINEL_BARE_METAL, as sp_net.c is
#       (copy it to NAME.orig first, then "save"). Files it no longer has are removed.
#   sh spinel_mcu/update.sh save
#       Writes the patch again from NAME.orig and NAME, after a change made by hand. To change a
#       file that has no NAME.orig yet, copy it to NAME.orig first.
#   sh spinel_mcu/update.sh check [--spinel DIR]
#       Checks that the runtime files are the release the README names with the patch applied,
#       and nothing else.
#
# --spinel DIR takes Spinel from a checkout of the release, instead of cloning it from GitHub.
#
# Run from anywhere; it works in the sketch folder. Needs git (to clone), diff and GNU patch
# (Git Bash on Windows has both; on macOS, brew install gpatch).

set -eu

cd "$(dirname "$0")/.."
HERE=$(pwd)
PATCH=spinel_mcu/spinel_mcu.patch
# Derived files, DERIVED=RELEASED a pair, each with the patch spinel_mcu/DERIVED-without-.c.patch
DERIVED="sp_cold_bare_metal.c=sp_cold.c"

die() { echo "update.sh: $*" >&2; exit 1; }

# GNU patch, as gpatch (Homebrew's, on macOS) or as patch. The patch of macOS and BSD lacks
# --no-backup-if-mismatch and the fuzz this relies on
gnu_patch() {
  for p in gpatch patch; do
    if "$p" --version 2>/dev/null | grep -q 'GNU patch'; then PATCH_CMD=$p; return; fi
  done
  die "needs GNU patch (on macOS: brew install gpatch)"
}

# The release the README names
readme_release() {
  grep -m1 -oE 'Release: [0-9]{4}\.[0-9]{2}\.[0-9]{2}' README.md | cut -d' ' -f2
}

# The runtime files of the sketch, without the .orig copies and the derived files
vendored() {
  for f in sp_*.c sp_*.h re_*.c re_*.h spinel_rt.h mruby_shim.h; do
    [ -f "$f" ] || continue
    case " $DERIVED " in *" $f="*) continue ;; esac
    echo "$f"
  done
}

# The patch of a derived file
derived_patch() {
  echo "spinel_mcu/${1%.c}.patch"
}

# Makes derived file $1 in folder $3 from the released file $2 there; fails if a hunk does not apply
derive() {
  cp "$3/$2" "$3/$1"
  (cd "$3" && "$PATCH_CMD" -s --no-backup-if-mismatch "$1" < "$HERE/$(derived_patch "$1")")
}

# The runtime files of Spinel's lib, one path a line
upstream_files() {
  for p in "$LIB"/*.[ch] "$LIB"/regexp/*.[ch]; do
    [ -f "$p" ] && echo "$p"
  done
}

# Where NAME is in Spinel's lib, or nothing
upstream_path() {
  for d in "$LIB" "$LIB/regexp"; do
    if [ -f "$d/$1" ]; then echo "$d/$1"; return; fi
  done
}

# Sets LIB to the lib folder of release $1, from --spinel DIR or a clone
fetch() {
  if [ -n "$SPINEL_DIR" ]; then
    LIB="$SPINEL_DIR/lib"
    [ -d "$LIB" ] || die "no lib folder in $SPINEL_DIR"
    if have=$(git -C "$SPINEL_DIR" describe --tags --exact-match 2>/dev/null) && [ "$have" != "$1" ]; then
      die "$SPINEL_DIR is at $have, not $1"
    fi
  else
    TMP=$(mktemp -d)
    trap 'rm -rf "$TMP"' EXIT
    echo "Cloning Spinel $1"
    git clone -q --depth 1 -b "$1" https://github.com/matz/spinel.git "$TMP/spinel" 2>/dev/null ||
      die "cannot clone Spinel $1"
    LIB="$TMP/spinel/lib"
  fi
}

# Writes the patch from NAME.orig and NAME, labelled a/NAME and b/NAME for patch -p1
save() {
  : > "$PATCH.tmp"
  for o in *.orig; do
    f=${o%.orig}
    diff -u --label "a/$f" --label "b/$f" "$o" "$f" >> "$PATCH.tmp" || [ $? -eq 1 ] ||
      die "diff failed on $f"
  done
  mv "$PATCH.tmp" "$PATCH"
  echo "Wrote $PATCH ($(grep -c '^@@' "$PATCH") hunks in $(grep -c '^+++ ' "$PATCH") files)"
  for pair in $DERIVED; do
    d=${pair%%=*}; base=${pair#*=}
    released=$base; [ -f "$base.orig" ] && released=$base.orig
    p=$(derived_patch "$d")
    diff -u --label "a/$d" --label "b/$d" "$released" "$d" > "$p" || [ $? -eq 1 ] ||
      die "diff failed on $d"
    echo "Wrote $p ($(grep -c '^@@' "$p") hunks)"
  done
}

# Files of Spinel's lib that are not in the sketch
new_upstream() {
  for p in $(upstream_files); do
    f=$(basename "$p")
    [ -f "$f" ] || echo "$f"
  done
}

update() {
  tag=$1
  gnu_patch
  fetch "$tag"

  added=$(new_upstream)
  removed=
  for f in $(vendored); do
    p=$(upstream_path "$f")
    if [ -z "$p" ]; then removed="$removed $f"; rm -f "$f" "$f.orig"; continue; fi
    cp "$p" "$f"
    [ -f "$f.orig" ] && cp "$p" "$f.orig"
  done
  for f in $added; do cp "$(upstream_path "$f")" "$f"; done
  find . -maxdepth 1 -name '*.rej' -exec rm {} +

  status=0
  echo "Applying $PATCH"
  "$PATCH_CMD" -s -p1 --no-backup-if-mismatch < "$PATCH" || status=1
  for pair in $DERIVED; do
    d=${pair%%=*}; base=${pair#*=}
    p=$(upstream_path "$base")
    [ -n "$p" ] || { echo "$base is not in $tag any more: $d left as it was"; continue; }
    echo "Making $d from $base and $(derived_patch "$d")"
    WORKD=$(mktemp -d); cp "$p" "$WORKD/$base"
    if derive "$d" "$base" "$WORKD"; then cp "$WORKD/$d" "$d"; else cp "$WORKD/$d" "$d"; cp "$WORKD/$d.rej" . 2>/dev/null; status=1; fi
    rm -rf "$WORKD"
  done

  old=$(readme_release)
  if [ "$old" != "$tag" ]; then
    sed -i.bak "s/$(echo "$old" | sed 's/\./\\./g')/$tag/g" README.md README.ja.md && rm -f README.md.bak README.ja.md.bak
    echo "README.md and README.ja.md now name $tag (was $old)"
  fi

  [ -z "$removed" ] || echo "Not in $tag any more, removed:$removed"
  [ -z "$added" ] || { echo "New in $tag, copied in (one that needs POSIX is to be left out with SPINEL_BARE_METAL):"; echo "$added" | sed 's/^/  /'; }

  if [ $status -ne 0 ]; then
    echo "Some hunks did not apply; they are in:"
    find . -maxdepth 1 -name '*.rej' | sed 's|^\./|  |'
    echo "Make the changes by hand, delete the .rej files, then: sh spinel_mcu/update.sh save"
    exit 1
  fi
  save
  echo "Next: regenerate spms1_main.c (sh sim_render/build.sh), compare with CRuby"
  echo "(sh sim_render/compare_with_cruby.sh), build for the device, and check .time_critical"
}

check() {
  tag=$(readme_release)
  gnu_patch
  fetch "$tag"
  bad=0

  # Each runtime file is the release, or the release with the patch applied
  WORK=$(mktemp -d)
  trap 'rm -rf "$WORK" ${TMP:+"$TMP"}' EXIT
  for f in $(vendored); do
    p=$(upstream_path "$f")
    if [ -z "$p" ]; then echo "Not in Spinel $tag: $f"; bad=1; continue; fi
    if [ -f "$f.orig" ]; then
      cmp -s "$p" "$f.orig" || { echo "$f.orig is not Spinel $tag's"; bad=1; }
    fi
    cp "$p" "$WORK/$f"
  done
  if (cd "$WORK" && "$PATCH_CMD" -s -p1 --no-backup-if-mismatch -r - < "$HERE/$PATCH" > /dev/null); then
    for f in $(vendored); do
      cmp -s "$WORK/$f" "$f" || { echo "$f is not Spinel $tag's with $PATCH applied"; bad=1; }
    done
  else
    echo "$PATCH does not apply to Spinel $tag"; bad=1
  fi

  # Each derived file is its released file with its patch applied
  for pair in $DERIVED; do
    d=${pair%%=*}; base=${pair#*=}
    p=$(upstream_path "$base")
    [ -n "$p" ] || { echo "Not in Spinel $tag: $base, from which $d is made"; bad=1; continue; }
    mkdir -p "$WORK/derived"; cp "$p" "$WORK/derived/$base"
    if derive "$d" "$base" "$WORK/derived" > /dev/null 2>&1; then
      cmp -s "$WORK/derived/$d" "$d" || { echo "$d is not Spinel $tag's $base with $(derived_patch "$d") applied"; bad=1; }
    else
      echo "$(derived_patch "$d") does not apply to Spinel $tag's $base"; bad=1
    fi
  done

  # The patch and the .orig copies name the same files, so that "save" writes this patch again
  for f in $(sed -n 's|^+++ b/||p' "$PATCH"); do
    [ -f "$f.orig" ] || { echo "$PATCH changes $f, which has no $f.orig"; bad=1; }
  done
  for o in *.orig; do
    [ -f "${o%.orig}" ] || { echo "$o has no ${o%.orig}"; bad=1; }
  done

  added=$(new_upstream)
  [ -z "$added" ] || { echo "In Spinel $tag, not in the sketch:"; echo "$added" | sed 's/^/  /'; bad=1; }

  if [ $bad -ne 0 ]; then exit 1; fi
  echo "The runtime is Spinel $tag with $PATCH applied, and its derived files with theirs"
}

cmd=${1:-}
[ $# -gt 0 ] && shift
TAG=
SPINEL_DIR=
TMP=
while [ $# -gt 0 ]; do
  case "$1" in
    --spinel) [ $# -ge 2 ] || die "--spinel needs a folder"; SPINEL_DIR=$2; shift 2 ;;
    -*) die "unknown option $1" ;;
    *) [ -z "$TAG" ] || die "one release only"; TAG=$1; shift ;;
  esac
done

case "$cmd" in
  update) [ -n "$TAG" ] || die "usage: update.sh update TAG [--spinel DIR]"; update "$TAG" ;;
  save) save ;;
  check) check ;;
  *) die "usage: update.sh update TAG [--spinel DIR] | save | check [--spinel DIR]" ;;
esac
