# Recommended plugins and skills

The setup used for Power Platform consulting work: building code apps, flows and SharePoint solutions, plus proposals, sales and marketing. `scripts/install-recommended-plugins.sh` installs everything marked **Installed**.

Install one by hand with `/plugin install <plugin>@<marketplace>` inside Claude Code, or `claude plugin install <plugin>@<marketplace>` in a terminal.

## Marketplaces

| Marketplace name | Add with | Who |
|---|---|---|
| `claude-plugins-official` | (built in) | Anthropic |
| `knowledge-work-plugins` | `claude plugin marketplace add anthropics/knowledge-work-plugins` | Anthropic |
| `power-platform-skills` | `claude plugin marketplace add microsoft/power-platform-skills` | Microsoft |
| `power-platform-claude-skills` | `claude plugin marketplace add bilalshabbir123/power-platform-claude-skills` | This repo |
| `superpowers-marketplace` | `claude plugin marketplace add obra/superpowers-marketplace` | Community (obra) |
| `agricidaniel-claude-obsidian` | `claude plugin marketplace add AgriciDaniel/claude-obsidian` | Community |
| `elevenlabs` | `claude plugin marketplace add elevenlabs/claude-plugins` | ElevenLabs |
| `agentic-awesome-skills` | `claude plugin marketplace add sickn33/antigravity-awesome-skills` | Community ("Antigravity Awesome Skills") |

## Coding and building

| Plugin | Marketplace | What it gives you | How to use |
|---|---|---|---|
| **ralph-loop** (was "Ralph Wiggum") | official | Repeats a task in a loop (review → improve → verify) until a finish line is met. | `/ralph-loop "<task>" --max-iterations 5 --completion-promise "DONE"`; stop with `/cancel-ralph`. Always set a max. |
| **context7** | official | MCP server with current, version-specific library docs. | Add "use context7" to a prompt about a library (React, Vite, Fluent UI…). |
| **feature-dev** | official | Guided feature build: explore code → questions → architecture → build → review. | `/feature-dev <feature brief>` |
| **code-review** | official | Multi-agent review of a pull request. | `/code-review` (the built-in `/code-review` also reviews local changes). |
| **pr-review-toolkit** | official | Specialist reviewers (tests, errors, types, comments). | `/review-pr` |
| **commit-commands** | official | Commit / push / open PR in one go. | `/commit`, `/commit-push-pr`, `/clean_gone` |
| **frontend-design** | official | Skill for distinctive, production-grade UI instead of generic "AI look". | Automatic on UI work, or "use the frontend-design skill". |
| **playwright** | official | Real browser automation: open pages, click, fill forms, screenshot, end-to-end tests. | "Use Playwright to open … and screenshot …" |
| **typescript-lsp** | official | TypeScript language server, so Claude sees type errors as it edits. | Automatic in TS projects. |
| **security-guidance** | official | Warns about risky code patterns while editing. | Automatic. |
| **skill-creator** | official | Helps write, test and improve skills. | "Use skill-creator to make a skill for …" |
| **claude-md-management** | official | Audits and improves `CLAUDE.md` files. | `/revise-claude-md` |
| **superpowers** | superpowers-marketplace | 15 skills for a disciplined workflow: brainstorm → plan → test-first → debug → review. | Automatic; or "use superpowers to plan this". |

## Business work

| Plugin | Marketplace | What it gives you |
|---|---|---|
| **marketing** | knowledge-work-plugins | Content, campaigns, SEO audits, email sequences, performance reports. |
| **sales** | knowledge-work-plugins | Call prep, account research, follow-ups, pipeline review, proposals. |
| **product-management** | knowledge-work-plugins | Specs, roadmaps, user research summaries; `/brainstorm`. |
| **productivity** | knowledge-work-plugins | Task lists, day planning, work memory. |

## Knowledge, voice and skill libraries

| Plugin | Marketplace | What it gives you | Setup needed |
|---|---|---|---|
| **claude-obsidian** | agricidaniel-claude-obsidian | Karpathy-style "LLM wiki" in an Obsidian vault: ingest sources, linked and cited notes, `/wiki`. | Install Obsidian, make a vault folder, `cd` into it, run `claude`. Needs Python 3.11+. |
| **elevenlabs-tts** | elevenlabs | Claude reads its answers aloud. | ElevenLabs API key: run `/elevenlabs-tts:setup`, then `/elevenlabs-tts:start`. Does nothing until set up. |
| **elevenlabs-stt** | elevenlabs | Talk to Claude (speech to text, Ctrl+Shift+Space). | Same key: `/elevenlabs-stt:setup`, then `/elevenlabs-stt:start`; allow microphone. |
| **agentic-bundle-essentials** | agentic-awesome-skills | 5 general skills from the Antigravity Awesome Skills library. | None. |
| **agentic-bundle-aas-documents-presentations** | agentic-awesome-skills | 7 skills for documents and slide decks. | None. |

> **Antigravity** itself is Google's AI code editor (a VS Code fork). Claude Code runs inside it like in VS Code: install the Claude Code extension from its extensions panel. "Antigravity Awesome Skills" is a separate community library of 1,000+ skills. Only themed bundles are installed here, because loading the whole library adds hundreds of skill descriptions to every session. Browse other bundles with `/plugin` → `agentic-awesome-skills`.

## Already installed (Microsoft Power Platform)

From `power-platform-skills`: canvas-apps, code-apps-preview, model-apps, power-pages, power-automate, pcf, mcp-apps, mobile-app, power-apps-mobile-extension, process-intelligence. From this repo: power-platform, sharepoint, react, ai-models.

## Personal skills (in `~/.claude/skills`, not plugins)

18 MIT-licensed skills from a course skill pack are in [`setup/skills/`](../../setup/skills/) and installed by the install script, including PowerPoint ones (`notes-to-powerpoint`, `csv-to-presentations`). Skills without an open licence (PowerPoint/Excel redesigners, diagram design, image skills, Higgsfield) and all course documents are in the private repo `claude-setup-private`. They were written for claude.ai, so in Claude Code tell them where the input file is and where to save the output.

## Not installed, and why

| Item | Reason |
|---|---|
| Whole Antigravity skill library (`agentic-awesome-skills`) | Too many skills at once; pick bundles instead. |
| `superpowers@claude-plugins-official` | Same plugin as the obra marketplace one; installing both duplicates skills. |
| `dfa-excel-formatter`, `dfa-pptx-redesigner` | Stored in the private repo, not installed: branded for another company (change to Inteknix branding first). |

## Keep it healthy

1. `claude plugin list` — what is installed and enabled.
2. `claude plugin marketplace update` — pull updates (official marketplaces update automatically; community ones don't).
3. `claude plugin disable <plugin>` — switch off without uninstalling, if a plugin gets in the way.
4. `claude plugin details <plugin>` — what a plugin contains and its token cost.
