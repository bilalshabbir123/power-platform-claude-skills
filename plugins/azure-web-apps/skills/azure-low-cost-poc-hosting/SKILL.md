---
name: azure-low-cost-poc-hosting
description: Host a proof of concept or demo on Azure for close to £0 — App Service Free F1 vs Basic B1 (scale up for demo days, down after), Azure SQL Database free offer (serverless, auto-pause, what happens when the free allowance runs out), Blob Storage with managed identity and no keys, and the one-way traps. Use it when someone asks "host this cheaply on Azure", "free Azure SQL", "app is slow on first load", "database paused", "sync failed since the 10th", "scale up for the demo", "stop Azure costs after the demo", or "why can't I switch the database back to auto-pause". For .NET / Node web apps with a SQL backend.
---

# Low-cost Azure hosting for a POC or demo

## Purpose
- **What it does:** a cost-safe setup for a POC (one Linux Web App, one free Azure SQL database, one storage account) plus the exact switches for demo days and afterwards, and the traps that cost money or break the app.
- **When to use it:** before creating resources for a POC, before and after a demo, when a free-tier app is slow or its database is paused.
- **Expected outcome:** £0 most of the month, a fast app on demo day, and no surprise bill.

## Expertise
- **Architects** keep the POC to one App Service (API + built SPA in `wwwroot`), one database, one storage account, all with managed identity — no secrets to rotate.
- **Field-tested practice:** free tiers are fine for a POC *if* the app lets the database sleep and someone owns the demo-day scale-up / scale-down.

## Instructions

### Design approach
| Resource | POC choice | Notes |
|---|---|---|
| App Service plan | **Free F1**, Linux | No Always On, 60 CPU min/day, 1 GB disk; sleeps after ~20 min idle → first request takes from several seconds up to ~2 min. **[Field-tested]** F1 quota can be unavailable in a region: try a nearby region. |
| Demo days | **Basic B1** + Always On | Billed per hour while on B1; scale back after |
| Database | **Azure SQL free offer** (serverless) | Up to 10 free DBs per subscription, monthly vCore-seconds + 32 GB each; auto-pause when idle |
| Storage | Standard **LRS**, private container | GRS isn't needed for a POC; check the SKU actually created matches the docs |
| Auth to SQL/Storage | System-assigned **managed identity** | SQL: `CREATE USER [app-name] FROM EXTERNAL PROVIDER` + `db_datareader`/`db_datawriter` only; Storage: *Storage Blob Data Contributor* |

### The free SQL database: choose the "limit reached" behaviour carefully
When the monthly free allowance is used up the database does one of two things:
- **AutoPause** — pauses until the 1st of next month. £0, but the app's database is **offline** for the rest of the month. **[Field-tested]** Symptom: the PWA showed "Sync failed – retrying" for 9 days; the DB status was *Paused*.
- **BillOverUsage** — keeps running and bills for compute above the allowance (still auto-pauses after the idle delay).

**[Field-tested] Switching is one-way.** Changing from BillOverUsage back to AutoPause fails:
`ProvisioningDisabled: Cannot update FreeLimitExhaustionBehavior from BillOverUsage to AutoPause`.
So: only switch to BillOverUsage if you accept paying from now on. The only way back to a guaranteed-free DB is a **new** free-offer database and a data move. Set a **budget alert** on the resource group either way.

### What uses up the free allowance
- Anything that wakes the DB: app polling, health checks that query the DB, keep-alive pings, Always On + background jobs.
- **[Field-tested]** A 60 s sync poll from one forgotten open tab kept the DB awake 24/7. Poll ~5 min, only when the page is visible and used recently; make `/api/health` (public liveness) **not** touch the DB; put DB checks on a restricted `/api/health/ready`.
- First connect after a pause takes up to ~1 min: use `Connect Timeout=60` and treat SQL error **40613** as "waking up, retry".

### Development standards — demo-day switches (run by the person who owns Azure)
```bash
az account set --subscription "<subscription name>"
# Before the demo (order matters: plan first, then Always On)
az appservice plan update -g <rg> -n <plan> --sku B1
az webapp config set -g <rg> -n <app> --always-on true
# After the demo (Always On off first — F1 doesn't support it)
az webapp config set -g <rg> -n <app> --always-on false
az appservice plan update -g <rg> -n <plan> --sku F1
# Check
az appservice plan show -g <rg> -n <plan> --query sku.name
az sql db show -g <rg> -s <server> -n <db> --query "{status:status,limit:freeLimitExhaustionBehavior}"
```
Do the scale-up the day before and open the app once, so the demo isn't the first request.

### Governance and DLP
- One resource group per POC so cost and clean-up are one scope. Tag it with owner and end date.
- Budget alert (Cost Management → Budgets) on the resource group, e.g. £5 with email at 50/100%.
- Decide who may change Azure. If the developer doesn't, write the commands down for the owner and record what was run.

### Security
- HTTPS only, minimum TLS 1.2, FTP disabled, SCM basic auth off.
- Storage: public blob access off; prefer **shared key access disabled** and sign upload/download URLs with a **user-delegation SAS** (needs *Storage Blob Data Contributor* — it includes "generate user delegation key"). Locally, Azurite only supports service SAS: put both behind one `IFileStorage` interface.
- SQL: Entra-only authentication; the app identity gets reader/writer only. Run migrations by hand with `dotnet ef migrations script --idempotent` as an Entra admin.

### Performance (limits)
- F1: 60 CPU minutes/day and cold starts. Fine for building and device testing, not for a live demo → B1.
- SQL serverless: the first query after a pause is slow; the app should show a clear "waking up" or retry, not a generic error.

### ALM (deployment)
Manual deploy for a POC is fine: `npm run build` (output into `wwwroot`) → `dotnet publish -c Release` → zip → `az webapp deploy --type zip`. Serve `sw.js` and the manifest with `no-cache`. **[Field-tested]** If the deploy window is closed after "Warmed up Kudu instance", the result is unknown: check the live bundle (`curl -s <url>/ | grep -o 'assets/[^"]*\.js'` and grep it for a string from the change) before redeploying.

### Licensing
No licences beyond the Azure subscription. Check a PDF or Office library's licence for the *exact version* before you depend on it on the server — **[Field-tested]** one popular PDF library threw a licence exception at runtime in a newer major version.

## Examples

### Beginner — first deploy check
`curl -s https://<app>.azurewebsites.net/api/health` → `{"status":"ok"}` (allow ~30–120 s on F1 the first time).

### Intermediate — "Sync failed" all week
1. Portal → SQL database → status *Paused* and the free-offer usage at 100%. 2. Find what kept it awake (polling interval, health check hitting the DB). 3. Fix the app first. 4. Decide: wait for the 1st (free) or switch to BillOverUsage (paid, **one-way**).

### Advanced (enterprise) — move from POC to pilot
Keep B1 (or higher) with Always On; move the DB to a paid serverless or provisioned tier with backups/PITR you've checked; add App Insights, alerts, staging slot (Standard+), and automated deployment.

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Switching the free DB to BillOverUsage "for the demo" | Can't switch back; billing continues | Decide permanently; budget alert |
| Fast polling / DB health pings | Free compute gone mid-month; DB paused | 5-min visible-only polling; health check without DB |
| Live demo on F1 | 2-minute first load in front of the client | Scale to B1 + Always On the day before |
| Scaling to F1 with Always On still on | Command fails | Turn Always On off first |
| Leaving B1 on after the demo | ~£10–15/month for nothing | Scale down the same day |
| Docs say LRS, account is GRS | Paying for redundancy you don't need | Check `sku.name` after creation |

## Validation checklist

### Security
- [ ] Managed identity for SQL and Storage; no connection-string passwords or account keys in settings
- [ ] HTTPS only, TLS 1.2, FTP off
### Performance
- [ ] `/api/health` doesn't query the DB; polling ≤ every 5 min when visible
- [ ] Scaled to B1 + Always On before a demo
### ALM
- [ ] Deploy verified on the live site (bundle contains the change)
### Solution packaging
- [ ] One resource group, tagged with owner and end date
### Deployment readiness
- [ ] Budget alert set; free-limit behaviour decided and written down
- [ ] After the demo: Always On off, plan back to F1, verified

## Troubleshooting
| Symptom | Likely cause | Fix |
|---|---|---|
| First page load ~2 min | F1 asleep | B1 + Always On for demos |
| Error 40613 on connect | Serverless DB waking | Retry; `Connect Timeout=60` |
| DB *Paused* mid-month | Free allowance used, AutoPause | Fix polling; wait for the 1st or accept billing (one-way) |
| `Cannot update FreeLimitExhaustionBehavior from BillOverUsage to AutoPause` | One-way setting | New free DB + data move, or keep paying with a budget alert |
| Upload URL 403 | MI lacks *Storage Blob Data Contributor* | Assign the role; wait a few minutes |

## References
- [Microsoft] Azure SQL Database free offer — https://learn.microsoft.com/azure/azure-sql/database/free-offer
- [Microsoft] Serverless compute tier and auto-pause — https://learn.microsoft.com/azure/azure-sql/database/serverless-tier-overview
- [Microsoft] App Service plans and limits — https://learn.microsoft.com/azure/app-service/overview-hosting-plans
- [Microsoft] Managed identity to Azure SQL — https://learn.microsoft.com/azure/app-service/tutorial-connect-msi-sql-database
- [Microsoft] Create a budget — https://learn.microsoft.com/azure/cost-management-billing/costs/tutorial-acm-create-budgets
- [Field-tested] Lessons 42–47 and 49 in `docs/lessons-learned.md`
