#!/usr/bin/env bash
# Install every skill in this repo into the Claude Code skills directory.
# Links skills/<name> -> $CLAUDE_SKILLS_DIR/<name> (default ~/.claude/skills).
# Falls back to copying if symlinks aren't permitted (e.g. Windows without Dev Mode).
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
dest="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$dest"

linked=0
for d in "$repo"/skills/*/; do
  [ -f "$d/SKILL.md" ] || continue
  name="$(basename "$d")"
  target="$dest/$name"
  rm -rf "$target"
  if ln -s "$d" "$target" 2>/dev/null; then
    echo "linked  $name -> $target"
  else
    cp -r "$d" "$target"
    echo "copied  $name -> $target  (symlink not permitted)"
  fi
  linked=$((linked + 1))
done

echo "done — $linked skill(s) installed to $dest"
