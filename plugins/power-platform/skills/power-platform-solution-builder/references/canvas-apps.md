# Canvas apps (Power Fx)

Read this when the request is a canvas app, or when choosing between canvas and code app.

## Canvas or code app?
| Choose canvas when | Choose a code app when |
|---|---|
| Makers will maintain it | Pro developers will maintain it |
| Standard screens, forms, galleries | Complex UI, custom components, heavy client logic |
| Many connectors, little custom code | You want TypeScript, unit tests, npm libraries (e.g. React Bits) |
| Offline on mobile is needed | Desktop / browser first |

## Design approach
1. **Dataverse first.** It has the widest delegation support. SharePoint lists work for simple, small lists but delegate fewer functions **[Microsoft]**.
2. **Delegation is the #1 correctness issue.** A non-delegable query only processes the first **data row limit** rows: **500 by default, maximum 10,000** (Settings → General) **[Microsoft]**. Above that, results are silently incomplete. A blue underline / yellow triangle in Studio is the warning.
   - Delegable on Dataverse: `Filter`, `Search`, `LookUp`, `Sort`, `SortByColumns`, comparisons including `= Blank()`, `StartsWith`, `in` (subject to the 15-table query limit) **[Microsoft]**.
   - Not delegable: `FirstN`, `Len`/`Mid` in filters, most text functions inside a filter **[Microsoft]**.
   - `CountRows(table)` on Dataverse returns a **cached** count; for an exact count under 50,000 use `CountIf(table, true)` **[Microsoft]**.
   - `UpdateIf` / `RemoveIf` work locally up to the data row limit **[Microsoft]** — use a flow or `Patch` over a filtered, delegable set for bulk changes.
3. **Start fast:** keep `App.OnStart` light. Use **named formulas** (`App.Formulas`) for values computed on demand, `App.StartScreen` for routing, and `Concurrent()` for independent loads.
4. **Reuse:** component libraries for shared headers/controls; user-defined functions for shared logic.
5. **Explicit column selection** (on by default for new apps) keeps payloads small **[Microsoft]**.

## Development standards
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

## Governance and DLP
- Premium connectors (Dataverse, HTTP, custom) make the app premium **[Microsoft]**.
- DLP groups (Business / Non-business / Blocked) decide which connectors can be combined in one app.
- Share with security groups; sharing doesn't grant data access — roles do.

## Security
- Hiding a button is not security. Dataverse roles and column security are.
- Don't store secrets in variables or in the app; use connections.

## Performance
- Use **Monitor** to see every network call and its duration.
- Avoid `ForAll(… Patch …)` over large sets (one call per row); use `Patch(table, collectionOfChanges)` or a flow.
- Load galleries directly from a delegable query (paged in batches of 100) instead of collecting everything first **[Microsoft]**.

## ALM
- Build inside a solution from day one; env vars and connection references for every connector.
- Promote as a managed solution → `power-platform-solution-release-alm`.

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Ignoring delegation warnings | Missing records past 500 / 10,000 | Delegable functions on Dataverse; test with more rows than the limit |
| Raising the data row limit to "fix" delegation | Slower app, still wrong above the limit | Fix the query |
| Heavy `OnStart` | Slow start | Named formulas, `StartScreen`, `Concurrent` |
| `CountRows` for exact totals | Stale number | `CountIf(table, true)` (≤ 50,000) |
| No error handling on `Patch` | Users think it saved | `IfError` + `Notify` |

## References
- [Microsoft] [Delegation overview](https://learn.microsoft.com/power-apps/maker/canvas-apps/delegation-overview)
- [Microsoft] [Dataverse delegable functions](https://learn.microsoft.com/power-apps/maker/canvas-apps/connections/connection-common-data-service#power-apps-delegable-functions-and-operations-for-dataverse)
- [Microsoft] [Small data payloads](https://learn.microsoft.com/power-apps/maker/canvas-apps/small-data-payloads)
- [Microsoft] [Count functions](https://learn.microsoft.com/power-platform/power-fx/reference/function-table-counts)
