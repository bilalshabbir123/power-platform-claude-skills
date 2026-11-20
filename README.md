# Power Platform Claude Skills

Field-tested [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills) for Microsoft **Power Platform**, **SharePoint**, **React UI** and **custom AI models**, organised as a plugin marketplace: **one plugin per technology**, all in one repository.

Every skill solves **one specific problem**, explains the mistake that caused it, and ends with the checks that stop it happening again. Each skill has eval cases, so you can check it actually improves Claude's answers.

## Plugins and skills

| Plugin | Skill | Solves |
|---|---|---|
| **power-platform** | [`power-platform-solution-builder`](plugins/power-platform/skills/power-platform-solution-builder/) | **Start here.** Picks canvas / code app / SPFx / custom React / flow / AI, applies shared standards, loads only the matching reference |
| | [`power-apps-canvas-app-delegation-performance`](plugins/power-platform/skills/power-apps-canvas-app-delegation-performance/) | Canvas apps that miss records (delegation, 10,000 row limit), start slowly or fail to save silently |
| | [`power-apps-code-app-deployment`](plugins/power-platform/skills/power-apps-code-app-deployment/) | Publishing a code app: stale builds, wrong account, version proof |
| | [`power-apps-code-app-dataverse-data-access`](plugins/power-platform/skills/power-apps-code-app-dataverse-data-access/) | Dataverse reads and writes without truncation, lost saves or throttling |
| | [`power-apps-code-app-business-rules-testing`](plugins/power-platform/skills/power-apps-code-app-business-rules-testing/) | Automatic records at the wrong time, duplicates, date bugs, player-only bugs |
| | [`power-automate-dataverse-triggered-flows`](plugins/power-platform/skills/power-automate-dataverse-triggered-flows/) | Flows that duplicate, fail on long text or silently stop |
| | [`dataverse-security-roles-for-code-apps`](plugins/power-platform/skills/dataverse-security-roles-for-code-apps/) | Least-privilege roles, no self-promotion, role scripts that work |
| | [`power-platform-solution-release-alm`](plugins/power-platform/skills/power-platform-solution-release-alm/) | Managed solution releases to production without surprises |
| **sharepoint** | [`sharepoint-spfx-web-parts`](plugins/sharepoint/skills/sharepoint-spfx-web-parts/) | SPFx on the Heft toolchain, data access, permissions, throttling, CI |
| **react** | [`react-bits-animated-ui`](plugins/react/skills/react-bits-animated-ui/) | React Bits animations that are accessible, fast, CSP-safe and licence-compliant |
| **ai-models** | [`unsloth-custom-llm-for-power-platform`](plugins/ai-models/skills/unsloth-custom-llm-for-power-platform/) | Fine-tune with Unsloth and call the model from Power Platform safely |

The mistakes these skills prevent are listed in [docs/lessons-learned.md](docs/lessons-learned.md).

## Install

**Option A — as plugins (recommended; easy updates):**
```
/plugin marketplace add bilalshabbir123/power-platform-claude-skills
/plugin install power-platform@power-platform-claude-skills
/plugin install sharepoint@power-platform-claude-skills
/plugin install react@power-platform-claude-skills
/plugin install ai-models@power-platform-claude-skills
```
Update later with `/plugin marketplace update power-platform-claude-skills`.

**Option B — copy the skill folders:**
```bash
git clone https://github.com/bilalshabbir123/power-platform-claude-skills.git
mkdir -p ~/.claude/skills
cp -R power-platform-claude-skills/plugins/*/skills/* ~/.claude/skills/
```
Restart Claude Code. Skills load automatically when a request matches their `description`, or ask by name ("use the sharepoint-spfx-web-parts skill").

## Claude setup: concepts and recommended plugins

New to Claude Code, skills or plugins? Start with **[docs/claude-setup/](docs/claude-setup/)**:

1. [Concepts guide](docs/claude-setup/README.md): Claude products, modes, context, memory and `CLAUDE.md`, skills vs commands vs hooks vs MCP vs plugins, prompting techniques, agents, Claude + Obsidian, safety.
2. [Recommended plugins](docs/claude-setup/recommended-plugins.md): Ralph Loop, Context7, feature-dev, Playwright, Superpowers, code review, marketing/sales (knowledge-work), Claude Obsidian, ElevenLabs, Antigravity skill bundles, Power Platform. Each entry says what it does and how to use it.
3. One command to install the whole setup on a new machine:
   ```bash
   scripts/install-recommended-plugins.sh
   ```
4. [`templates/CLAUDE.template.md`](templates/CLAUDE.template.md): a starting `CLAUDE.md` for a new project.

## Why one hub skill plus focused skills (not one giant skill)

Claude reads every skill's short description all the time, a skill's `SKILL.md` only when it's relevant, and reference files only when the skill points to them. One giant skill would load every product's rules for every request and mix them up (for example canvas delegation rules in a code app). So:

1. **`power-platform-solution-builder`** is the single entry point. It decides the technology and reads only the matching file in its `references/` folder.
2. **Focused skills** hold the deep, tested detail for one problem each.
3. **Plugins** group skills by technology so you can install only what you use, and new technologies are added as new plugins.

## Repository structure

```
.claude-plugin/marketplace.json     # lists every plugin in this repo
plugins/
  <technology>/                     # power-platform, sharepoint, react, ai-models, ...
    .claude-plugin/plugin.json      # name, description, version
    README.md
    skills/<skill-name>/
      SKILL.md                      # what Claude reads
      README.md                     # what people read
      references/                   # optional, loaded on demand
    evals/<case>/                   # tests: prompt.md + graders/*.md
templates/SKILL.template.md         # required structure for every skill
templates/CLAUDE.template.md        # starting CLAUDE.md for a new project
docs/
  claude-setup/                     # concepts guide + recommended plugins
  lessons-learned.md                # mistakes, causes, and the skill that prevents each
  testing-skills.md                 # how to run and write evals
scripts/check.sh                    # structure + privacy checks (also run in CI)
scripts/install-recommended-plugins.sh  # installs the recommended plugin setup
CONTRIBUTING.md                     # standards, naming, quality gate, adding a technology
```

## Testing

```bash
scripts/check.sh                                         # structure, manifests, privacy
claude plugin validate .                                 # marketplace + plugins
claude plugin eval plugins/react --runs 1 --no-publish   # with-skill vs without-skill scores
```
See [docs/testing-skills.md](docs/testing-skills.md).

## Labels

- **[Microsoft]** — from Microsoft Learn (linked).
- **[Field-tested]** — observed on a real tenant; the skill says how to re-check it.
- **[React Bits] / [Unsloth] / [Vendor docs]** — from that project's official repository or docs (linked).

## Disclaimer

Licensing, limits, CLI commands and third-party projects change. Each skill links the pages it relies on; check them before licensing, capacity or legal decisions. Third-party projects keep their own licences (React Bits: MIT + Commons Clause; Unsloth: Apache 2.0 core, AGPL-3.0 Studio). This repo links to them and does not redistribute their code.
