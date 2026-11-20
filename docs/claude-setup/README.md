# Claude setup guide — the concepts in plain English

Read this top to bottom once. Each part is short. The plugin list is in [recommended-plugins.md](recommended-plugins.md), and `scripts/install-recommended-plugins.sh` installs all of it on a new machine.

---

## 1. The Claude products (which one to use when)

| Product | What it is | Use it for |
|---|---|---|
| **Claude.ai** (web, desktop, mobile) | Chat with Claude. Has Projects, Memory, file uploads, artifacts. | Questions, writing, research, quick documents. |
| **Claude Code** | Claude in your terminal or editor (VS Code, JetBrains, Antigravity, desktop app). It reads and edits files and runs commands. | Building apps, fixing bugs, scripts, deployments, anything in a folder of files. |
| **Cowork** | Claude on your desktop for non-coding desk work: files, reports, research. | Sorting files, weekly reports, research documents. |
| **Claude API / Agent SDK** | Claude called from your own code. | Putting Claude inside your own apps and agents. |

Rule of thumb: **chat to think, Claude Code to build, Cowork to do desk work.**

---

## 2. How Claude Code works

1. Open a terminal in a project folder and type `claude`.
2. You describe the goal. Claude reads files, plans, edits, runs commands, and shows you each step.
3. You approve actions (or set a permission mode that approves safe ones automatically).

### Modes (press Shift+Tab to switch)
- **Normal** — asks before each edit or command.
- **Auto-accept edits** — edits files without asking; still asks for risky commands.
- **Plan mode** — reads and plans only, changes nothing. Use it before any big change.

### The context window
Claude's "working memory" for one session. Everything it reads (files, command output, your messages) fills it.
- `/context` shows how full it is.
- `/compact` summarises the session so far to free space.
- `/clear` starts fresh. Do this between unrelated tasks — a clean context gives better answers.

### Commands you will use every day
| Command | What it does |
|---|---|
| `/help` | All commands. |
| `/init` | Writes a first `CLAUDE.md` for the project. |
| `/memory` | Open and edit memory files. |
| `/plugin` | Browse, install, update plugins. |
| `/skills` | List the skills Claude can use. |
| `/mcp` | List connected MCP servers (tools). |
| `/model` | Change model. |
| `/context`, `/compact`, `/clear` | Manage the context window (above). |
| `/resume` | Pick up an older session. |
| `/code-review` | Review your current changes for bugs. |
| `Esc` | Stop Claude. `Esc Esc` = go back to an earlier message. |
| `! <command>` | Run a shell command yourself; the output goes into the chat. |

---

## 3. Memory: how Claude remembers you and your project

By default each new session starts with a clean slate. These make knowledge stick:

| Layer | Where | What goes in it |
|---|---|---|
| **CLAUDE.md** (project) | Project root, checked into git | How to build/test, rules, architecture, "never do X". Loaded every session. |
| **`.claude/rules/*.md`** | Project | Longer topic rules (deployment, data model). Can be scoped to file paths. |
| **User CLAUDE.md** | `~/.claude/CLAUDE.md` | Your personal preferences for every project (e.g. "short replies, numbered steps"). |
| **Auto memory** | `~/.claude/projects/.../memory/` | Facts Claude saves as it learns (accounts, past mistakes, decisions). |
| **Claude.ai Projects + Memory** | claude.ai | The same idea for chat. |

**Good CLAUDE.md habits**
1. Keep it short (under ~200 lines). Put detail in `.claude/rules/`.
2. Write commands exactly (`npm run build`, not "build it").
3. Write rules as "always / never" with the reason.
4. Update it at the end of a session (handover notes).

A template is in [`templates/CLAUDE.template.md`](../../templates/CLAUDE.template.md).

---

## 4. The five ways to extend Claude

| Extension | One-line meaning | Example |
|---|---|---|
| **Skill** | A folder with `SKILL.md`: instructions + optional scripts for one kind of task. Claude loads it only when the task matches its description. | `frontend-design`, the Power Platform skills in this repo. |
| **Slash command** | A saved prompt you run by name. | `/commit`, `/feature-dev`. |
| **Sub-agent** | A separate Claude with its own context and tools, for a focused job. | A code reviewer agent. |
| **Hook** | A script the harness runs automatically on an event (before a command, after an edit, when Claude stops). | Block `rm -rf`, run Prettier after every edit. |
| **MCP server** | A connector that gives Claude new tools (browser, docs, databases, Figma, Dataverse). | Playwright, Context7. |

**Plugin** = a package that bundles any of the above, installed with one command. **Marketplace** = a GitHub repo that lists plugins.

```
/plugin marketplace add <github-owner>/<repo>     # add a marketplace once
/plugin install <plugin>@<marketplace>            # install a plugin
/plugin marketplace update <marketplace>          # get updates
```

### Which one should I make?
1. "I keep typing the same prompt" → **slash command**.
2. "Claude needs know-how for a type of task" → **skill**.
3. "This must happen every time, no matter what" → **hook** (memory or prompts can't guarantee it).
4. "Claude needs to reach a system it can't touch" → **MCP server**.
5. "I want to share several of these with my team" → **plugin**.

### How skills load (why many skills don't slow Claude down much)
1. Claude always sees each skill's **name + description** (short).
2. It reads the full `SKILL.md` only when your request matches.
3. It reads `references/` files only when the skill points to them.

So the **description decides when a skill fires**. Write it as "Use when …" with the words people actually say. Very large skill libraries still add many descriptions, so install bundles you will use, not everything.

### Anatomy of a skill
```
my-skill/
  SKILL.md          # front matter (name, description) + instructions
  references/       # extra detail, loaded on demand
  scripts/          # code the skill can run
  templates/        # files to copy
```
This repo's required sections and checks are in [CONTRIBUTING.md](../../CONTRIBUTING.md); [`templates/SKILL.template.md`](../../templates/SKILL.template.md) is the starting point.

---

## 5. Prompting: the techniques from the course PDFs

**The 7-part prompt formula:** Persona · Task · Context · Format · Length · Tone · Example.
The course projects use a 4-block version that works very well in Claude Code:

```
Context:     what exists now and why
Instruction: what to do (and "don't ask me questions" if you want it autonomous)
Input:       data, quality bar, constraints
Output:      exactly what files / format you want at the end
```

| Technique | Meaning | When |
|---|---|---|
| **Zero-shot** | Just ask, no examples. | Simple, common tasks. |
| **One-shot** | Give one example of the output you want. | You need a specific format. |
| **Few-shot** | Give 2–5 varied examples. | Style or classification must be consistent. |
| **Chain of thought** | Ask it to reason step by step before answering. | Maths, logic, debugging, decisions. |
| **Reflexion** | Draft → critique against criteria → improve. | Quality matters (proposals, code). Ralph Loop automates this. |
| **Automatic prompt engineering** | Ask Claude to write and test the prompt for you. | You are unsure how to phrase a hard prompt. |

---

## 6. Working patterns that pay off

1. **Plan first.** Plan mode, or "make a plan, don't change anything yet", for anything over ~30 minutes.
2. **Give a way to check.** Tests, `npm run build`, a URL to open. Claude does far better when it can verify.
3. **One task per session.** `/clear` between tasks.
4. **Small commits.** Commit after each working step, so you can always go back.
5. **Loops for polish.** Ralph Loop repeats "review → improve → verify" until a goal is met. Give it a clear finish line and a maximum number of rounds.
6. **Sub-agents for wide searches** and parallel independent work; keep the main session for decisions.
7. **Live docs.** Say "use context7" when working with a library, so Claude reads the current docs instead of guessing.

---

## 7. Agents (Module 4 of the course)

- **Agent** = a model + tools + a loop: it takes a goal, plans, calls tools, checks results, and repeats.
- **Memory** for agents: short-term (the conversation), long-term (a database or files it reads back).
- **Tools**: web search (e.g. Tavily), APIs, databases, MCP servers.
- **Multi-agent**: one coordinator hands focused jobs to specialist sub-agents.
- Build them with the **Claude Agent SDK** (Python/TypeScript), or frameworks such as LangGraph, CrewAI or Microsoft Semantic Kernel / Agent Framework.

---

## 8. Claude + Obsidian (a knowledge base that grows)

- An Obsidian **vault is just a folder of Markdown files** with `[[wiki links]]`. Claude Code can read and write it directly.
- Pattern (Karpathy's "LLM wiki"): drop sources in, Claude turns them into linked, cited notes, and answers questions from the vault later.
- Start: `cd ~/vault && claude`. The `claude-obsidian` plugin adds `/wiki` commands for this.
- Use it from other projects by adding the vault path to that project's `CLAUDE.md`.
- **Only worth it if you feed it regularly** (meeting notes, client research, lessons learned). For one-off questions it is overkill.

---

## 9. Safety

1. Read a plugin or skill before installing it — it can run code on your machine.
2. Never put secrets, client names, tenant IDs or emails in a public repo (this repo's `scripts/check.sh` blocks them).
3. Keep production read-only for Claude; deploy to a test environment first.
4. Use hooks to block dangerous commands rather than relying on instructions.
5. For computer-use / browser automation, use a separate browser profile and stay signed out of anything you don't need.

---

## 10. What is installed (the Inteknix setup)

See [recommended-plugins.md](recommended-plugins.md) for each plugin, what it is for, and how to use it. To rebuild the setup on a new machine:

```bash
git clone https://github.com/bilalshabbir123/power-platform-claude-skills.git
cd power-platform-claude-skills
scripts/install-recommended-plugins.sh
```
