# Custom React apps that use Dataverse or Power Platform

Read this when the app is hosted outside Power Platform (Azure Static Web Apps, App Service, your own site) but reads/writes Dataverse or triggers flows.

## First, check you really need it
| Requirement | Better option |
|---|---|
| Internal users, React UI, Dataverse | **Code app** (sign-in, sharing, DLP, CSP handled for you) |
| External/anonymous users, portal | **Power Pages** (table permissions, web roles) |
| Own domain, own auth, deep integration with other systems | Custom React app (this file) |

## Architecture
```
React (Vite) SPA ──MSAL (delegated)──► Dataverse Web API          (internal users, simple)
React SPA ──► your API (Azure Functions / App Service) ──► Dataverse (app user / managed identity)
                                        └──► Power Automate (HTTP-triggered flow) / custom API
```
- **Delegated (user) access:** register an Entra ID SPA app, MSAL.js (`@azure/msal-browser` / `@azure/msal-react`), scope `https://<org>.crm.dynamics.com/user_impersonation`. Every user still needs a Dataverse security role and a licence.
- **Server access:** a confidential client or **managed identity** registered as a Dataverse **application user** with a least-privilege role. Secrets stay on the server (Key Vault). Use this for external users or when rules must not run in the browser.

## Development standards
- Web API base: `https://<org>.crm.dynamics.com/api/data/v9.2/`; headers `OData-Version: 4.0`, `Accept: application/json`, `Prefer: odata.maxpagesize=500` for paging.
- **Paging:** follow `@odata.nextLink` until it's absent. Don't use `$top` to mean "all" (it caps results).
- **Escaping:** single quotes in OData string literals are doubled (`O'Brien` → `O''Brien`); build filters with a helper, never string-concatenate user input.
- **Writes:** `PATCH /entityset(id)` with `If-Match: *` to update only; lookups via `"cr123_ProjectId@odata.bind": "/cr123_projects(<id>)"`.
- **Throttling:** handle `429` with `Retry-After`; service protection limits are 6,000 requests / 20 minutes execution / 52 concurrent per 5 minutes per user per server **[Microsoft]**. Use `$batch` (max 1,000 operations) for bulk work **[Microsoft]**.
- Same patterns as code apps for read-modify-write, optimistic UI rollback and double-submit guards → `power-apps-code-app-dataverse-data-access`.

## Governance and security
- CORS: Dataverse allows browser calls with a valid token; your own API must restrict origins.
- Conditional Access applies to the Entra ID app; register redirect URIs exactly.
- Content Security Policy on your host: allow only your API and `*.crm*.dynamics.com` in `connect-src`.
- Power Platform DLP does **not** govern a custom app's direct Web API calls — document the data flow for your admin.

## ALM
- Git + CI/CD (GitHub Actions → Azure Static Web Apps / App Service); environment-specific config (org URL, client ID) from build-time env vars, never hard-coded.
- Dataverse schema still ships as a managed solution → `power-platform-solution-release-alm`.

## Licensing
- Users accessing Dataverse need an appropriate Power Apps / Dynamics licence even through a custom app (multiplexing rules) **[Microsoft]** — confirm with Microsoft licensing guidance before design sign-off.

## References
- [Microsoft] [Dataverse Web API overview](https://learn.microsoft.com/power-apps/developer/data-platform/webapi/overview)
- [Microsoft] [Service protection API limits](https://learn.microsoft.com/power-apps/developer/data-platform/api-limits)
- [Microsoft] [Execute batch operations](https://learn.microsoft.com/power-apps/developer/data-platform/webapi/execute-batch-operations-using-web-api)
- [Microsoft] [Multiplexing guidance](https://learn.microsoft.com/power-platform/admin/powerapps-flow-licensing-faq)
