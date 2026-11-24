# Lessons learned

Real mistakes made while building and releasing an enterprise Power Apps code app (React + Dataverse + Power Automate), while building a personal-productivity code app on Dataverse, while building an offline field-service PWA on Azure (React + ASP.NET Core + Azure SQL), while writing client proposals and technical summaries, and while building this skills repo, what caused each one, and the skill or practice that now prevents it. Details are anonymised.

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
| 28 | Every create/update with a lookup failed with `0x80048d19` | Columns created with mixed-case SchemaName; the code-app bridge binds with the lowercase logical name | `power-apps-code-app-dataverse-data-access` |
| 29 | Publishing with `pac code push` returned HTTP 400 (`workflowDetails`) | App referenced a flow; older CLI generation | `power-apps-code-app-deployment` (use `pa app push`) |
| 30 | A command in one project ran against another tenant | `pac` auth profiles are shared by every terminal; another window had switched profile | `power-apps-code-app-deployment` (per-project wrapper script) |
| 31 | Twin check-in rows for the same day | Two UI events ran find-or-create at once with stale state | `power-apps-code-app-dataverse-data-access` (in-flight map) |
| 32 | Lists reordered on unrelated pages | In-place sort of a shared store array | `power-apps-code-app-dataverse-data-access` |
| 33 | Routine times shown an hour late after the clock change | Wall-clock times stored UTC-converted | `power-apps-code-app-dataverse-data-access` |
| 34 | Delete dimmed the screen but showed no dialog | Dim layer and dialog rendered separately in the player frame | `power-apps-code-app-business-rules-testing` |
| 35 | "Fix didn't work" reports after a publish | Player's own cached "old version — Refresh" banner | `power-apps-code-app-deployment` |
| 36 | Files couldn't be uploaded to SharePoint from the app | Connector client can't send file content | Instant flow with a File input (`power-platform-solution-builder` code-apps reference) |
| 37 | UI tests "passed" that never ran file pickers or drag-and-drop | Automation can't reach inside the cross-origin player iframe | `power-apps-code-app-business-rules-testing` (list manual tests) |
| 38 | Two surveys for one job after an office PC and a tablet both started it | Each device generated a random ID for a record that should be one per parent | `pwa-offline-first-sync` (UUID v5 from the parent ID + server merge-create) |
| 39 | Users saw "Sync failed – retrying" with no clue why | The panel didn't show the HTTP status or message | `pwa-offline-first-sync` |
| 40 | No sync after aeroplane mode / Control Centre on iPhone | iOS didn't fire the `online` event | `pwa-offline-first-sync` (also sync on visibility and focus) |
| 41 | Reassigned jobs stayed on the old surveyor's tablet | Pull returned changes only, not the user's current scope | `pwa-offline-first-sync` (scope reconciliation) |
| 42 | App broken for 9 days mid-month | Free Azure SQL database used its monthly compute and auto-paused | `azure-low-cost-poc-hosting` |
| 43 | Free compute used up in 10 days | A 60-second poll from one open tab kept the serverless database awake | `azure-low-cost-poc-hosting`, `pwa-offline-first-sync` |
| 44 | Couldn't stop database charges after a demo | Free-limit behaviour BillOverUsage can't be changed back to AutoPause | `azure-low-cost-poc-hosting` |
| 45 | ~2-minute first page load | App Service Free F1 has no Always On and sleeps when idle | `azure-low-cost-poc-hosting` (B1 + Always On for demos) |
| 46 | Deploy result unknown | Deploy window closed after "Warmed up Kudu instance"; nobody checked the live bundle | `azure-low-cost-poc-hosting` |
| 47 | Server PDF generation failed with a licence exception | A newer major version of a PDF library changed its licensing | `azure-low-cost-poc-hosting` (check the exact version's licence) |
| 48 | Couldn't assign app roles to users | "Add user/group" needs enterprise app Owner or Cloud Application Administrator | `entra-id-msal-pwa-sign-in` |
| 49 | Docs said Standard LRS, the storage account was GRS | SKU not checked after creation | `azure-low-cost-poc-hosting` |
| 50 | Client's screen list left out the price list they had asked for in the demo | Requests spread across two meetings and a separate list | `pwa-client-requirements-clarification-doc` (mark "(proposed)" and ask) |
| 51 | AI meeting recap stated things not quite said in the call | Recap used without checking the transcript | `pwa-client-requirements-clarification-doc` |
| 52 | Proposal nearly sent with `£00,000` prices | Placeholders typed as numbers | `power-platform-proposal-and-technical-docs` (`[£TBC]` + pre-send search) |
| 53 | Same proposal said 100 and 20 documents, 5 and 10 users, 60 and 40 checklist items | Each section written separately, no single source of numbers | `power-platform-proposal-and-technical-docs` (facts sheet) |
| 54 | Phase rows added to ~9.5 days but the summary said 17-19 | Totals typed by hand | `power-platform-proposal-and-technical-docs` (sum in the generator) |
| 55 | Running costs differed between two sections | Figures copied before an update | `power-platform-proposal-and-technical-docs` |
| 56 | Reissued proposal still carried old-approach items (Copilot Studio licence, "exclusively Microsoft", no-MFA service account) | Old document patched instead of rewritten | `power-platform-proposal-and-technical-docs` (rewrite from the facts sheet) |
| 57 | RfP asked for UK/EU data residency; the proposed AI plan stores data in the US | Plan checked against the product, not the tier sold | `power-platform-proposal-and-technical-docs` (vendor confirmation + client acceptance in writing) |
| 58 | Draft promised audit compliance on a plan with no audit log | Top-tier features assumed | `power-platform-proposal-and-technical-docs` (licence/plan check) |
| 59 | Client contact couldn't follow deliverable tables; four rounds of "I don't understand" | Technical wording, abstract steps | `power-platform-proposal-and-technical-docs` (plain words + one example) |
| 60 | 20-row component list repeated itself | Same thing named three ways (vault/catalogue, forms/lists/flows) | `power-platform-proposal-and-technical-docs` (one merged table with days) |
| 61 | "See section 13" pointed at the wrong section | Section inserted, references not rechecked | `power-platform-proposal-and-technical-docs` |
| 62 | Generated .docx body text in Times New Roman | Font set on headings only | `power-platform-proposal-and-technical-docs` (font on every run + Normal style) |
| 63 | "3-page" summary longer in Word than in the preview | Page count taken from Quick Look | `power-platform-proposal-and-technical-docs` (Word PDF export + `pdfinfo`) |

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
10. Keep two tenants apart on one machine: wrap every CLI call in a script that selects and checks the account/environment, and restores it afterwards.
11. Free cloud tiers need an owner: someone scales up before a demo and back down after, and nobody flips a one-way billing setting "just for the demo".
12. Every client document is generated from one facts sheet by a script, and its numbers, totals, plan features and page count are checked before it is sent.
