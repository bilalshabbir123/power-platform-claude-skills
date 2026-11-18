---
name: sharepoint-spfx-web-parts
description: Build, upgrade, secure and release SharePoint Framework (SPFx) web parts and extensions with React — Heft toolchain (SPFx 1.22+), Node version choice, PnPjs / Microsoft Graph / AadHttpClient data access, calling Dataverse or Power Automate from SharePoint, throttling, app catalog deployment and CI. Use when someone asks to create or fix an SPFx web part, upgrade an old gulp-based SPFx project, put a React UI on a SharePoint page / Teams tab / Viva Connections card, or show Power Platform data inside SharePoint.
---

# SharePoint Framework (SPFx) web parts and extensions

## Purpose
- **What it does:** a repeatable way to build SPFx solutions on the current toolchain, call SharePoint, Graph, your APIs and Dataverse safely, and release `.sppkg` packages through CI and the app catalog.
- **When to use it:** new web parts, list command sets, application customizers, Teams tabs, Viva ACEs; upgrading SPFx versions; showing Power Platform data on SharePoint pages.
- **Expected outcome:** builds that work on the right Node version, least-privilege API permissions, throttling-safe data access and reproducible releases.

## Expertise
- **Architects** use SPFx only when the UI must live *inside* SharePoint/Teams/Viva; standalone business apps on Dataverse are simpler as code apps or canvas apps.
- **Developers** pin the Node version per project, keep services out of components, and test services.
- **Admins/MVPs** approve packages and API permissions in the tenant app catalog and review them like code — an approved Graph permission is tenant-wide.

## Instructions

### Design approach
1. One web part = one job. Settings (list, number of items, colours) go in the **property pane**, not code.
2. Pick the data path:
   | Data | Use |
   |---|---|
   | SharePoint lists/libraries | PnPjs (`@pnp/sp`) or `SPHttpClient` |
   | Microsoft Graph (users, Teams, mail) | `MSGraphClientV3` |
   | Your API / Azure Function | `AadHttpClient` + Entra ID app; `webApiPermissionRequests` in `package-solution.json`, approved by an admin |
   | Dataverse | Prefer a Power Automate flow or Dataverse custom API behind your API so rules stay server-side; direct calls via `AadHttpClient` to the Dataverse Web API with delegated permission work but put logic in the browser |
3. UI: Fluent UI React to match SharePoint; read theme from the page. Animated effects only when they help (see the `react-bits-animated-ui` skill for reduced motion and bundle size).

### Development standards
- **Toolchain:** SPFx **1.22+ uses Heft**; gulp was used up to 1.21.1 **[Microsoft]**. Don't follow gulp guides on a Heft project.
- **Node:** for SPFx **1.24**, Node.js **26 LTS** is recommended; 22 (22.14.0+) and 24 are supported **[Microsoft]**. Older projects use their own compatibility row. Use nvm/fnm and an `.nvmrc` per project.
- Install: `npm install @microsoft/generator-sharepoint@latest --global` **[Microsoft]**.
- Upgrade report (community tool, no Microsoft SLA) **[Microsoft]**:
  ```bash
  npx -p @pnp/cli-microsoft365@latest m365 spfx project upgrade --toVersion <version> --output md
  ```
- TypeScript strict; a `services/` layer with unit tests; components only render.
- Handle **429**: honour `Retry-After`, batch with `$batch`, `$select` only needed columns, cache read-mostly data.

### Governance and DLP
- `.sppkg` is deployed through the **tenant** (or site collection) **app catalog** by an admin.
- `skipFeatureDeployment: true` makes the web part available on every site — decide on purpose.
- API permission requests become tenant-wide once approved: request the least privilege and document why.
- If the web part calls Power Platform (flows, custom connectors), Power Platform DLP and licensing still apply.

### Security
- SPFx runs as the **current user** inside the page. Never embed secrets or keys; the bundle is downloadable.
- Use **domain-isolated** web parts (`isDomainIsolated`) when calling APIs with powerful permissions.
- Sanitize any HTML you render from list data (no `dangerouslySetInnerHTML` on user content).

### Performance
- Keep bundles small: check the bundle analysis Heft/webpack produces; lazy-load heavy components with dynamic `import()`.
- Avoid one request per item; use `$batch` or a single filtered query.
- Large lists: filter on indexed columns (the 5,000-item list view threshold applies to unindexed queries).

### ALM
- Git + CI (GitHub Actions / Azure DevOps) builds and packages; bump `version` in `package-solution.json` every release.
- Deploy with CLI for Microsoft 365 or PnP PowerShell to a TEST site/tenant, then production.
- Keep the previous `.sppkg` for rollback.

### Licensing
- SPFx is included with SharePoint Online. Calls into Power Platform (flows, Dataverse, custom connectors) follow Power Platform licensing.

## Examples

### Beginner — list items web part
Scaffold with the generator (React template), read `cr123_Announcements` with PnPjs, list name in the property pane, Fluent UI `DetailsList`.

### Intermediate — show Dataverse data on a SharePoint page
Azure Function (Entra ID protected) queries Dataverse with a managed identity app user → web part calls it with `AadHttpClient` → admin approves the single permission request. Business rules stay in the Function.

### Advanced (enterprise) — upgrade and CI
Run the CLI upgrade report from 1.21.1 → current, migrate gulp customisations to Heft config, add `.nvmrc`, build `.sppkg` in GitHub Actions, deploy to the TEST app catalog automatically and to production after approval.

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Wrong Node version | Build fails or odd errors | Compatibility table + `.nvmrc` |
| gulp commands on a Heft project | Commands don't exist | Check SPFx version first |
| Broad Graph permissions | Tenant-wide over-privilege | Least privilege; admin review |
| No throttling handling | Random 429s on busy sites | Retry-After, batching, `$select` |
| `.sppkg` built on a laptop | Unreproducible releases | CI build |
| Business rules in the browser | Bypassed via direct API calls | Server-side (flow, Function, custom API) |

## Validation checklist
### Security
- [ ] No secrets in the bundle; HTML from data sanitized
- [ ] API permissions least-privilege and approved
### Performance
- [ ] Bundle checked; heavy parts lazy-loaded
- [ ] 429 handling and batching in place
### ALM
- [ ] `.nvmrc` + lockfile committed; version bumped
- [ ] CI builds the `.sppkg`
### Solution packaging
- [ ] `package-solution.json` reviewed (`skipFeatureDeployment`, `isDomainIsolated`, permissions)
### Deployment readiness
- [ ] Tested on a TEST site with a non-admin user
- [ ] Previous package kept for rollback

## References
- [Microsoft] [Set up your SPFx development environment](https://learn.microsoft.com/sharepoint/dev/spfx/set-up-your-development-environment)
- [Microsoft] [SPFx Heft toolchain](https://learn.microsoft.com/sharepoint/dev/spfx/toolchain/sharepoint-framework-toolchain-rushstack-heft)
- [Microsoft] [SPFx compatibility reference](https://learn.microsoft.com/sharepoint/dev/spfx/compatibility)
- [Microsoft] [SPFx v1.22 release notes](https://learn.microsoft.com/sharepoint/dev/spfx/release-1.22.0)
