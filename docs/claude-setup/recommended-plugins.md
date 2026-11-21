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
| `compound-engineering-plugin` | `claude plugin marketplace add EveryInc/compound-engineering-plugin` | Every |
| `playwright-skill` | `claude plugin marketplace add lackeyjb/playwright-skill` | Community (lackeyjb, MIT) |
| `21st-dev` | `claude plugin marketplace add 21st-dev/magic-mcp` | 21st.dev |

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
| **compound-engineering** | compound-engineering-plugin | Plan → work → review → "compound" (each fix is written up so the next task is faster). Overlaps with superpowers: use one per project. | `/ce-plan`, `/ce-work`, `/ce-code-review`, `/ce-compound`; `/ce-help` lists all. |
| **playwright-skill** | playwright-skill | Claude writes and runs its own Playwright scripts (screenshots, form and login tests). | Run its `npm run setup` once (downloads Chromium), then "use Playwright to test <url>". |
| **21st** (was Magic MCP) | 21st-dev | Ready-made React/Tailwind UI components from 21st.dev. | Needs a free key from https://21st.dev/mcp in `API_KEY_21ST` (shell profile). |
| **graphify** (skill, not a plugin) | — (PyPI `graphifyy`) | Turns a folder (code, docs, PDFs) into a knowledge graph Claude queries instead of searching. | Install: `pipx install graphifyy && graphify install`. Use: `/graphify .` |

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

## Batch 2 (added 2026-11-21): design, writing, research and scraping

Installed for all projects (user scope) and in the new-project template.

| Tool | What it does | Install | When to use / notes |
|---|---|---|---|
| **REA** (morluto/rea) | "Reverse Engineer Anything": Claude inspects an app, API or binary without its source code. | `claude plugin marketplace add morluto/rea` then `claude plugin install rea@rea` | Working out how an undocumented API or a third-party app behaves. Only on software you're allowed to inspect. |
| **Ponytail** (DietrichGebert/ponytail) | Rules that make Claude write only the code a task needs: reuse first, no new dependencies unless needed. `/ponytail-debt` lists shortcuts left for later, `/ponytail-help` gives a quick reference. | `claude plugin marketplace add DietrichGebert/ponytail` then `claude plugin install ponytail@ponytail` | Any coding project. Defaults kept: the task log stays local (`~/.config/ponytail/band/`), no webhook. Change with `/plugin configure ponytail@ponytail`. |
| **Hallmark** (nutlope/hallmark) | Anti-"AI look" design skill. `hallmark audit` scores a UI (no edits), `hallmark redesign` rebuilds the layout keeping the text, `hallmark study` copies the style of a screenshot or URL. | `claude plugin marketplace add nutlope/hallmark` then `claude plugin install hallmark@hallmark` | Client-facing screens and sites. |
| **Humanizer** (blader/humanizer) | Rewrites text to remove signs of AI writing. | `claude plugin marketplace add blader/humanizer` then `claude plugin install humanizer@humanizer` | Proposals, emails, LinkedIn posts: `/humanizer:humanizer` then paste the text. |
| **Impeccable** (pbakaus/impeccable) | Frontend design skill with design commands (polish, audit, typography, colour). | `claude plugin marketplace add pbakaus/impeccable` then `claude plugin install impeccable@impeccable` | Run `/impeccable init` once per project. |
| **UI UX Pro Max** (nextlevelbuilder) | Large design database: styles, colour palettes, font pairs, UX rules, chart types. | `claude plugin marketplace add nextlevelbuilder/ui-ux-pro-max-skill` then `claude plugin install ui-ux-pro-max@ui-ux-pro-max-skill` | Choosing a look for a new app or site. Its search script needs Python 3. |
| **Last 30 Days** (mvanhorn/last30days-skill) | Researches a topic across Reddit, X, YouTube, Hacker News, news and the web for the last 30 days. | `claude plugin marketplace add https://github.com/mvanhorn/last30days-skill.git` (the short form failed here) then `claude plugin install last30days@last30days-skill` | "What are people saying about X?" Works with no keys (web only); the first run offers optional keys, stored in the keychain. |
| **Scrapling** (D4Vinci/Scrapling) | Web scraping MCP server + skill: plain HTTP, stealth browser, JavaScript pages. | `python3.13 -m venv ~/.local/share/scrapling-venv`, `~/.local/share/scrapling-venv/bin/pip install "scrapling[ai]"`, then `claude mcp add --scope user scrapling -- ~/.local/share/scrapling-venv/bin/scrapling-mcp` | When normal fetch fails. Browser mode needs `~/.local/share/scrapling-venv/bin/scrapling install` once (downloads browsers). Respect each site's terms. |
| **Diagram Design** | Business-style diagrams in Excalidraw. | Private repo (no open licence). | Architecture and process diagrams for proposals. |
| **Onyx** | Not installed: probably onyx-dot-app/onyx, a self-hosted AI chat and company search platform (Docker), not a Claude skill. | — | Confirm which Onyx is meant. |

Overlap: Hallmark, Impeccable, UI UX Pro Max and the official frontend-design all guide UI design. Name the one you want in the prompt ("use hallmark to audit this page") so they don't pull in different directions.
