#!/usr/bin/env bash
# Two-way sync between this computer's Claude setup and this repo.
#   scripts/sync-setup.sh --check   pull the repo, list what differs (prints nothing when in sync)
#   scripts/sync-setup.sh --pull    install anything in the repo that this computer is missing
#   scripts/sync-setup.sh --push    add plugins/skills this computer has but the repo is missing, check, commit, push
set -u
cd "$(dirname "$0")/.."
mode="${1:---check}"
git pull -q --ff-only 2>/dev/null

diff_json=$(python3 - <<'EOF'
import json, os
home = os.path.expanduser('~/.claude')
user = json.load(open(f'{home}/settings.json')) if os.path.exists(f'{home}/settings.json') else {}
repo = json.load(open('setup/claude-settings.json'))
known = {}
try: known = json.load(open(f'{home}/plugins/known_marketplaces.json'))
except Exception: pass
up, rp = user.get('enabledPlugins', {}), repo['enabledPlugins']
um, rm = user.get('extraKnownMarketplaces', {}), repo['extraKnownMarketplaces']
skip_skills = {'synced'}
priv = os.path.expanduser('~/repos/claude-setup-private/skills')
if os.path.isdir(priv): skip_skills |= set(os.listdir(priv))  # private skills never go to this public repo
us = {d for d in os.listdir(f'{home}/skills')} - skip_skills if os.path.isdir(f'{home}/skills') else set()
rs = set(os.listdir('setup/skills'))
missing_mkts = {}
for p in up:
    if up[p] and p not in rp:
        m = p.split('@')[1]
        if m not in ('claude-plugins-official',) and m not in rm:
            src = um.get(m) or ({'source': known[m]['source']} if m in known else None)
            if src: missing_mkts[m] = src
print(json.dumps({
  'push_plugins': sorted(p for p in up if up[p] and p not in rp),
  'push_marketplaces': missing_mkts,
  'push_skills': sorted(s for s in us - rs if os.path.isfile(f'{home}/skills/{s}/SKILL.md')),
  'pull_plugins': sorted(p for p in rp if p not in up),
  'pull_skills': sorted(rs - us),
}))
EOF
)
get() { python3 -c "import json,sys;d=json.loads(sys.argv[1]);v=d['$1'];print(' '.join(v) if isinstance(v,list) else ' '.join(v.keys()))" "$diff_json"; }
push_plugins=$(get push_plugins); push_skills=$(get push_skills); pull_plugins=$(get pull_plugins); pull_skills=$(get pull_skills)

case "$mode" in
--check)
  [ -z "$push_plugins$push_skills$pull_plugins$pull_skills" ] && exit 0
  echo "Claude setup is out of sync with the setup repo ($(pwd)):"
  [ -n "$push_plugins" ] && echo "  On this computer, not in the repo (plugins): $push_plugins"
  [ -n "$push_skills" ]  && echo "  On this computer, not in the repo (skills):  $push_skills"
  [ -n "$pull_plugins" ] && echo "  In the repo, not on this computer (plugins): $pull_plugins"
  [ -n "$pull_skills" ]  && echo "  In the repo, not on this computer (skills):  $pull_skills"
  echo "  Fix: scripts/sync-setup.sh --push (send to repo) and/or --pull (install here)."
  ;;
--pull)
  exec scripts/install-recommended-plugins.sh
  ;;
--push)
  [ -z "$push_plugins$push_skills" ] && { echo "Repo already has everything from this computer."; exit 0; }
  python3 - "$diff_json" <<'EOF'
import json, sys
d = json.loads(sys.argv[1])
for f in ('setup/claude-settings.json', 'templates/project/.claude/settings.json'):
    s = json.load(open(f))
    s['extraKnownMarketplaces'].update(d['push_marketplaces'])
    for p in d['push_plugins']: s['enabledPlugins'][p] = True
    json.dump(s, open(f, 'w'), indent=2); open(f, 'a').write('\n')
EOF
  for s in $push_skills; do cp -R ~/.claude/skills/"$s" setup/skills/; done
  if ! scripts/check.sh; then
    echo "Privacy/structure check failed — nothing pushed. Remove private details (emails, GUIDs, client names) and run again."
    git checkout -- setup templates 2>/dev/null; for s in $push_skills; do rm -rf "setup/skills/$s"; done
    exit 1
  fi
  git add setup templates
  git commit -q -m "Sync Claude setup: ${push_plugins:+plugins $push_plugins }${push_skills:+skills $push_skills}" && git push -q && echo "Pushed: $push_plugins $push_skills"
  ;;
*) echo "Usage: $0 --check | --pull | --push"; exit 1 ;;
esac
