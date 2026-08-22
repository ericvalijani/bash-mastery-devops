#!/usr/bin/env bash
# Portable loader for bats-support / bats-assert.
#
# These libraries live in different places depending on how they were
# installed, so hardcoding one absolute path (as an earlier version of these
# tests did) makes the suite pass on exactly one machine and fail everywhere
# else. Search the known locations instead, and fail with a useful message.

_bats_lib_dirs=(
  "${BATS_LIB_PATH:-}" # explicit override
  "/usr/lib/bats"      # Debian/Ubuntu (bats-support, bats-assert pkgs)
  "/usr/lib"           # some distros flatten it
  "/usr/local/lib"     # git clone / manual install
  "/usr/local/lib/bats"
  "/opt/homebrew/lib" # macOS arm64
  "/usr/local/opt"    # macOS intel
  "${HOME}/.bats/lib"
)

_load_bats_lib() {
  local name="$1" dir
  for dir in "${_bats_lib_dirs[@]}"; do
    [[ -z "$dir" ]] && continue
    if [[ -f "$dir/$name/load.bash" ]]; then
      load "$dir/$name/load.bash"
      return 0
    fi
  done
  echo "FATAL: could not locate '$name'." >&2
  echo "Install it (Debian/Ubuntu: apt install $name) or set BATS_LIB_PATH." >&2
  return 1
}

_load_bats_lib bats-support
_load_bats_lib bats-assert

# Absolute paths derived from the test file's own location, so the suite can be
# run from any working directory (bats does NOT cd into the test dir).
MODULAR_DIR="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
export MODULAR_DIR
export MODULES_DIR="$MODULAR_DIR/modules"
export LIB_DIR="$MODULAR_DIR/lib"

# bin_without TOOL — echo the path of a throwaway bin directory containing
# every common utility EXCEPT TOOL, so a test can prove "behaviour when TOOL is
# missing" on any machine.
#
# Two approaches that DON'T work:
#   PATH="$FAKEBIN:/usr/bin:/bin"  — only hides TOOL on a machine that happens
#                                    not to have it installed.
#   stripping TOOL's directory from PATH — removes bash/date/tee along with it,
#                                    since they live in /usr/bin too.
#
# So: symlink a known-good set of utilities into a temp dir, skipping TOOL.
bin_without() {
  local tool="$1"
  local dir="${BATS_TEST_TMPDIR:-/tmp}/bin_without_$tool"
  mkdir -p "$dir"
  local c src
  for c in bash sh env dirname basename mktemp date tee grep sed awk rm cat \
    cp mv mkdir ln chmod find sort head tail wc curl jq; do
    [[ "$c" == "$tool" ]] && continue
    src="$(command -v "$c" 2>/dev/null)" || continue
    ln -sf "$src" "$dir/$c"
  done
  printf '%s' "$dir"
}
