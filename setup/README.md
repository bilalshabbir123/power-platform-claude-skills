# Setup files

Everything needed to rebuild the Claude Code setup on a new computer or in a new project. Nothing has to be downloaded by hand: plugins are fetched from their GitHub marketplaces automatically.

| File | What it is |
|---|---|
| `claude-settings.json` | The list of plugin marketplaces and enabled plugins. Merged into `~/.claude/settings.json` by the install script. |
| `skills/` | Personal skills copied to `~/.claude/skills` (meeting notes, decision log, SOP, notes to PowerPoint, writing partner). MIT licence, from a public course skill pack. |
| `user-CLAUDE.md` | Sync notes added to `~/.claude/CLAUDE.md`, so Claude knows about this repo in every project. |
| `../templates/project/.claude/settings.json` | The same plugin list for a single project; `scripts/new-project.sh` adds it. |

## New computer (once)

```bash
git clone https://github.com/bilalshabbir123/power-platform-claude-skills.git ~/repos/power-platform-claude-skills
~/repos/power-platform-claude-skills/scripts/install-recommended-plugins.sh
```
Then restart Claude Code. Every project now has all plugins and skills.

## New project

```bash
~/repos/power-platform-claude-skills/scripts/new-project.sh /path/to/project
```
This adds `.claude/settings.json` and a starter `CLAUDE.md`. Commit them; anyone who opens the project in Claude Code is offered the same plugins.

## Two-way sync (automatic check)

The install script adds a session-start check. When this computer and the repo differ, Claude sees a message like
"Claude setup is out of sync…" at the start of a session and, following the notes in `~/.claude/CLAUDE.md`, fixes it:

| Command | What it does |
|---|---|
| `scripts/sync-setup.sh --check` | Pulls the repo and lists differences (silent when in sync). |
| `scripts/sync-setup.sh --pull` | Installs plugins/skills the repo has and this computer is missing. |
| `scripts/sync-setup.sh --push` | Adds new plugins/skills from this computer to the repo, runs the privacy check, commits and pushes. |

So when you install a new plugin or create a personal skill in any project, the next session notices and sends it back to the repo. The privacy check refuses to push emails, GUIDs or tenant URLs. Client-specific skills belong in that client project, not here.
