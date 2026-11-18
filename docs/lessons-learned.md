# Lessons learned

Real mistakes made while building and releasing an enterprise Power Apps code app (React + Dataverse + Power Automate), and while building this skills repo, what caused each one, and the skill or practice that now prevents it. Details are anonymised.

| # | What went wrong | Root cause | Prevented by |
|---|---|---|---|
| 1 | Totals and lists were silently too low (e.g. 49.6 h instead of 452.5 h) | Data client's default page size (500) and `$top` stopped paging; `skipToken` ignored | `power-apps-code-app-dataverse-data-access` |
| 2 | A new field never saved in production, though the release was called "ready" | Retry stripped a fixed list of new columns on any error; that form wasn't tested | `power-apps-code-app-dataverse-data-access`, `power-platform-solution-release-alm` |
| 3 | Published change not visible to users | Edited a file after building; publish uploads the existing build | `power-apps-code-app-deployment` |
| 4 | Publishing failed with "multiple accounts" / wrong account | Cached CLI credentials for two accounts | `power-apps-code-app-deployment` |
| 5 | Git, tests and builds hung | Repository in a cloud-synced folder; `node_modules` evicted to online-only | `power-apps-code-app-deployment` |
| 6 | "Raise invoice" task created for a project invoiced weeks earlier | Rule checked the trigger (status changed) and a title, not whether an invoice existed | `power-apps-code-app-business-rules-testing` |
| 7 | Duplicate records on rename | Duplicate check matched the title | `power-apps-code-app-business-rules-testing` |
| 8 | Pop-up opened behind the task window | Each component chose its own z-index | `power-apps-code-app-business-rules-testing` |
| 9 | Dates saved as year 0002 | Linked date logic ran on every keystroke of a native date input | `power-apps-code-app-business-rules-testing`, `power-apps-code-app-dataverse-data-access` |
| 10 | Support emails longer than ~2,000 characters failed to create tickets | Flow cut text to 3,990 for a 2,000-character column | `power-automate-dataverse-triggered-flows` |
| 11 | Two approvals and an overwritten status from one change | Trigger delivered twice within milliseconds; no concurrency control | `power-automate-dataverse-triggered-flows` |
| 12 | Duplicate tasks from rapid ticket saves | Create-if-missing ran in parallel runs | `power-automate-dataverse-triggered-flows` |
| 13 | Mailbox flow silently stopped for four days | A shared connection reference was repointed; only run history was watched | `power-automate-dataverse-triggered-flows` |
| 14 | Flow couldn't be turned on | Connection references owned by different accounts | `power-automate-dataverse-triggered-flows` |
| 15 | Send from shared mailbox failed in live test | Read access checked, Send As not | `power-automate-dataverse-triggered-flows` |
| 16 | Notification never sent | Static (mocked) result left on an action | `power-automate-dataverse-triggered-flows` |
| 17 | Reference parsed from an email subject could break the filter | No GUID validation before use in OData | `power-automate-dataverse-triggered-flows` |
| 18 | Any user could make themselves admin | Team Member role could create rows in the app's role table | `dataverse-security-roles-for-code-apps` |
| 19 | Role script "remove" step failed for weeks unnoticed | Wrong parameter shape for `RemovePrivilegeRole`; statuses not checked | `dataverse-security-roles-for-code-apps` |
| 20 | Comments stopped saving on busy records | History appended to a 4,000-character column | `power-apps-code-app-dataverse-data-access` |
| 21 | An import would have switched on flows production had turned off | No snapshot of flow states before the managed upgrade | `power-platform-solution-release-alm` |
| 22 | Risk of DEV recipients in production | Environment variable values included in the solution | `power-platform-solution-release-alm`, `power-automate-dataverse-triggered-flows` |
| 23 | Insights card showed yesterday's numbers next morning | "Today" computed once when the page opened | `power-apps-code-app-business-rules-testing` |
| 24 | Skill eval failed every run, even for correct answers | One grader bundled four requirements and an optional extra | [testing-skills.md](testing-skills.md): one statement per grader |
| 25 | Skills for several technologies were hard to find and install | Flat `skills/` folder with no grouping | One plugin per technology + marketplace manifest + hub skill |
| 26 | Same rules repeated or contradicted across products | One-size advice (e.g. canvas row limits applied to code apps) | `power-platform-solution-builder` loads only the matching reference |
| 27 | Canvas advice said the data row limit maxes at 2,000 | Model knowledge out of date (current maximum is 10,000) and the fact sat only in a hub reference file | `power-apps-canvas-app-delegation-performance` + an eval grader that checks the current limit |

## Working rules that came out of this

1. Never call a release ready while anything is untested. List untested items as blockers.
2. Production is read-only for builders; it changes only through a managed solution.
3. Every messaging flow has a test-recipient switch; tests never reach customers or team channels.
4. Read the SDK or metadata instead of assuming defaults (page size, MaxLength, action parameters).
5. Check every status a script prints, and check trigger history as well as run history.
6. Back up every field a test write touches before writing.
7. One rule module per business rule; test the precondition-false case.
8. Every skill ships with eval cases and is checked with and without the skill before release.
9. Link third-party code instead of copying it when its licence restricts redistribution.
