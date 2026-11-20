# Power Apps code apps (React + Vite on Power Platform)

Read this when the request is a code app. For the deep detail, hand over to the focused skills listed at the end.

## What a code app is
- A React (or other SPA) project built with Vite and published into a Power Platform environment. It runs inside the Power Apps player, uses Power Platform sign-in, sharing, DLP and Conditional Access, and calls data through **connectors** (Dataverse, SharePoint, Office 365, custom connectors) via the generated client **[Microsoft]**.
- Users need **Power Apps Premium** (or pay-as-you-go / per-app) **[Microsoft]**.

## Project setup (current CLI)
```bash
npm create vite@latest contoso-app -- --template react-ts
cd contoso-app && npm install
npm install @microsoft/power-apps          # SDK + CLI
npx power-apps init                        # or: pa app init (newer CLI generation)
npx power-apps add-data-source --api-id dataverse --resource-name cr123_project --org-url https://<org>.crm.dynamics.com/
npm run build && npx power-apps push       # or: pa app push --solution-id <solution>
```
The CLI has changed generations (`pac code …` → `power-apps …` → `pa app …`). Check `--help` of the installed version; see `power-apps-code-app-deployment` for the version table and the publish order.

## The rules that differ from a normal React app
| Area | Code app rule | Why |
|---|---|---|
| Network | No direct `fetch` to external hosts; use a connector | CSP `connect-src 'none'` by default **[Microsoft]** |
| Images | `data:` URLs or bundled files; `blob:` URLs are blocked | CSP `img-src 'self' data:` **[Microsoft]**, seen in the player **[Field-tested]** |
| Fonts | Bundle fonts locally; Google Fonts CDN is blocked | CSP `font-src 'self'` **[Microsoft]** |
| Web workers | Blocked unless an admin sets `worker-src` | CSP `worker-src 'none'` **[Microsoft]** |
| Embedding | Only Power Apps can frame the app unless `frame-ancestors` is extended | **[Microsoft]** |
| Query string | Read deep links with `getContext().app.queryParams`, not `window.location` | The app runs in an iframe **[Field-tested]** |
| Storage | Wrap `localStorage` in try/catch | Can be unavailable in the player **[Field-tested]** |
| Secrets | None in the bundle | Built assets are served from a public endpoint **[Microsoft]** |
| File upload | The SharePoint/OneDrive connector clients couldn't upload file content from the app; send the file to an instant flow (Power Apps V2 trigger with a File input) that creates it in the library, and keep files small (we cap at 25 MB) | **[Field-tested]** |
| Lookups | Lowercase SchemaName for lookup columns, or binds fail with `0x80048d19` | **[Field-tested]**, `power-apps-code-app-dataverse-data-access` |
| Local dev | `npm run dev` has no data bridge; real data only in the player | **[Field-tested]** |
| Paging | Follow `skipToken`; default page size is 500; never rely on `$top` for "all" | **[Field-tested]**, `power-apps-code-app-dataverse-data-access` |

CSP is set per environment by an admin (Power Platform admin center → Environment → Settings → Product → Privacy + Security → Content security policy → App), or with the `PowerApps_CSPConfigCodeApps` setting via the Power Platform API. Custom values merge with defaults; for a `'none'` default they replace it **[Microsoft]**. Roll out CSP changes in report-only mode first.

## Recommended structure
```
src/
  services/       # data access: paging, retries, escaping (one place)
  rules/          # pure business rules + unit tests (no React, no SDK)
  components/     # UI; heavy visuals lazy-loaded
  generated/      # CLI-generated clients — never hand-edit
```

## Hand over to
- Publishing, CLI, accounts, OneDrive pitfalls → `power-apps-code-app-deployment`
- Reading / writing Dataverse safely → `power-apps-code-app-dataverse-data-access`
- Business rules, duplicates, player-only bugs, tests → `power-apps-code-app-business-rules-testing`
- Roles and permissions → `dataverse-security-roles-for-code-apps`
- Animated UI → `react-bits-animated-ui`
- Release to production → `power-platform-solution-release-alm`

## References
- [Microsoft] [Code apps overview](https://learn.microsoft.com/power-apps/developer/code-apps/overview)
- [Microsoft] [Code apps CSP](https://learn.microsoft.com/power-apps/developer/code-apps/how-to/content-security-policy)
