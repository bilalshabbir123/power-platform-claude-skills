---
name: power-apps-canvas-app-delegation-performance
description: Build canvas apps (Power Fx) that return complete results and load fast — delegation rules for Dataverse and SharePoint, the data row limit (500 default, maximum 10,000), CountRows vs CountIf, named formulas, Concurrent, Patch error handling, double-submit guards, and when to choose a canvas app or a code app. Use when a gallery shows fewer records than expected, there is a yellow delegation warning or blue underline, a canvas app is slow to start, a Patch silently fails, or someone asks canvas vs code app.
---

# Canvas apps: delegation, performance and safe saves

## Purpose
- **What it does:** stops canvas apps silently returning incomplete data, makes them start fast, and makes every save show success or a clear error.
- **When to use it:** delegation warnings, "missing records", slow `OnStart`, bulk updates, choosing canvas vs code app.
- **Expected outcome:** delegable queries on Dataverse, correct counts, light start-up, and saves that never fail silently.

## Expertise
- **Architects** pick canvas for maker-maintained apps with many connectors, and a code app when pro developers need TypeScript, tests and npm libraries.
- **Developers** treat every delegation warning as a bug on any table that can grow past the data row limit.
- **MVP practice:** the data row limit is **500 by default and can be raised to 10,000** **[Microsoft]** (older guidance said 2,000 — that is out of date). Raising it never fixes a non-delegable query; it only moves where results go wrong.

## Instructions

### Choosing canvas or code app
| Choose canvas when | Choose a code app when |
|---|---|
| Makers will maintain it | Pro developers will maintain it |
| Standard screens, forms, galleries | Complex UI, custom components, heavy client logic |
| Many connectors, little custom code | You want TypeScript, unit tests, npm libraries (e.g. React Bits) |
| Offline on mobile is needed | Desktop / browser first |

### Design approach
1. **Dataverse first.** It has the widest delegation support. SharePoint lists work for simple, small lists but delegate fewer functions **[Microsoft]**.
2. **Delegation is the #1 correctness issue.** A non-delegable query only processes the first **data row limit** rows: **500 by default, maximum 10,000** (Settings → General) **[Microsoft]**. Above that, results are silently incomplete. A blue underline / yellow triangle in Studio is the warning.
   - Delegable on Dataverse: `Filter`, `Search`, `LookUp`, `Sort`, `SortByColumns`, comparisons including `= Blank()`, `StartsWith`, `in` (subject to the 15-table query limit) **[Microsoft]**.
   - Not delegable: `FirstN`, `Len`/`Mid` in filters, most text functions inside a filter **[Microsoft]**.
   - `CountRows(table)` on Dataverse returns a **cached** count; for an exact count under 50,000 use `CountIf(table, true)` **[Microsoft]**.
   - `UpdateIf` / `RemoveIf` work locally up to the data row limit **[Microsoft]** — use a flow or `Patch` over a filtered, delegable set for bulk changes.
3. **Start fast:** keep `App.OnStart` light. Use **named formulas** (`App.Formulas`) for values computed on demand, `App.StartScreen` for routing, and `Concurrent()` for independent loads.
4. **Reuse:** component libraries for shared headers/controls; user-defined functions for shared logic.
5. **Explicit column selection** (on by default for new apps) keeps payloads small **[Microsoft]**.

### Development standards
- Naming: controls `scrHome`, `galProjects`, `btnSave`, `txtSearch`; variables `gblUser` (global), `locIsSaving` (context), collections `colCart`.
- Save pattern: `Patch` → check `IsError` / `Errors()` → `Notify` success or the error, never silent.
  ```powerfx
  Set(locIsSaving, true);
  IfError(
      Patch(Projects, galProjects.Selected, { Name: txtName.Text }),
      Notify("Couldn't save: " & FirstError.Message, NotificationType.Error),
      Notify("Saved", NotificationType.Success)
  );
  Set(locIsSaving, false)
  ```
  Disable the save button while `locIsSaving` to stop double submits.
- Formulas as source: canvas apps can be stored as **Power Apps source files (`.pa.yaml`)** and reviewed in Git **[Microsoft]**.
- Accessibility: `AccessibleLabel` on every interactive control, tab order, colour contrast 4.5:1. Run **App checker**.

### Governance and DLP
- Premium connectors (Dataverse, HTTP, custom) make the app premium **[Microsoft]**.
- DLP groups (Business / Non-business / Blocked) decide which connectors can be combined in one app.
- Share with security groups; sharing doesn't grant data access — roles do.

### Security
- Hiding a button is not security. Dataverse roles and column security are.
- Don't store secrets in variables or in the app; use connections.

### Performance
- Use **Monitor** to see every network call and its duration.
- Avoid `ForAll(… Patch …)` over large sets (one call per row); use `Patch(table, collectionOfChanges)` or a flow.
- Load galleries directly from a delegable query (paged in batches of 100) instead of collecting everything first **[Microsoft]**.

### ALM
- Build inside a solution from day one; env vars and connection references for every connector.
- Promote as a managed solution → `power-platform-solution-release-alm`.

### Licensing
- Dataverse, HTTP and custom connectors make the app premium (Power Apps Premium / per-app / pay-as-you-go) **[Microsoft]**.

## Examples

### Beginner — fix a non-delegable search
`Filter(Projects, Len(Name) > 3)` → add a Whole number formula column `cr123_namelength = Len(Name)` and use `Filter(Projects, cr123_namelength > 3)`; confirm the warning is gone and test with more rows than the data row limit.

### Intermediate — exact totals
Replace `CountRows(Filter(Tickets, Status = "Open"))` shown as an exact KPI with `CountIf(Tickets, Status = "Open")` (≤ 50,000 rows) and document the limit.

### Advanced (enterprise) — fast start and bulk change
Move `OnStart` collections to named formulas, use `App.StartScreen`, load independent lookups with `Concurrent()`, and move a 20,000-row status change from `ForAll(Patch)` to a Power Automate flow with paging.


## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Ignoring delegation warnings | Missing records past 500 / 10,000 | Delegable functions on Dataverse; test with more rows than the limit |
| Raising the data row limit to "fix" delegation | Slower app, still wrong above the limit | Fix the query |
| Heavy `OnStart` | Slow start | Named formulas, `StartScreen`, `Concurrent` |
| `CountRows` for exact totals | Stale number | `CountIf(table, true)` (≤ 50,000) |
| No error handling on `Patch` | Users think it saved | `IfError` + `Notify` |

## Validation checklist
### Security
- [ ] Data access enforced by Dataverse roles, not hidden controls
### Performance
- [ ] No delegation warnings on tables that can exceed the data row limit
- [ ] `OnStart` light; Monitor shows no unnecessary calls
### ALM
- [ ] App in a solution; connection references and env vars used
### Solution packaging
- [ ] Source stored as `.pa.yaml` / Git where enabled
### Deployment readiness
- [ ] Tested with more rows than the data row limit
- [ ] Every Patch path shows success or an error

## References
- [Microsoft] [Delegation overview](https://learn.microsoft.com/power-apps/maker/canvas-apps/delegation-overview)
- [Microsoft] [Dataverse delegable functions](https://learn.microsoft.com/power-apps/maker/canvas-apps/connections/connection-common-data-service#power-apps-delegable-functions-and-operations-for-dataverse)
- [Microsoft] [Small data payloads](https://learn.microsoft.com/power-apps/maker/canvas-apps/small-data-payloads)
- [Microsoft] [Count functions](https://learn.microsoft.com/power-platform/power-fx/reference/function-table-counts)
