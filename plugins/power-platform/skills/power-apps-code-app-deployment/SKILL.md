---
name: power-apps-code-app-deployment
description: Build, publish and verify a Power Apps code app (React/Vue/Vite) with the Power Apps CLI (`pa app push`, older `power-apps push` / `pac code push`). Use when publishing a code app, when a publish "succeeds" but the change isn't live, when the CLI says multiple accounts or signs in as the wrong user, when setting up a new environment for code apps, or when scripting non-interactive deploys.
---

# Power Apps code app — build, publish and verify

## Purpose
- **What it does:** gives a fixed, verifiable sequence to publish a code app, and the checks that prove the published version is the one you built.
- **When to use it:** every publish; first-time environment setup; CI or service-principal publishing; any time "the fix is deployed but users don't see it".
- **Expected outcome:** each publish is traceable (version string visible in the app, commit pushed, correct environment and account) and nothing un-built or un-committed is ever published.

## Expertise
- **Solution architects** treat the code app as one component of a solution, never as a loose app: it is published with `--solution-id` so it moves through environments with its tables, flows and environment variables.
- **Code app developers** know the publish command uploads the **existing build output** — it does not build. They make the build the last step before the publish and prove it with a version string.
- **Automation / DevOps specialists** script the sequence (lint → test → build → verify → commit → publish) so nobody skips a step, and use a service principal with `--non-interactive` for pipelines.
- **MVP practice:** show the app version in the UI. It is the cheapest possible way to confirm a deployment landed for a given user and browser session.

## Instructions

### Design approach
1. **One environment per stage.** Develop and publish to DEV/TEST only. Production receives the app **only through a managed solution import** (see `power-platform-solution-release-alm`). Never `pa app push` to production.
2. **Enable code apps per environment** **[Microsoft]**: Power Platform admin center → Environments → *environment* → Settings → Product → Features → *Power Apps code apps* → **Enable code apps**.
3. **Put the app in a solution from day one:** `pa app push --solution-id <solution-guid>` (or set `PA_CLI_SOLUTION_ID`).
4. **Know your CLI generation.** The command has changed name over time — check with `--help` before scripting:
   | CLI | Publish command | Notes |
   |---|---|---|
   | Power Apps CLI (current) | `pa app push` | Documented on Microsoft Learn |
   | npm `@microsoft/power-apps` (earlier) | `power-apps push --non-interactive` | Same flow, older binary name |
   | PAC CLI (earliest preview) | `pac code push` | **[Field-tested]** On one tenant this hit a different endpoint and silently didn't update the app; we stopped using it. If you must use it, verify the version string afterwards. |

### Development standards
1. **Version string.** Keep `appVersion` in one file (e.g. `src/brandingConfig.ts`) and show it in the sidebar or footer. Bump it on **every** publish.
2. **Fixed order — no edits between build and publish:**
   ```bash
   npm run lint && npm test && npm run build
   grep -o "v1\.4\.[0-9]*" dist/assets/*.js | sort -u     # must show the NEW version only
   git add -A && git commit -m "<what changed> (v1.4.27)" && git push
   pa app push --solution-id "$PA_CLI_SOLUTION_ID"
   ```
   **[Field-tested]** If you edit any file (even the version number) after `npm run build`, git has the change but the published app doesn't, because the publish uploads `dist/` as it is.
3. **Commit and push before publishing,** so every published version maps to a commit.
4. **Generated files:** after `pa app add data-source` / `pa app refresh data-source`, review the diff of generated services and models before building; regenerated code can overwrite local fixes. Never hand-edit generated files without a note explaining why.
5. **Local development:** the Power Apps data bridge only answers inside the player/host. **[Field-tested]** Outside it, SDK calls can hang instead of failing. Wrap data calls in a short timeout in dev builds only (`import.meta.env.DEV`) so the app shows its error state instead of an endless spinner. Use `pa app run` for the local host.

### Governance and DLP
- Code apps follow the environment's **DLP policies, sharing limits, Conditional Access and app quarantine** **[Microsoft]**. A connector blocked by DLP will block the app at launch — check policies before adding a data source.
- Keep a list of every data source and connector the app uses (`power.config.json` holds it) and review it in each release.
- Share the app with **security groups**, not individuals (`pa app share --principal <group-object-id>`). Sharing an app does **not** grant data access; Dataverse security roles do.

### Security
- **Compiled assets are served from a publicly accessible endpoint** **[Microsoft]**. Never put secrets, keys, tenant-specific confidential data or customer data in the bundle. Load data after sign-in from a data source.
- IP restriction (SAS IP binding / firewall) does **not** apply to code apps; use **Conditional Access** by location instead **[Microsoft]**.
- Sign in with the **intended account** and confirm it before every publish: `pa auth status`; change with `pa auth switch --account <upn>`. **[Field-tested]** With the older npm CLI, cached tokens for two accounts produced "Multiple accounts found" and publishes failed until the cached credential was cleared (on macOS it was stored in Keychain under the service name `power-apps`).
- For pipelines, use a **service principal**: share the app with it with `--access edit` (use the Enterprise Application object ID) and publish with `--non-interactive` **[Microsoft]**.

### Performance
- Keep the bundle lean: code-split large pages (`React.lazy`), avoid shipping sample data in production builds.
- Every page load costs Dataverse requests; see `power-apps-code-app-dataverse-data-access` for paging, `$select` and request limits.
- Publishing doesn't affect running users until they reload; tell testers to reload (and, in the player URL, **don't keep a `hint=` query parameter** — **[Field-tested]** it pinned the browser to an older deployment session).

### ALM
- Source control is **your Git repository**. Code apps don't support Power Platform Git integration **[Microsoft]**, so the solution export is not your source of truth for the code — Git is.
- Tag or note the version in the commit message (`… (v1.4.27)`) and keep release notes per version.
- Promote to TEST/PROD by exporting the solution that contains the app (managed for downstream environments).

### Licensing
- End users need **Power Apps Premium**, pay-as-you-go, an App Pass, or auto-claim **[Microsoft]**. Budget for it before the first production release.

## Examples

### Beginner — first publish to a dev environment
```bash
pa auth login --account maker@contoso.com
pa auth status                         # confirm the active account
pa app init --display-name "Contoso Requests" --environment-id <dev-env-guid>
npm run build
pa app push --solution-id <solution-guid>
```
Open the app from make.powerapps.com → Apps; confirm the version in the footer.

### Intermediate — a deploy script that refuses to publish a stale build
```bash
#!/usr/bin/env bash
set -euo pipefail
VERSION=$(grep -o "v[0-9]*\.[0-9]*\.[0-9]*" src/brandingConfig.ts | head -1)
npm run lint && npm test && npm run build
if ! grep -q "$VERSION" dist/assets/*.js; then echo "dist does not contain $VERSION"; exit 1; fi
if [ -n "$(git status --porcelain)" ]; then git add -A && git commit -m "Release $VERSION"; fi
git push
if [ "$(git rev-list --count @{u}..HEAD)" != "0" ]; then echo "not pushed"; exit 1; fi
pa auth status | grep -qi "$EXPECTED_ACCOUNT" || { echo "wrong account"; exit 1; }
pa app push --solution-id "$PA_CLI_SOLUTION_ID"
echo "Published $VERSION — reload the app and check the footer."
```

### Advanced (enterprise) — pipeline publish with a service principal
1. Register an app in Entra ID; create an application user in the DEV environment with a role that can create/update canvas apps in the solution.
2. Share the code app with the service principal (Enterprise Application object ID) with `--access edit`.
3. In the pipeline: `npm ci && npm run lint && npm test && npm run build`, verify the version, then `pa app push --solution-id $PA_CLI_SOLUTION_ID --non-interactive`.
4. Export the solution **managed** with `pac solution export --managed` and promote through Power Platform Pipelines or your release tool. Production never receives a direct push.
5. Post-deploy: a smoke test that reads the version string and one Dataverse list.

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Editing a file after `npm run build`, then publishing | Git has the change, the live app doesn't | Build is the last step; grep `dist/` for the new version before publishing |
| Forgetting to bump the version | Can't tell if a publish landed | Bump on every publish; show it in the UI |
| Publishing with the wrong signed-in account / tenant | Publish fails, or lands in the wrong environment | `pa auth status` before every push; script the check |
| Using an old CLI command from a blog post | Command not found, or a publish that doesn't update | `pa --help`; follow the table above |
| Pushing directly to production | Unmanaged, untraceable changes in prod | Prod only via managed solution import |
| Secrets in the front-end bundle | Exposed on a public endpoint | Keep secrets server-side (flows, custom APIs, environment variables with secret store) |
| Keeping `hint=` in the player URL | Testers see an older deployment | Share the play URL without `hint=` |
| Repo inside a cloud-synced folder (OneDrive etc.) | **[Field-tested]** `node_modules` files evicted to "online-only"; git, tests and builds hang | Keep repos outside synced folders, or run `npm ci` to restore local files |
| Not reviewing generated files after refresh | Local fixes in generated services silently lost | Review the diff after every `add/refresh data-source` |

## Validation checklist

### Security
- [ ] No secrets, keys or customer data in `src/` or `dist/` (`grep -ri "secret\|apikey\|password" dist/` is empty)
- [ ] Correct account and environment shown by `pa auth status`
- [ ] App shared with security groups only; Conditional Access considered

### Performance
- [ ] Bundle size reviewed; large pages lazy-loaded
- [ ] No sample/demo data in the production bundle

### ALM
- [ ] Version bumped and visible in the UI
- [ ] Commit pushed (`git status -sb` shows no "ahead")
- [ ] Release notes updated for this version

### Solution packaging
- [ ] App is in the solution (`--solution-id`)
- [ ] All data sources the app uses are tables/flows/connection references in the same solution

### Deployment readiness
- [ ] `lint`, `test`, `build` passed in this order, with no edits since
- [ ] `dist/` contains the new version string
- [ ] After publish: reloaded the app (no `hint=`), version matches, one changed screen checked

## References
- [Microsoft] [Power Apps code apps overview](https://learn.microsoft.com/power-apps/developer/code-apps/overview)
- [Microsoft] [Power Apps CLI command reference](https://learn.microsoft.com/power-apps/developer/code-apps/reference/cli)
- [Microsoft] [Code apps system configuration (public hosting, header, request access)](https://learn.microsoft.com/power-apps/developer/code-apps/system-limits-configuration)
