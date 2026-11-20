#!/usr/bin/env bash
# Installs the recommended Claude Code plugin setup (see docs/claude-setup/recommended-plugins.md).
# Safe to run again: existing marketplaces and plugins are skipped or updated.
set -u

marketplaces=(
  anthropics/knowledge-work-plugins
  microsoft/power-platform-skills
  bilalshabbir123/power-platform-claude-skills
  obra/superpowers-marketplace
  AgriciDaniel/claude-obsidian
  elevenlabs/claude-plugins
  sickn33/antigravity-awesome-skills
)

plugins=(
  # Coding (Anthropic official)
  ralph-loop@claude-plugins-official
  context7@claude-plugins-official
  feature-dev@claude-plugins-official
  playwright@claude-plugins-official
  code-review@claude-plugins-official
  pr-review-toolkit@claude-plugins-official
  commit-commands@claude-plugins-official
  frontend-design@claude-plugins-official
  typescript-lsp@claude-plugins-official
  security-guidance@claude-plugins-official
  skill-creator@claude-plugins-official
  claude-md-management@claude-plugins-official
  superpowers@superpowers-marketplace
  # Business (Anthropic knowledge-work)
  marketing@knowledge-work-plugins
  sales@knowledge-work-plugins
  product-management@knowledge-work-plugins
  productivity@knowledge-work-plugins
  # Power Platform (Microsoft + this repo)
  code-apps-preview@power-platform-skills
  canvas-apps@power-platform-skills
  model-apps@power-platform-skills
  power-pages@power-platform-skills
  power-automate@power-platform-skills
  pcf@power-platform-skills
  power-platform@power-platform-claude-skills
  sharepoint@power-platform-claude-skills
  react@power-platform-claude-skills
  ai-models@power-platform-claude-skills
  # Knowledge, voice, skill libraries
  claude-obsidian@agricidaniel-claude-obsidian
  elevenlabs-tts@elevenlabs
  elevenlabs-stt@elevenlabs
  agentic-bundle-essentials@agentic-awesome-skills
  agentic-bundle-aas-documents-presentations@agentic-awesome-skills
)

command -v claude >/dev/null || { echo "Claude Code is not installed: https://docs.claude.com/en/docs/claude-code"; exit 1; }

for m in "${marketplaces[@]}"; do
  echo "→ marketplace $m"
  claude plugin marketplace add "$m" >/dev/null 2>&1 || echo "  (already added or failed — check: claude plugin marketplace list)"
done
claude plugin marketplace update >/dev/null 2>&1

failed=()
for p in "${plugins[@]}"; do
  printf "→ %-60s" "$p"
  if claude plugin install "$p" --scope user >/dev/null 2>&1; then echo "ok"; else echo "FAILED"; failed+=("$p"); fi
done

echo
[ ${#failed[@]} -eq 0 ] && echo "All plugins installed. Restart Claude Code." || { echo "Failed: ${failed[*]}"; exit 1; }
echo "Next: ElevenLabs needs an API key (/elevenlabs-tts:setup, /elevenlabs-stt:setup)."
