# SharePoint Framework (SPFx) — summary

Read this when the UI must live inside SharePoint pages, Teams tabs or Viva Connections. Full detail: skill **`sharepoint-spfx-web-parts`** (plugin `sharepoint`).

- Use SPFx only when the UI must sit *inside* SharePoint/Teams/Viva; standalone Dataverse apps are simpler as code or canvas apps.
- SPFx **1.22+ uses Heft** (gulp up to 1.21.1). SPFx 1.24: Node.js 26 LTS recommended, 22 (22.14.0+) and 24 supported **[Microsoft]**.
- Data: PnPjs / `SPHttpClient` for SharePoint, `MSGraphClientV3` for Graph, `AadHttpClient` for your API; keep Dataverse business rules server-side (flow, Function, custom API).
- Runs as the current user; no secrets in the bundle; least-privilege API permissions approved in the app catalog.
- Handle 429 with `Retry-After`; batch; `$select`.
- `.sppkg` built in CI, version bumped every release.
