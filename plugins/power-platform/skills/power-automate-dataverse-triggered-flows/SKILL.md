---
name: power-automate-dataverse-triggered-flows
description: Build reliable Power Automate cloud flows that support a code app — triggered by Dataverse row changes or by a shared mailbox — without duplicates, loops, failures on long text, silent trigger outages, or test messages reaching real people. Use when a flow creates duplicate records, fails only for long emails, stops picking up emails, can't be turned on (ConnectionAuthorizationFailed), sends from a shared mailbox, or needs a safe test mode for Teams/email notifications.
---

# Dataverse- and mailbox-triggered flows for a code app

## Purpose
- **What it does:** design rules, standard building blocks and test steps for flows that react to Dataverse changes or incoming email and write back to Dataverse, Teams or Outlook.
- **When to use it:** creating or changing any automated flow behind a code app; diagnosing duplicates, missing runs, failed runs or wrong recipients.
- **Expected outcome:** each flow runs once per real change, can't loop, writes only valid data, fails loudly, and in non-production sends messages only to a test recipient.

## Expertise
- **Architects** keep flows in the app's solution, connected through **connection references** and configured through **environment variables**, so the same flow works in DEV, TEST and PROD.
- **Automation specialists** assume a trigger can fire more than once or close together, and design *create-if-missing* steps to be safe under concurrency.
- **Dataverse specialists** respect column limits and validate any value parsed from text before using it in a filter.
- **MVP practice:** monitor the **trigger** as well as the runs — a polling trigger that keeps failing creates **no runs**, so run history just looks quiet.

## Instructions

### Design approach
1. **Solution-aware only.** Create flows inside the solution. Use connection references for every connector and environment variables for every address, ID, channel, threshold and switch.
2. **Narrow triggers.** On the Dataverse trigger *When a row is added, modified or deleted*, set **Change type**, **Select columns** (only the columns that matter) and **Filter rows** (OData) or **trigger conditions**. This cuts runs, cost and loops.
3. **No self-loops.** If the flow updates the same table it triggers on, filter on columns the flow never writes, or add a condition that the change wasn't made by the flow's own account.
4. **Create-if-missing must be safe under concurrency.** Two saves seconds apart start two runs that both see "no record yet" and both create one. Options, strongest first:
   - an **alternate key** on the target table, with an *upsert*;
   - **trigger concurrency = 1** (Settings → Concurrency control → Degree of parallelism 1) so runs queue;
   - a **claim** pattern: write a claim value, wait a few seconds, re-read, and continue only if your claim won.
   **[Field-tested]** A Dataverse trigger delivered one status change twice, 2 ms apart; both runs sent an approval, and the second overwrote the first run's result. With concurrency 1, three saves within 0.2 s produced exactly one record.
   Note: changing trigger concurrency later may not be fully reversible; decide deliberately.
5. **Fail loudly.** Wrap the work in a `Try` scope, add a `Catch` scope with *run after = has failed / timed out*, set a status on the record (e.g. *Send failed*), and alert the owner. Never leave a record stuck in *Awaiting…*.

### Development standards
- **Text into Dataverse: cut to the column's MaxLength.** Read it from metadata (see `power-apps-code-app-dataverse-data-access`) and use `substring(text, 0, min(length(text), N))` with N = MaxLength minus a margin. Keep the full text somewhere sized for it (an activity, a note, or a Multiline column).
  **[Field-tested]** A support-email flow cut descriptions to 3,990 characters but the column held 2,000. Every email longer than that failed to create a ticket, and it only surfaced during QA.
- **Values parsed from subjects or bodies** (e.g. `[REF:<id>]`): validate before use. A GUID check in an expression:
  `and(equals(length(v),36), equals(substring(v,8,1),'-'), equals(substring(v,13,1),'-'), equals(substring(v,18,1),'-'), equals(substring(v,23,1),'-'))` — plus check that the other characters are hex — then use it in a filter as `cr123_ticketid eq <guid>`. Escape any text used in `Filter rows` (`replace(v, '''', '''''')`).
- **Lookups:** bind with the entity set and ID — `/cr123_tickets(<guid>)`. **[Field-tested]** Binding a bare GUID failed.
- **Email to text:** convert HTML with the *Content Conversion → Html to text* action before storing or summarising.
- **Matching replies to records:** prefer an explicit reference in the subject; fall back to the Outlook **conversation ID** stored on the record; then to same sender + same normalised subject (strip `RE:`/`FW:`) on an *open* record.
- **Skip lists:** ignore auto-senders (no-reply, mailer-daemon, postmaster, DMARC reports, your own mailbox) before creating anything.
- **Static results (mocking)** are for testing only. **[Field-tested]** A flow had a mocked "send DM" result left on and never actually sent. Check every action's *Static result* setting before release.

**Test mode for notifications** (mandatory for any flow that emails or messages people):
- Environment variable `cr123_NotificationTestRecipient`: when it has a value, **every** email/Teams message goes only to it, with `[TEST]` in the subject and the intended recipients listed in the body.
- Environment variable `cr123_<Feature>MessagesLive` (`yes`/`no`) to switch a subset of messages to real people in production while others stay in test mode.
- Never post test runs to a real team channel; skip the channel post when the record is marked as a test, or in non-production.
- Prefer Teams for internal team messages if that's what the team uses; keep email for external or formal notices.

### Governance and DLP
- Keep Dataverse, Office 365 Outlook, Teams, SharePoint, Approvals and Content Conversion in the **same DLP group** (Business). **[Microsoft]** If an app triggers a flow and both use Dataverse, grouping the two Dataverse connectors differently can make the app non-compliant.
- Block or restrict the HTTP connector unless there's an approved need.
- **One owner per flow's connections.** **[Field-tested]** A flow whose connection references belonged to two different accounts couldn't be turned on by either one (`ConnectionAuthorizationFailed`). Pattern that works: connections created by the flow owner, **signed in as a service account** (for example a shared "automation" mailbox user).
- **Shared mailboxes:** check **Send As / Send on behalf** rights as well as read access. **[Field-tested]** A flow could read a shared inbox but failed at the send step with `ErrorSendAsDenied`, which only showed up in a live test.
- **Never repoint a shared connection reference** without listing every flow that uses it. **[Field-tested]** Repointing one reference to a personal Outlook connection broke another flow's mailbox trigger for four days ("Default folder Inbox not found").

### Security
- Run as a **service account** (or flow owner with a non-personal connection), not a developer's personal account, in TEST and PROD.
- Least privilege for the service account's Dataverse role (only the tables the flow touches).
- Don't put secrets in flow definitions; use environment variables of type *Secret* (Azure Key Vault) where needed.
- Treat email content as untrusted: escape it, validate references, never execute links or attachments, and save attachments to a controlled library.

### Performance
- **Request limits** **[Microsoft]**: every trigger and action counts as a Power Platform request. 24-hour limits: 40,000 per user (Power Automate Premium / Power Apps Premium), 6,000 (Microsoft 365 / free), 250,000 per Process licence (stackable, solution flows only). There is also a 5-minute limit of 100,000.
- Polling triggers (every minute) cost requests all day — use the longest interval the business accepts, and working-hours schedules (`Recurrence` with hours/weekdays).
- Filter server-side (`Filter rows`, `Select columns`), avoid `List rows` inside `Apply to each`, and set `Apply to each` concurrency deliberately (default is sequential).
- Use the *Row ID* trigger output and `Get a row by ID` with `Select columns` instead of re-listing tables.

### ALM
- Flows, connection references and environment variable **definitions** go in the solution; **values** are set per environment (deployment settings file or after import). Don't ship DEV values inside the solution.
- If you edit flow definitions programmatically (Dataverse `workflows.clientdata`), **back up the current clientdata first**, change one thing, save, then turn the flow off and on so the trigger re-registers, and check the next trigger fires. Activation validates the definition; read the error.
- Keep the generator script or exported definition in Git.

### Licensing
- Flows that use Dataverse, premium connectors or HTTP need **Power Automate Premium** for the owner (or the flow runs in the context of a Power Apps Premium app's users), or a **Process** licence for high-volume flows **[Microsoft]**.

## Examples

### Beginner — notify the assignee when a task's priority goes to High, test-safe
- Trigger: Dataverse *modified*, table `cr123_task`, Select columns `cr123_priority`, Filter rows `cr123_priority ge 3 and statecode eq 0`.
- Compose `To`: `if(empty(parameters('Test Recipient (cr123_NotificationTestRecipient)')), outputs('Get_assignee_email'), parameters('Test Recipient (cr123_NotificationTestRecipient)'))`.
- Teams *Post message in a chat with Flow bot* to `To`; skip if the modifier is the assignee.

### Intermediate — support email → ticket, no duplicates, no failures on long text
1. Trigger: *When a new email arrives in a shared mailbox (V2)*, with attachments.
2. Skip auto-senders.
3. Find the ticket: subject `[REF:…]` (validated GUID) → stored conversation ID → open ticket with same sender + normalised subject.
4. Found → add an *email in* activity with the full text and set status back to *In progress*.
5. Not found → create the ticket with `description = substring(text, 0, min(length(text), 1990))` for a 2,000-character column, and the full text in an activity.
6. Save attachments to the support library; store the link (cut to its column length).
7. `Catch` scope: alert the owner with the run link.

### Advanced (enterprise) — one record per parent under bursts, with a manual backfill
- Sync flow: trigger on ticket create/update (Select columns: title, assignee, status, priority, SLA), **concurrency 1**. Find the task by `contains(cr123_labels, 'ticket:<id>')` → update it or create it. Map statuses: Resolved/Closed → Completed; Pending client → Blocked; reopened → open.
- Backfill flow (instant, manual): list open assigned tickets with no task and *touch* each (update a harmless field) so the sync flow creates the task. Run once after deployment.
- Test plan: three saves in under a second → one task; status round trip; deleted ticket → task completed.

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Create-if-missing without concurrency control | Duplicate records/approvals | Alternate key + upsert, concurrency 1, or claim |
| Cutting text longer than the column | Run fails only for long input | Read MaxLength; cut with margin |
| Using parsed text in a filter unchecked | Filter errors or injection | Validate GUID; escape quotes |
| Mixed connection owners | Flow can't be turned on | One owner; service account sign-in |
| Assuming shared-mailbox send rights | Fails at send in production | Test Send As before go-live; Catch + status |
| Watching only run history | Broken polling trigger unnoticed for days | Check trigger history after every change |
| Static result left on | Messages never sent | Review static results before release |
| No test recipient | Test messages reach customers or team | Test-recipient env var on every messaging flow |
| Flow writes the column it triggers on | Infinite loop | Select columns / trigger conditions |
| DEV env var values in the solution | PROD uses DEV recipients/IDs | Ship definitions only; set values per environment |

## Validation checklist

### Security
- [ ] Runs under a service account; connections all owned consistently
- [ ] Email/text input escaped and validated before filters
- [ ] Test-recipient variable set in every non-production environment

### Performance
- [ ] Trigger has Select columns + Filter rows / conditions
- [ ] No List rows inside loops; polling interval justified
- [ ] Daily request use estimated against the owner's entitlement

### ALM
- [ ] Flow, connection references, env var definitions in the solution; no env var values
- [ ] Definition backed up before programmatic edits; generator/export in Git

### Solution packaging
- [ ] Every connection reference the flow uses is in the solution
- [ ] New columns/tables the flow writes are in the solution

### Deployment readiness
- [ ] Burst test (several saves within a second) → one record
- [ ] Long-text test (over the column limit) → succeeds
- [ ] Failure test → status set + alert sent
- [ ] Trigger history checked after activation (not just runs)
- [ ] Static results off

## References
- [Microsoft] [Requests limits and allocations](https://learn.microsoft.com/power-platform/admin/api-request-limits-allocations)
- [Microsoft] [Limits of automated, scheduled and instant flows](https://learn.microsoft.com/power-automate/limits-and-config)
- [Microsoft] [Trigger flows when a row is added, modified or deleted](https://learn.microsoft.com/power-automate/dataverse/create-update-delete-trigger)
- [Microsoft] [Use environment variables in solutions](https://learn.microsoft.com/power-apps/maker/data-platform/environmentvariables)
- [Microsoft] [Data policy known limitations](https://learn.microsoft.com/power-platform/admin/dlp-known-issues)
