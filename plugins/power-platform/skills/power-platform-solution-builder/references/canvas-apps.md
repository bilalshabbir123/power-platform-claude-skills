# Canvas apps — summary

Full detail: skill **`power-apps-canvas-app-delegation-performance`**.

- Canvas for maker-maintained apps with many connectors; code app for pro developers needing TypeScript, tests and npm libraries.
- Dataverse first (widest delegation). Non-delegable queries process only the **data row limit: 500 by default, maximum 10,000** **[Microsoft]**. Fix the query; don't just raise the limit.
- `CountRows(table)` on Dataverse is a cached count; exact counts with `CountIf(table, true)` up to 50,000 **[Microsoft]**.
- Light `OnStart`: named formulas, `App.StartScreen`, `Concurrent()`.
- Every `Patch` wrapped in `IfError` + `Notify`; disable the button while saving.
