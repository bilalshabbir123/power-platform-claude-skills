#!/usr/bin/env bash
# Prepares a project folder: adds .claude/settings.json (the recommended plugins) and a starter CLAUDE.md.
# Anyone who opens the project in Claude Code and trusts the folder is offered the same plugins.
# Usage: scripts/new-project.sh /path/to/project
set -eu
target="${1:?Usage: scripts/new-project.sh /path/to/project}"
repo="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$target/.claude"
if [ -f "$target/.claude/settings.json" ]; then
  python3 - "$repo/templates/project/.claude/settings.json" "$target/.claude/settings.json" <<'EOF'
import json, sys
src, dst = json.load(open(sys.argv[1])), json.load(open(sys.argv[2]))
for k in ('extraKnownMarketplaces', 'enabledPlugins'):
    dst.setdefault(k, {}).update(src[k])
json.dump(dst, open(sys.argv[2], 'w'), indent=2)
EOF
  echo "Merged plugins into existing $target/.claude/settings.json"
else
  cp "$repo/templates/project/.claude/settings.json" "$target/.claude/settings.json"
  echo "Added $target/.claude/settings.json"
fi
if [ ! -f "$target/CLAUDE.md" ]; then cp "$repo/templates/CLAUDE.template.md" "$target/CLAUDE.md"; echo "Added $target/CLAUDE.md (fill it in)"; fi
