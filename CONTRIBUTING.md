# Contributing

## Before creating a skill

1. Read the existing skills in `plugins/*/skills/` and check that yours doesn't duplicate one. Extend an existing skill if the problem is the same.
2. Put it in the plugin for its technology: `plugins/<technology>/skills/<skill-name>/SKILL.md`. Copy `templates/SKILL.template.md` and keep its section order.
3. Add a `README.md` next to it (purpose, when to use, what's inside, related skills).
4. Add at least **two eval cases** in `plugins/<technology>/evals/<case>/` (see `docs/testing-skills.md`).
5. Add a row to the root `README.md` table and, if it's a new kind of request, a line in the hub skill's decision table (`power-platform-solution-builder`).
6. Scope: Microsoft Power Platform, Microsoft 365 / SharePoint, and technologies used *with* them in business apps (React UI, custom AI models). Explain the Power Platform / Microsoft 365 angle in the skill.

## Adding a new technology

1. Create `plugins/<technology>/.claude-plugin/plugin.json` (`name`, `description`, `version`, `author`, `repository`, `keywords`) and `plugins/<technology>/README.md`.
2. Add the plugin to `.claude-plugin/marketplace.json` (`name`, `source: "./plugins/<technology>"`, `description`).
3. Add skills and evals as above.
4. Run `scripts/check.sh` and `claude plugin validate .`.
5. Bump `version` in the plugin's `plugin.json` whenever its skills change (and the marketplace `metadata.version` for structural changes).

## Naming

- Folder and `name:` are the same, lowercase kebab-case, starting with the product or technology: `power-apps-…`, `power-automate-…`, `dataverse-…`, `power-pages-…`, `power-platform-…`, `copilot-studio-…`, `ai-builder-…`, `power-bi-…`, `sharepoint-…`, `react-…`, or the library name (`react-bits-…`, `unsloth-…`).
- Plugin folders are the technology: `power-platform`, `sharepoint`, `react`, `ai-models` (add new ones the same way).
- Skill names are unique across the whole repo.
- The name says the specific problem (`power-automate-dataverse-triggered-flows`), not a generic area (`power-automate-tips`).
- `description:` says **what** the skill does and **when** to use it, with words people actually type (Claude uses it to decide when to load the skill). Keep it under 1,024 characters.

## Content rules

- Solve one specific Power Platform challenge. No generic advice.
- Use environment variables, connection references and solutions in every example. No hard-coded URLs, emails, IDs or tenants.
- Never include real customer, company, person, tenant or environment details. Use `contoso`, `cr123_` prefixes and placeholder GUIDs.
- Label claims: **[Microsoft]** with a Microsoft Learn link, or **[Field-tested]** with how to re-check it.
- Cover managed and unmanaged scenarios, DLP, licensing, scalability and error handling.
- Examples must be realistic and runnable. If something can't be tested automatically, say so and give the manual test.

## Quality gate

A skill is **not complete** until every box is ticked:

- [ ] Purpose, when to use, expected outcome
- [ ] Expertise section (architect, developer, automation specialist, MVP practices)
- [ ] Instructions: design approach, development standards, governance, security, performance, ALM
- [ ] Beginner, intermediate and advanced enterprise examples
- [ ] Common mistakes with how to avoid each
- [ ] Validation checklist: security, performance, ALM, solution packaging, deployment readiness
- [ ] Governance and DLP covered
- [ ] API limits / delegation / Dataverse / flow performance covered where relevant
- [ ] Licensing impact stated
- [ ] Naming and repository structure followed
- [ ] `README.md` present
- [ ] At least two eval cases; `claude plugin eval` run and the with-skill score is not lower than without
- [ ] `SKILL.md` under 500 lines; longer detail moved to `references/` with a note on when to read each file
- [ ] Third-party code is linked, not copied, when its licence restricts redistribution
- [ ] No private data (run the check below)

```bash
# must end with "All checks passed"
scripts/check.sh
```

## Commits and pull requests

- One skill (or one fix) per commit. Message: `Add <skill-name> skill` or `<skill-name>: <what changed>`.
- PR description: the problem the skill solves, the sections included, how examples were checked, and the quality-gate list.
