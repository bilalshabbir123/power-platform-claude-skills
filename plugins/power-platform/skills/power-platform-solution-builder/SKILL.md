---
name: power-platform-solution-builder
description: One entry point for building on Microsoft Power Platform and Microsoft 365 — Power Apps code apps (React + Vite), canvas apps (Power Fx), Power Automate cloud flows, SharePoint Framework (SPFx) web parts, custom React apps that call Dataverse or Power Platform, React UI animation with React Bits, and calling a self-hosted fine-tuned LLM (Unsloth) from Power Platform. Use it whenever someone asks to build, choose between, fix, test, secure, or release any of these ("should this be a canvas app or code app", "build an SPFx web part", "call Dataverse from my React app", "add animations to my code app", "use my fine-tuned model in a flow"), even if they don't name a product. It picks the right technology, loads only the matching reference file, and hands over to the focused skills in this repo.
---

# Power Platform solution builder (hub skill)

## Purpose
- **What it does:** one skill that covers code apps, canvas apps, Power Automate, SharePoint SPFx, custom React apps, React Bits UI and custom LLMs. It does this **without loading everything at once**: this file decides *which* technology fits and then reads only the matching file in `references/`, plus the focused skills for the deep detail.
- **When to use it:** at the start of any Power Platform / Microsoft 365 build, when choosing a technology, or when a request spans several products (for example "a code app with a flow that emails a summary from our own model").
- **Expected outcome:** the right technology for the job, the same standards everywhere (solutions, environment variables, connection references, Dataverse-first, least privilege, tested before "ready"), and no mixing of rules between products (for example canvas delegation rules applied to a code app).

## Expertise
- **Solution architects** choose the *least custom* option that meets the need: model-driven or canvas before code app; code app before a fully custom app; built-in AI (AI Builder prompts, Copilot Studio) before a self-hosted model.
- **Developers** keep one standard across products: TypeScript, source control, automated tests, one module per business rule, no secrets in client code.
- **Automation specialists** treat every flow as production code: solution-aware, connection references owned by a service account, concurrency control, test-recipient switch.
- **MVP practice:** read the platform's real limits (page size, data row limit, CSP, timeouts) instead of assuming them, and label every claim as **[Microsoft]** (linked) or **[Field-tested]**.

## Instructions

### Step 1 — choose the technology
| Need | Choose | Read |
|---|---|---|
| Forms and views over Dataverse, little custom UI | Model-driven app | (Microsoft docs; not covered here) |
| Low-code app for makers, Power Fx, many connectors | **Canvas app** | `references/canvas-apps.md` → skill `power-apps-canvas-app-delegation-performance` |
| Pro-code React UI, full control, still governed by Power Platform (sharing, DLP, Conditional Access, Dataverse) | **Power Apps code app** | `references/code-apps.md` |
| A UI that lives *inside* SharePoint pages, Teams tabs or Viva | **SPFx web part / extension** | `references/sharepoint-spfx.md` |
| Public site or external users | Power Pages (not covered here) or a custom app | `references/custom-react-apps.md` |
| An app outside Power Platform (own hosting, own auth) that reads/writes Dataverse | **Custom React app** | `references/custom-react-apps.md` |
| Background work: triggers, approvals, emails, Teams, schedules | **Power Automate cloud flow** | `references/power-automate.md` |
| Animated UI (text effects, backgrounds, micro-interactions) in any React app | **React Bits** | `references/react-bits-ui.md` → skill `react-bits-animated-ui` |
| A model fine-tuned on your own data, called from a flow or app | **Unsloth + OpenAI-compatible endpoint + custom connector** | `references/custom-llm-unsloth.md` → skill `unsloth-custom-llm-for-power-platform` |

Read **only** the reference files for the products in the request. Each reference says when to hand over to a focused skill.

### Step 2 — apply the shared standards (every product)
1. **Solutions:** everything lives in one solution (or a few with clear dependencies). Unmanaged in DEV, **managed** in TEST and PROD. → `power-platform-solution-release-alm`.
2. **Environment variables** for anything that differs per environment (URLs, recipients, IDs, feature switches). Ship definitions, **not values**.
3. **Connection references** for every connector, bound per environment to service-account connections.
4. **Dataverse-first** for business data: relational, secured by roles, delegable, auditable. SharePoint lists only for documents or simple lists.
5. **Naming:** one publisher prefix (`cr123_`), tables singular (`cr123_project`), flows `<App> - <Trigger> - <Action>`, env vars `cr123_<App><Purpose>`.
6. **Security:** least-privilege Dataverse roles; client-side checks are UX only. → `dataverse-security-roles-for-code-apps`.
7. **Secrets:** never in client bundles (code apps, SPFx and React bundles are downloadable). Use connections, Azure Key Vault–backed env vars, or a server.
8. **Error handling:** every write shows success or a clear error; flows use Try/Catch scopes with a failure notification to a test recipient.
9. **Testing:** "ready" means every changed path was run and read back. Untested items are blockers. → `power-apps-code-app-business-rules-testing`.
10. **Governance and DLP:** check DLP policies for every connector (including HTTP and custom connectors) in each target environment before building.

### Step 3 — licensing check before you build
| Product | Users need (verify on Microsoft Learn before buying) |
|---|---|
| Canvas app with standard connectors only | Microsoft 365 licence that includes Power Apps for M365 |
| Canvas app with Dataverse or premium/custom connectors | Power Apps Premium / per-app / pay-as-you-go **[Microsoft]** |
| Code app | Power Apps Premium (code apps are premium) **[Microsoft]** |
| Cloud flow with premium connectors (Dataverse, HTTP, custom) | Power Automate Premium, or covered by the app's licence context; Process licence for heavy unattended flows **[Microsoft]** |
| SPFx | Included with SharePoint Online; any Power Platform calls it makes follow Power Platform licensing |
| Custom React app calling Dataverse | Each user still needs a Dataverse-entitled licence; service-to-service app users have their own rules **[Microsoft]** |
| Self-hosted LLM | No Power Platform licence for the model, but the custom connector / HTTP action is premium; plus hosting (GPU) cost |

### Governance and DLP
- Custom connectors and the HTTP connector are commonly **Blocked** or **Non-business** in tenant DLP. Check first; ask the admin for a URL-pattern rule for your custom connector host **[Microsoft]**.
- Code app sharing and DLP follow canvas app rules **[Microsoft]**.
- SPFx packages are approved in the tenant (or site) app catalog; API permissions requested by SPFx need admin approval.

### Security
- Code apps and SPFx bundles are public static files: no secrets, no tokens, no internal URLs that grant access by themselves.
- Code apps enforce a **Content Security Policy** by default (`connect-src 'none'`, `script-src 'self'`, `img-src 'self' data:`, `worker-src 'none'`); external calls go through connectors **[Microsoft]**.
- A custom React app must use Entra ID (MSAL) with delegated permissions or a confidential server; never a client secret in the browser.

### Performance
| Product | The limit that bites | Where it's covered |
|---|---|---|
| Code app | Data client default page size 500; Dataverse service protection 6,000 requests / 5 min / user | `power-apps-code-app-dataverse-data-access` |
| Canvas app | Non-delegable query returns only the **data row limit** (500 default, max 10,000) **[Microsoft]** | `references/canvas-apps.md` |
| Power Automate | 120 s synchronous outbound request timeout; 100,000 actions / 5 min burst **[Microsoft]** | `references/power-automate.md` |
| SPFx | Bundle size and SharePoint REST throttling (429 + Retry-After) | `references/sharepoint-spfx.md` |
| React Bits | WebGL backgrounds (three / ogl) add large chunks and GPU load | `react-bits-animated-ui` |
| Custom LLM | Generation time vs the 120 s timeout | `unsloth-custom-llm-for-power-platform` |

### ALM
- Code apps: Git for source (no Power Platform Git integration for code apps **[Microsoft]**), published into a solution.
- Canvas apps: solution-aware; source with Power Apps source files (`.pa.yaml`) or Git integration where enabled.
- SPFx: Git + `.sppkg` artefact from CI, deployed to the app catalog per environment (tenant).
- Custom connectors: import them in a **separate solution first**, before the solution with flows and connection references **[Microsoft]**.

### Licensing
See the Step 3 table. A design that users can't open because of licensing is not deployable.

## Examples

### Beginner — "Build a leave request app"
Canvas app on Dataverse table `cr123_leaverequest`, one approval flow, one solution. Read `references/canvas-apps.md` and `references/power-automate.md`.

### Intermediate — "Rebuild our project tracker as a modern React app inside Power Apps"
Code app (`references/code-apps.md`) → focused skills: deployment, Dataverse data access, business rules testing, security roles. Animated dashboard header with React Bits Split Text, respecting reduced motion (`react-bits-animated-ui`).

### Advanced (enterprise) — "Classify support emails with our own model and show results in SharePoint"
Mailbox-triggered flow (`power-automate-dataverse-triggered-flows`) → custom connector to an Azure-hosted vLLM endpoint serving an Unsloth fine-tuned model (`unsloth-custom-llm-for-power-platform`) → writes `cr123_category` to Dataverse → SPFx web part shows the queue on the support SharePoint site (`references/sharepoint-spfx.md`, skill `sharepoint-spfx-web-parts`). Released as managed solutions + `.sppkg` through a pipeline (`power-platform-solution-release-alm`).

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Picking a code app or custom app when a canvas or model-driven app would do | More code to own, premium licences, slower delivery | Step 1 table; least custom option first |
| Applying one product's rules to another | Canvas "500 row" thinking in code apps, or `$top` paging in React | Read only the matching reference |
| Calling external APIs directly from a code app with `fetch` | Blocked by CSP `connect-src 'none'` | Use a connector (custom connector for your API) |
| Secrets in SPFx / code app / React bundles | Anyone can read them | Connections, Key Vault env vars, or a server |
| Custom connector in the same solution as its flows on first import | Import fails | Separate connector solution first |
| One giant skill or prompt with every product's detail | Context wasted, wrong rules applied | This hub + references + focused skills (progressive disclosure) |

## Validation checklist

### Security
- [ ] No secrets in any client bundle
- [ ] Dataverse roles tested with a non-admin user
- [ ] DLP checked for every connector, including HTTP / custom

### Performance
- [ ] The product's real limit identified (page size, data row limit, timeout, bundle size)
- [ ] Heavy UI (WebGL, large libraries) lazy-loaded

### ALM
- [ ] Everything in solutions / Git; versions bumped
- [ ] Env var definitions without values; connection references present

### Solution packaging
- [ ] Custom connectors in their own solution, imported first
- [ ] SPFx `.sppkg` built in CI, not on a laptop

### Deployment readiness
- [ ] Licences confirmed for every user group
- [ ] Every changed path tested and read back; untested = blocker

## References
- [Microsoft] [Power Apps code apps overview](https://learn.microsoft.com/power-apps/developer/code-apps/overview)
- [Microsoft] [Code apps Content Security Policy](https://learn.microsoft.com/power-apps/developer/code-apps/how-to/content-security-policy)
- [Microsoft] [Canvas app delegation](https://learn.microsoft.com/power-apps/maker/canvas-apps/delegation-overview)
- [Microsoft] [Power Automate limits](https://learn.microsoft.com/power-automate/limits-and-config)
- [Microsoft] [SPFx Heft toolchain](https://learn.microsoft.com/sharepoint/dev/spfx/toolchain/sharepoint-framework-toolchain-rushstack-heft)
- [Microsoft] [Custom connectors in solutions](https://learn.microsoft.com/connectors/custom-connectors/customconnectorssolutions)
- [Microsoft] [Data policies for custom connectors](https://learn.microsoft.com/power-platform/admin/dlp-custom-connector-parity)
