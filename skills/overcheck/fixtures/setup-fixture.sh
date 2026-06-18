#!/usr/bin/env bash
# Usage: setup-fixture.sh <fixture-name>
# Builds a temp git repo: commits <name>.before, then overwrites with <name>.after
# left UNCOMMITTED, so `git diff HEAD` shows exactly the fixture's change.
# Prints the temp repo path on stdout.
set -euo pipefail
name="$1"
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
before="$here/$name.before"
after="$here/$name.after"
[ -f "$before" ] || { echo "missing $before" >&2; exit 1; }
[ -f "$after" ]  || { echo "missing $after"  >&2; exit 1; }
repo="$(mktemp -d)"
cd "$repo"
git init -q
git config user.email t@e.st; git config user.name test
# target path is carried by the fixture's first line: "# file: <path>"
target="$(head -1 "$before" | sed 's/^# file: //')"
mkdir -p "$(dirname "$target")"
tail -n +2 "$before" > "$target"
git add -A && git commit -q -m base
tail -n +2 "$after" > "$target"
echo "$repo"
