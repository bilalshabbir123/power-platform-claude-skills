# Contributing

## Before creating a skill

1. Read the existing skills in `skills/` and check that yours doesn't duplicate one. Extend an existing skill if the problem is the same.
2. Copy `templates/SKILL.template.md` to `skills/<skill-name>/SKILL.md` and keep its section order.
3. Add a `README.md` next to it (purpose, when to use, what's inside, related skills).
4. The skill must be about Power Platform: Power Apps, Power Automate, Power BI, Dataverse, Power Pages, AI Builder, Copilot Studio or Microsoft 365 integrations.

## Naming

- Folder and `name:` are the same, lowercase kebab-case, starting with the product: `power-apps-…`, `power-automate-…`, `dataverse-…`, `power-pages-…`, `power-platform-…`, `copilot-studio-…`, `ai-builder-…`, `power-bi-…`.
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
- [ ] No private data (run the check below)

```bash
# must print nothing
grep -rniE "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" skills | grep -v "00000000-0000-0000-0000-000000000000\|<.*>"
```

## Commits and pull requests

- One skill (or one fix) per commit. Message: `Add <skill-name> skill` or `<skill-name>: <what changed>`.
- PR description: the problem the skill solves, the sections included, how examples were checked, and the quality-gate list.
