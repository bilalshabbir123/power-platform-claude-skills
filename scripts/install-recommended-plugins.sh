#!/usr/bin/env bash
# One-time setup for a new computer. Everything comes from this repo:
#   1. setup/claude-settings.json  -> merged into ~/.claude/settings.json (marketplaces + plugins)
#   2. every plugin in that file   -> installed for all projects
#   3. setup/skills/*              -> copied to ~/.claude/skills
# Safe to run again (it updates, never deletes your own settings).
set -u
cd "$(dirname "$0")/.."
command -v claude >/dev/null || { echo "Install Claude Code first: https://docs.claude.com/en/docs/claude-code"; exit 1; }

echo "1/3 Merging plugin settings into ~/.claude/settings.json"
mkdir -p ~/.claude
python3 - <<'EOF'
import json, os, shutil, time
path = os.path.expanduser('~/.claude/settings.json')
user = json.load(open(path)) if os.path.exists(path) else {}
if os.path.exists(path):
    shutil.copy(path, path + '.backup-' + time.strftime('%Y%m%d%H%M%S'))
repo = json.load(open('setup/claude-settings.json'))
for key in ('extraKnownMarketplaces', 'enabledPlugins'):
    user.setdefault(key, {}).update(repo[key])
json.dump(user, open(path, 'w'), indent=2)
EOF

echo "2/3 Installing plugins"
for repo in $(python3 -c "import json;[print(v['source']['repo']) for v in json.load(open('setup/claude-settings.json'))['extraKnownMarketplaces'].values()]"); do
  claude plugin marketplace add "$repo" >/dev/null 2>&1
done
claude plugin marketplace update >/dev/null 2>&1
failed=()
for p in $(python3 -c "import json;[print(k) for k in json.load(open('setup/claude-settings.json'))['enabledPlugins']]"); do
  printf "   %-62s" "$p"
  if claude plugin install "$p" --scope user >/dev/null 2>&1; then echo "ok"; else echo "FAILED"; failed+=("$p"); fi
done

echo "3/3 Copying personal skills to ~/.claude/skills"
mkdir -p ~/.claude/skills
for s in setup/skills/*/; do cp -R "$s" ~/.claude/skills/; echo "   $(basename "$s")"; done

echo "Adding the sync notes to ~/.claude/CLAUDE.md and the session-start sync check"
touch ~/.claude/CLAUDE.md
grep -q "claude-setup-sync" ~/.claude/CLAUDE.md || { printf '\n' >> ~/.claude/CLAUDE.md; cat setup/user-CLAUDE.md >> ~/.claude/CLAUDE.md; }
python3 - "$(pwd)/scripts/sync-setup.sh" <<'EOF'
import json, os, sys
path = os.path.expanduser('~/.claude/settings.json')
s = json.load(open(path))
cmd = f'[ -x "{sys.argv[1]}" ] && "{sys.argv[1]}" --check 2>/dev/null; true'
hooks = s.setdefault('hooks', {}).setdefault('SessionStart', [])
if not any('sync-setup.sh' in h.get('command', '') for e in hooks for h in e.get('hooks', [])):
    hooks.append({'hooks': [{'type': 'command', 'command': cmd, 'timeout': 30}]})
json.dump(s, open(path, 'w'), indent=2)
EOF

echo
[ ${#failed[@]} -eq 0 ] && echo "Done. Restart Claude Code." || echo "Done, but these failed (run again later): ${failed[*]}"
echo "ElevenLabs needs an API key: /elevenlabs-tts:setup and /elevenlabs-stt:setup inside Claude Code."
