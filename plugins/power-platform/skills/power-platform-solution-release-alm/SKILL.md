---
name: power-platform-solution-release-alm
description: Release a Power Apps code app with its Dataverse tables, flows, connection references, environment variables and security roles from DEV/TEST to production as a managed solution — safely and verifiably. Use when preparing a production package, importing a managed solution, deciding whether a release is "ready", protecting flow on/off states during an upgrade, or checking production after an import.
---

# Solution release and ALM for a code app

## Purpose
- **What it does:** an environment strategy, a release checklist that blocks "ready" until everything changed is tested, a packaging procedure (managed export without DEV values), and read-only post-import verification.
- **When to use it:** every production release; first release of a new app; any import into a downstream environment.
- **Expected outcome:** production changes only through managed solutions, each release is reproducible and checked, flows keep their intended on/off state, and nothing untested is called ready.

## Expertise
- **Solution architects** run at least DEV/TEST → PROD (ideally DEV → TEST → PROD), with one publisher and prefix, unmanaged in DEV and **managed everywhere else**.
- **Release managers** freeze a version, list every change, and treat untested items as **blockers**, not footnotes.
- **Automation specialists** snapshot flow states before an import and compare after.
- **MVP practice:** production is **read-only for builders**. Investigate with GET requests; change it only through the release.

## Instructions

### Design approach
1. **Environments:** DEV (build, unmanaged), TEST/UAT (managed import, real-like data, test mode on), PROD (managed). Use Managed Environments where available for sharing limits, usage insights and pipelines.
2. **One solution** (or a small set with clear dependencies) containing: the code app, tables/columns, flows, connection references, environment variable **definitions**, security roles, AI Builder prompts, and anything the app references.
3. **Environment variables** for every value that differs per environment (recipients, URLs, IDs, switches such as test recipient / messages live). **Values are not shipped**: remove DEV values from the solution and set PROD values with a deployment settings file or after import.
4. **Connection references** bound per environment at import, to connections owned by the right service account.
5. **Fix forward.** Plan for a newer version to fix problems rather than rollback; keep previous managed zips and release notes so you know what changed.

### Development standards
- **Version every release:** solution version (e.g. `1.0.0.40`) and app version (e.g. `v1.4.27`), both in release notes.
- **Release checklist — "ready" means all of these are true:**
  1. Every changed form: create/edit → save → **refresh** → value still there → **read back from Dataverse** (not just the UI).
  2. Every changed flow: one successful test run per branch, including the failure branch; trigger history checked.
  3. Every new column exists in the solution, with the right type and MaxLength.
  4. Untested items listed as **blockers** with what's needed to test them (e.g. "needs a real email to the support mailbox", "needs a non-admin user").
  5. Unit tests, lint and build pass.
  **[Field-tested]** A release was called ready while one form was "not tested". A field on that form never saved in production. The fix was simple; the damage was trust.
- **Export:**
  ```bash
  pac auth select --index <dev-profile>           # confirm DEV/TEST, never PROD
  pac solution online-version --solution-name ContosoRequests --solution-version 1.0.0.40
  pac solution export --name ContosoRequests --managed --path ./out/ContosoRequests_1_0_0_40_managed.zip
  ```
- **Inspect the zip before handing it over:** unzip and check `solution.xml` version, the app bundle contains the new app version string, every expected flow JSON is present, `environmentvariabledefinitions/*` contain **no** `environmentvariablevalues`, roles are present, and changed column metadata (e.g. MaxLength) is in `customizations.xml`.

### Governance and DLP
- Check DLP policies in the target environment for every connector the solution uses **before** import.
- Production import done by a named person (often not the developer), with a change record.
- Release notes in plain language for the business: what's new, what changed behaviour (especially automatic records and messages), what users must do.

### Security
- Roles are in the solution; **role assignments and app sharing** are done after import per environment.
- Never ship credentials; secrets via environment variables of type Secret (Key Vault).
- Builders have no write access to production data; use read-only queries for checks.

### Performance
- Large imports run asynchronously; schedule outside business hours.
- After import, flows with polling triggers start consuming requests immediately — check the owner's request entitlement.

### ALM
- **Source control:** the code app lives in Git (code apps don't support Power Platform Git integration **[Microsoft]**). Store flow generator scripts or exported definitions, role scripts and release notes in the same repo.
- **Flow on/off states:** snapshot before import and compare after:
  ```bash
  # GET only, against the target environment
  curl -s -H "Authorization: Bearer $TOKEN" -H "Accept: application/json" \
    "$ORG/api/data/v9.2/workflows?\$filter=category%20eq%205&\$select=name,statecode,workflowid" > before.json
  ```
  **[Field-tested]** Depending on the solution contents and import options, a managed upgrade can change flow states — once it would have turned on flows that production had deliberately switched off. New flows typically arrive **on**. Decide each flow's intended state, and if needed prepare the package so existing flows keep their production state.
- **Pipelines:** Power Platform Pipelines or Azure DevOps/GitHub Actions with the Power Platform Build Tools for repeatable export/import with deployment settings.

### Licensing
- Code app users need premium entitlements **[Microsoft]**; flows need appropriate Power Automate licences or Process licences for heavy use. Confirm before go-live — a release that users can't open is not deployable.

## Examples

### Beginner — first managed release
1. Add the app (`pa app push --solution-id …`), tables, flows, connection references, env var definitions to one solution in DEV.
2. Export managed; import into TEST; bind connections; set env var values (test recipient = tester).
3. Run the release checklist in TEST; then import the same zip into PROD.

### Intermediate — a release with new columns and new flows
- Bump the solution version; export managed; inspect the zip (columns, flows, no env var values).
- Snapshot PROD flow states (GET).
- After import: GET-check solution version, app published time, every flow state vs snapshot, new columns exist, connection references bound.
- Post-import tasks for the owner: run any one-off backfill flow once, assign roles, switch on flows meant to start manually.

### Advanced (enterprise) — gated pipeline
- Stage 1 (DEV): `npm ci`, lint, test, build; `pa app push --solution-id … --non-interactive` (service principal).
- Stage 2: `pac solution export --managed`; artefact = zip + deployment settings per environment.
- Stage 3 (TEST): import with settings; automated smoke test (app opens, version string, one list loads); manual checklist sign-off.
- Stage 4 (PROD): approval gate → import with PROD settings → read-only verification job (versions, flow states vs snapshot, columns) → release notes published.

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Calling a release ready with untested items | Production bug, lost trust | Untested = blocker; checklist |
| DEV env var values shipped in the solution | PROD sends to DEV recipients/IDs | Remove values; deployment settings |
| Not snapshotting flow states | Flows switched on/off unexpectedly | Snapshot + compare |
| Direct changes in production | Unmanaged layers, drift | Managed solution only; prod read-only for builders |
| Column changed in DEV but not in the solution | Saves fail in PROD | Inspect `customizations.xml`; test saves after import in TEST |
| Connection references bound to a personal account | Flows break when that person leaves or changes password | Service-account connections |
| Skipping post-import checks | Problems found by users | Read-only verification script |
| Version numbers not bumped | Can't tell what's deployed | Bump solution + app version every release |

## Validation checklist

### Security
- [ ] No secrets or env var values in the package
- [ ] Roles in solution; assignment plan per environment
- [ ] Builders have read-only access in PROD

### Performance
- [ ] Polling flows' request use estimated against entitlements
- [ ] Import scheduled outside business hours

### ALM
- [ ] Solution and app versions bumped; release notes written
- [ ] Code, flow definitions/scripts, role scripts in Git
- [ ] Previous managed zip kept

### Solution packaging
- [ ] Zip inspected: version, app bundle version, flows, columns/MaxLength, roles, env var definitions without values
- [ ] Connection references all present

### Deployment readiness
- [ ] Release checklist complete in TEST (forms read back, flow branches, failure paths)
- [ ] Untested items: none, or explicitly accepted by the owner
- [ ] Flow-state snapshot taken; post-import verification plan ready
- [ ] Post-import owner tasks listed (backfills, roles, switches)

## Troubleshooting
| Symptom | Likely cause | Fix |
|---|---|---|
| Field never saves in production | Form not tested; column not in the solution | Release checklist: save → refresh → read back; inspect `customizations.xml` |
| Production emails go to DEV recipients | Env var values shipped in the solution | Remove values; set PROD values via deployment settings |
| Flows switched on/off after import | No snapshot before import | Snapshot + compare; restore intended states |
| Import fails on custom connector | Connector in the same solution as its flows on first import | Separate connector solution imported first |
| Can't tell what's in production | Versions not bumped | Bump solution + app version; release notes |

Not sure which product applies? Start with the `power-platform-solution-builder` hub skill.

## References
- [Microsoft] [ALM with Microsoft Power Platform](https://learn.microsoft.com/power-platform/alm/overview-alm)
- [Microsoft] [Managed and unmanaged solutions](https://learn.microsoft.com/power-platform/alm/solution-concepts-alm)
- [Microsoft] [Environment variables](https://learn.microsoft.com/power-apps/maker/data-platform/environmentvariables)
- [Microsoft] [pac solution reference](https://learn.microsoft.com/power-platform/developer/cli/reference/solution)
- [Microsoft] [Pipelines in Power Platform](https://learn.microsoft.com/power-platform/alm/pipelines)
