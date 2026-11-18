---
name: power-apps-code-app-business-rules-testing
description: Design and test the business rules inside a Power Apps code app — automatic records (tasks, reminders, invoices) the app creates on a status change, duplicate prevention, date/week logic, and UI behaviour inside the Power Apps player. Use when the app creates a record it shouldn't (e.g. "raise invoice" for an already-invoiced project), creates duplicates, shows wrong "today/this week" numbers, or when adding unit tests (Vitest) and a release test plan to a code app.
---

# Business rules and testing in a code app

## Purpose
- **What it does:** a pattern for rules that create or change records automatically, a test strategy (pure functions + Vitest + break tests + a short manual player test), and the player-specific UI pitfalls to test for.
- **When to use it:** adding any "when X changes, create/close Y" behaviour; reviewing a bug where an automatic record was wrong or duplicated; before every release.
- **Expected outcome:** automatic records are created only when the real business state needs them, exactly once, the same rule is used everywhere, and each rule has tests including edge cases.

## Expertise
- **Architects** put each business rule in **one pure module** used by every screen, the automation and the reports, so they can't disagree.
- **Developers** make side effects **idempotent** (keyed by a stable ID), and test rules as plain functions without the UI.
- **Automation specialists** decide where a rule runs: in the app (instant, but only when someone uses the app) or in a flow/plug-in (always runs, also for imports and API writes).
- **MVP practice:** for every automatic record, write down the *precondition* (what must be true in the data) and test the case where the trigger fires but the precondition is false.

## Instructions

### Design approach
1. **Trigger ≠ precondition.** A status change is only the trigger. Before creating "Raise invoice", check the real state: does a non-draft invoice already exist? Is "invoice sent" ticked? Is the project marked not billable?
   **[Field-tested]** An app created "Raise invoice — <project>" when a project moved to *Completed*, checking only whether a task with that title existed. The project had been invoiced weeks before, so the team got a wrong task and message.
2. **One rule module, many callers:**
   ```ts
   // src/rules/projectInvoice.ts — no UI imports
   export const realInvoices = (p: ProjectLike) =>
     [...(p.invoices ?? []), ...(p.purchaseOrders ?? []).flatMap(po => po.invoices ?? [])]
       .filter(i => i && i.status !== 'Draft' && i.status !== 'Cancelled');
   export function invoiceState(p: ProjectLike): 'Paid' | 'Invoiced' | 'Not invoiced' {
     const inv = realInvoices(p);
     if (!inv.length) return /paid/i.test(p.invoiceStatus ?? '') ? 'Paid'
       : p.invoiceSent || /^invoiced|sent/i.test(p.invoiceStatus ?? '') ? 'Invoiced' : 'Not invoiced';
     return inv.every(i => i.status === 'Paid') ? 'Paid' : 'Invoiced';
   }
   export const notBillable = (p: ProjectLike) => /^\s*(n\/?a|not billable)/i.test(p.invoiceStatus ?? '');
   export const needsInvoiceTask = (p: ProjectLike) => invoiceState(p) === 'Not invoiced' && !notBillable(p);
   ```
   The invoice tracker page, the project chips and the automation all import `invoiceState` / `needsInvoiceTask`.
3. **Idempotency by stable key, not by display text.** Find an existing automatic record by a key that can't change: an alternate key, a lookup to the parent, or a hidden label such as `proj:<guid>`. **Titles change when records are renamed** — a title check creates a second record.
4. **Where should it run?** If the record must exist even when nobody opens the app (imports, API updates, other apps), put the rule in a **flow or plug-in** and keep the app's copy for instant feedback only. Use the same logic in both, and test both.
5. **Reversibility.** If the trigger is undone (status moved back), decide whether the automatic record is closed, left, or reopened — and code that explicitly.

### Development standards
- **Pure functions** for rules, dates and calculations (`periodsFor(today)`, `targetHours(...)`, `sortTasks(...)`), no React or SDK imports, so they run in Vitest in milliseconds.
- **Tests per rule:** the normal case, the precondition-false case, the duplicate case, the renamed case, and break inputs (null, empty, `NaN`, invalid date, names with apostrophes, extra spaces, a name that is part of another name).
- **Dates:** weeks start on a fixed day (state it), "today" is the user's local day, and long-lived screens recompute "today" (`const today = todayIso(); useMemo(() => periodsFor(today), [today])`) so a page left open overnight moves to the new day. Test Monday, Sunday, the 1st of the month, month starting mid-week, bank holidays.
- **No "completed on" column = approximate dates.** If "done today" uses `modifiedon`, editing an old completed record today counts it again. If it matters, add a real completion date column set when the status changes.
- **Stress test** pure calculations with realistic volume (e.g. 50 people × 20,000 time entries) and assert a time budget.

**Player-specific UI checks** (the app runs in an iframe inside the Power Apps player):
- **Stacking:** use one z-index scale for all overlays (e.g. drawer 4000, modal 5000, toast 6000). **[Field-tested]** A "log time" pop-up opened *behind* the task window because each component chose its own z-index.
- **Images from local files:** **[Field-tested]** `blob:` URLs were blocked in the player; preview pasted/uploaded images with `data:` URLs (`FileReader.readAsDataURL`).
- **Browser storage** can be unavailable (private mode, blocked site data): wrap `localStorage` in `try/catch`; use it only for preferences (last tab), never for business data.
- **Deep links:** read query parameters through the host context (`getContext()` from `@microsoft/power-apps/app`, `app.queryParams`), not `window.location`, because the app runs in a frame.
- **Native date inputs:** act on blur, not on every keystroke.
- **Accessibility:** minimum font size (we use 11px), contrast ≥ 4.5:1 in light and dark themes.

### Governance
- Every automatic record or message is a **change in behaviour for the business**: list it in release notes ("from v1.4.x the app creates…") and get the process owner's agreement.
- Messages created by automation (Teams/email) must have a test mode that sends only to the tester (see `power-automate-dataverse-triggered-flows`).

### Security
- An automatic record runs with the **current user's privileges**. If the user lacks Create on the target table, the automation fails for them — handle and report it; don't assume admin rights.
- Never decide permissions in the rule module alone; Dataverse roles enforce (see `dataverse-security-roles-for-code-apps`).

### Performance
- Before creating, query for the existing record with a narrow filter (`$select` the ID only, `$top` not needed for an existence check of one key).
- Don't run rule checks in render loops; run them on the change event.

### ALM
- Rules and their tests live in Git next to the code. Tests run before every build (`npm test && npm run build`).
- When a rule changes, add the bug that motivated it as a named test (e.g. `it('no invoice task when an invoice is already sent')`).

### Licensing
- No extra licence for in-app rules. Moving a rule into a flow consumes **Power Platform requests** from the flow owner's (or Process licence's) entitlement **[Microsoft]**.

## Examples

### Beginner — test a pure rule with Vitest
```ts
import { describe, it, expect } from 'vitest';
import { needsInvoiceTask } from './projectInvoice';
describe('needsInvoiceTask', () => {
  it('true when nothing invoiced', () => expect(needsInvoiceTask({})).toBe(true));
  it('false when an invoice is sent', () => expect(needsInvoiceTask({ invoices: [{ status: 'Sent' }] })).toBe(false));
  it('drafts and cancelled do not count', () => expect(needsInvoiceTask({ invoices: [{ status: 'Draft' }, { status: 'Cancelled' }] })).toBe(true));
  it('invoice under a purchase order counts', () => expect(needsInvoiceTask({ purchaseOrders: [{ invoices: [{ status: 'Paid' }] }] })).toBe(false));
  it('not billable', () => expect(needsInvoiceTask({ invoiceStatus: 'N/A' })).toBe(false));
});
```

### Intermediate — idempotent automatic task keyed by the parent ID
```ts
async function ensureInvoiceTask(project: Project) {
  if (!needsInvoiceTask(project)) return;                         // precondition, not just the trigger
  const key = `proj:${project.id}`;
  const existing = await listAll<{ cr123_taskid: string }>('cr123_tasks', {
    select: ['cr123_taskid'],
    filter: `startswith(cr123_title,'Raise invoice') and contains(cr123_labels,${odataString(key)}) and statecode eq 0`,
  }, 1);
  if (existing.length) return;                                    // rename-proof
  await client.createRecordAsync('cr123_tasks', { cr123_title: `Raise invoice — ${project.name}`, cr123_labels: key, /* … */ });
}
```

### Advanced (enterprise) — check a rule against production data without changing anything
Before releasing a rule change, run the new rule over a **read-only export** of production rows and list what it would do:
1. Export (GET only) the relevant rows to a local JSON file.
2. Run the same rule (port it to a script, or run the TS module with `tsx`) over every row.
3. Report counts: *would create N, would skip M*, and list known incidents (the record that caused the bug must now be skipped).
4. Attach the report to the release notes. No production writes are involved.

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Checking only the trigger (status changed) | Records created when not needed (invoice task for invoiced project) | Check the real precondition in data |
| Duplicate check by title | Rename → second record | Stable key (lookup, alternate key, hidden label) |
| Same rule copied into several screens | Screens disagree | One pure module imported everywhere |
| Rule only in the app | Imports/API updates skip it | Flow or plug-in for must-happen rules |
| `modifiedon` as "completed on" | Old items counted as done today | Real completion date column |
| "Today" computed once at page load | Wrong numbers after midnight | Recompute today; memo on it |
| Each component picks its own z-index | Pop-up hidden behind a window | One overlay scale |
| `blob:` image previews | Blank images in the player | `data:` URLs |
| Untested edge inputs | Crash on `NaN`, bad dates, apostrophes | Break tests for every rule |

## Validation checklist

### Security
- [ ] Automatic records work for a user with only the intended role (not admin)
- [ ] No permission decided only in client code

### Performance
- [ ] Existence checks select only the ID
- [ ] Stress test for heavy calculations passes within budget

### ALM
- [ ] Every rule has tests incl. precondition-false, duplicate, rename, break inputs
- [ ] The bug that motivated a change is a named test
- [ ] `npm test` runs before every build

### Solution packaging
- [ ] Any new column a rule depends on (e.g. completion date, label) is in the solution
- [ ] If the rule also runs in a flow, the flow is in the same solution

### Deployment readiness
- [ ] Rule run over read-only production data; result attached to release notes
- [ ] Manual player test done: overlays, date inputs, images, deep link
- [ ] Release notes state any new automatic record or message

## Troubleshooting
| Symptom | Likely cause | Fix |
|---|---|---|
| Automatic record created at the wrong time | Rule checks the trigger (status changed) but not the precondition | Separate trigger and precondition; unit test the precondition-false case |
| Duplicates after a rename | Duplicate check matched the title | Match a stable key (label `proj:<id>`, alternate key) |
| Pop-up opens behind another window | Components chose their own z-index | One z-index scale in shared tokens |
| Dates saved as year 0002 | Linked date logic ran on each keystroke | Run linked logic on blur; reject half-typed dates on save |
| Image preview blank in the player only | `blob:` URLs blocked by CSP | Use `data:` URLs |
| Deep link opens the home page | Read `window.location` inside the player iframe | `getContext().app.queryParams` |
| "Today" numbers stale next morning | Today computed once on load | Recompute on focus / interval |

Not sure which product applies? Start with the `power-platform-solution-builder` hub skill.

## References
- [Microsoft] [Code apps overview](https://learn.microsoft.com/power-apps/developer/code-apps/overview)
- [Microsoft] [Define alternate keys for a table](https://learn.microsoft.com/power-apps/maker/data-platform/define-alternate-keys-portal)
- [Vitest](https://vitest.dev/)
