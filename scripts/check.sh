#!/usr/bin/env bash
# Structure, manifest and privacy checks for every plugin and skill. Exit 1 on any problem.
set -u
cd "$(dirname "$0")/.."
fail=0; err() { echo "✗ $*"; fail=1; }

python3 -m json.tool .claude-plugin/marketplace.json >/dev/null || err "marketplace.json is not valid JSON"
for src in $(python3 -c "import json;[print(p['source']) for p in json.load(open('.claude-plugin/marketplace.json'))['plugins']]"); do
  [ -f "$src/.claude-plugin/plugin.json" ] || err "$src: missing .claude-plugin/plugin.json"
done
for p in plugins/*/; do
  p=${p%/}; name=$(basename "$p")
  grep -q "\"./$p\"" .claude-plugin/marketplace.json || err "$p is not listed in marketplace.json"
  [ -f "$p/README.md" ] || err "$p: missing README.md"
  n=$(find "$p/evals" -name prompt.md 2>/dev/null | wc -l | tr -d ' ')
  [ "$n" -ge 2 ] || err "$p: fewer than 2 eval cases"
done

names=""
for s in plugins/*/skills/*/; do
  s=${s%/}; dir=$(basename "$s"); f="$s/SKILL.md"
  [ -f "$f" ] || { err "$s: missing SKILL.md"; continue; }
  [ -f "$s/README.md" ] || err "$s: missing README.md"
  nm=$(sed -n 's/^name: //p' "$f" | head -1)
  [ "$nm" = "$dir" ] || err "$f: name '$nm' does not match folder '$dir'"
  desc=$(sed -n 's/^description: //p' "$f" | head -1)
  [ ${#desc} -gt 0 ] && [ ${#desc} -le 1024 ] || err "$f: description missing or over 1,024 characters (${#desc})"
  lines=$(wc -l < "$f"); [ "$lines" -le 500 ] || err "$f: $lines lines (limit 500)"
  for sec in "## Purpose" "## Expertise" "## Instructions" "## Examples" "## Common mistakes" "## Validation checklist" "## References"; do
    grep -q "^$sec" "$f" || err "$f: missing section '$sec'"
  done
  case " $names " in *" $nm "*) err "duplicate skill name $nm";; esac; names="$names $nm"
done

# Privacy: real GUIDs, emails and tenant hosts must not appear
if grep -rnoE "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" plugins templates docs README.md setup --exclude-dir=results | grep -v "00000000-0000-0000-0000-000000000000"; then err "GUID found (use placeholders)"; fi
if grep -rnoE "[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[a-z]{2,}" plugins templates docs setup README.md CONTRIBUTING.md --exclude-dir=results | grep -viE "noreply@|@contoso\.|@example\.|@pnp/|@microsoft/|@azure/|@odata\.bind|@odata\.|@react-bits|@react-three|@gsap|@tailwindcss|@types|@vitejs|@jsrepo|@latest|@next"; then err "email address found"; fi
if grep -rnoE "org[0-9a-f]{6,}\.crm[0-9]*\.dynamics\.com" plugins templates docs README.md setup; then err "real Dataverse org URL found"; fi

[ $fail -eq 0 ] && echo "All checks passed" || exit 1
