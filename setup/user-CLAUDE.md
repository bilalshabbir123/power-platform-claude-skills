<!-- claude-setup-sync -->
## Claude setup sync (applies to every project)

My Claude Code setup (plugins, marketplaces, personal skills) lives in the GitHub repo
`bilalshabbir123/power-platform-claude-skills`, cloned at `~/repos/power-platform-claude-skills`.
A session-start check prints "Claude setup is out of sync…" when this computer and the repo differ.

1. **New computer or missing plugins/skills:** run `~/repos/power-platform-claude-skills/scripts/sync-setup.sh --pull`
   (clone the repo first if it isn't there). Then tell me to restart Claude Code.
2. **I installed a new plugin or made a new personal skill:** run `scripts/sync-setup.sh --push` from the repo,
   so the repo has it next time. The repo is PUBLIC: the script's privacy check blocks emails, GUIDs and tenant URLs;
   also never push client names, project-specific skills or anything from a client project. If unsure, ask me first.
3. **New project:** run `~/repos/power-platform-claude-skills/scripts/new-project.sh <project folder>` to add
   `.claude/settings.json` (same plugins) and a starter `CLAUDE.md`.
4. **Private material** (course documents, skills without an open licence) goes to the PRIVATE repo
   `bilalshabbir123/claude-setup-private` at `~/repos/claude-setup-private` (see its README), never the public one.
   When I download new Claude documents or skills, sort them into its `documents/` or `skills/` folder and push.
5. **Learned something reusable** (a Power Platform / SharePoint / React fix that would help other projects):
   suggest adding it as a skill or a lessons-learned entry in that repo, following its CONTRIBUTING.md.
<!-- /claude-setup-sync -->
