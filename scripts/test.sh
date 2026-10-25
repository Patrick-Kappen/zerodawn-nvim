#!/usr/bin/env bash
# Run the tests of one addon, or of every addon: test.sh [ADDON]. Each tests/*_test.lua runs with nvim -l in its own headless nvim, with the addon on the runtimepath.
set -euo pipefail
shopt -s nullglob
cd "$(dirname "$0")/.."
if [[ $# -gt 0 ]]; then
  names=("$1")
else
  names=()
  for dir in addons/*/; do names+=("$(basename "$dir")"); done
fi
if [[ ${#names[@]} -eq 0 ]]; then
  echo "test: no addons in addons/, nothing to test"
  exit 0
fi
status=0
for name in "${names[@]}"; do
  dir="$PWD/addons/$name"
  [[ -d $dir ]] || {
    echo "test: addons/$name does not exist" >&2
    exit 2
  }
  tests=("$dir"/tests/*_test.lua)
  [[ ${#tests[@]} -gt 0 ]] || {
    echo "test: addons/$name/tests has no *_test.lua; add a test" >&2
    exit 1
  }
  for file in "${tests[@]}"; do
    if nvim --headless --clean --cmd "set rtp^=$dir" -l "$file"; then
      echo "ok   addons/$name/tests/$(basename "$file")"
    else
      echo "FAIL addons/$name/tests/$(basename "$file")" >&2
      status=1
    fi
  done
done
exit "$status"
