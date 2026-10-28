#!/usr/bin/env bash
# Run the tests for changed paths: test-changed.sh PATH... A path under addons/<name>/ runs the tests of that addon; any other path runs every test.
set -euo pipefail
cd "$(dirname "$0")/.."
addons=()
for path in "$@"; do
  if [[ $path =~ ^addons/([^/]+)/ ]]; then
    name=${BASH_REMATCH[1]}
    [[ -d addons/$name ]] || continue
    [[ " ${addons[*]} " == *" $name "* ]] || addons+=("$name")
  else
    exec scripts/test.sh
  fi
done
status=0
for name in "${addons[@]}"; do
  scripts/test.sh "$name" || status=1
done
exit "$status"
