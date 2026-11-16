# Power Platform Claude Skills

Production-ready [Claude Code skills](https://docs.claude.com/en/docs/claude-code/skills) for building on Microsoft Power Platform: Power Apps **code apps**, Dataverse, Power Automate and solution ALM.

Every skill here comes from real delivery work on an enterprise code app (React + TypeScript + Vite on Dataverse, with 30+ Power Automate flows and managed solution releases to production). Each one solves **one specific problem** we hit, explains the mistake that caused it, and gives the checks that stop it happening again.

## Skills

| Skill | Solves | Products |
|---|---|---|
| [`power-apps-code-app-deployment`](skills/power-apps-code-app-deployment/) | Publishing a code app reliably: stale builds, wrong account, version proof, environment setup | Power Apps code apps, Power Apps CLI |
| [`power-apps-code-app-dataverse-data-access`](skills/power-apps-code-app-dataverse-data-access/) | Reading and writing Dataverse from a code app without silent truncation, lost saves or throttling | Power Apps code apps, Dataverse |
| [`power-apps-code-app-business-rules-testing`](skills/power-apps-code-app-business-rules-testing/) | Automatic records created at the wrong time, duplicate records, date bugs, player-only UI bugs | Power Apps code apps, Dataverse |
| [`power-automate-dataverse-triggered-flows`](skills/power-automate-dataverse-triggered-flows/) | Flows triggered by Dataverse or mailboxes that duplicate, fail on long text, or silently stop | Power Automate, Dataverse, Microsoft 365 |
| [`dataverse-security-roles-for-code-apps`](skills/dataverse-security-roles-for-code-apps/) | Real security for a code app: least-privilege roles, no self-promotion, role scripts that actually work | Dataverse, Power Apps |
| [`power-platform-solution-release-alm`](skills/power-platform-solution-release-alm/) | Moving a code app and its flows to production with managed solutions, without surprises | Solutions, Dataverse, Power Automate |

The full list of mistakes these skills prevent is in [docs/lessons-learned.md](docs/lessons-learned.md).

## Install

Skills are folders that contain a `SKILL.md`. Claude Code loads them from:

- **Personal (all projects):** `~/.claude/skills/<skill-name>/`
- **One project (shared with the team through Git):** `<project>/.claude/skills/<skill-name>/`

```bash
git clone https://github.com/bilalshabbir123/power-platform-claude-skills.git
# all skills, for every project
mkdir -p ~/.claude/skills
cp -R power-platform-claude-skills/skills/* ~/.claude/skills/
# or one skill, for one project
mkdir -p .claude/skills
cp -R power-platform-claude-skills/skills/power-apps-code-app-deployment .claude/skills/
```

Restart Claude Code. A skill is used automatically when your request matches its `description`, or you can ask for it by name ("use the power-apps-code-app-deployment skill").

## Repository structure

```
skills/
  <skill-name>/
    SKILL.md      # what Claude reads: frontmatter (name, description) + full instructions
    README.md     # what people read: purpose, when to use, what's inside
templates/
  SKILL.template.md   # the required structure for every new skill
docs/
  lessons-learned.md  # every mistake, its cause, and the skill that prevents it
CONTRIBUTING.md       # standards and the quality gate
```

## Standards (summary)

Every skill must have: a clear purpose, an expertise section, detailed instructions (design, development standards, governance, security, performance, ALM), beginner / intermediate / advanced examples, common mistakes, and a validation checklist (security, performance, ALM, solution packaging, deployment readiness). See [CONTRIBUTING.md](CONTRIBUTING.md) for the quality gate.

Each recommendation is labelled where it matters:

- **[Microsoft]**: from Microsoft Learn documentation (linked).
- **[Field-tested]**: observed and verified on a real tenant. Behaviour can change between CLI or SDK versions, so the skill says how to re-check it.

## Disclaimer

Licensing, limits and CLI commands change. The skills link to the Microsoft Learn pages they rely on; check those before making licensing or capacity decisions.
