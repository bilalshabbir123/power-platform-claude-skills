# pwa-offline-first-sync

**Problem it solves:** field apps that lose changes, create duplicates on retry, overwrite each other, or keep showing jobs that were reassigned, once they're used without signal.

**Use it when:** building or fixing a React PWA (IndexedDB/Dexie) with an ASP.NET Core + Azure SQL backend that must work offline: surveyors, engineers, inspectors, fitters.

**What's inside:** outbox in the same transaction, operation format, idempotent push with `rowversion` conflicts (server wins, client values kept), scoped pull with scope reconciliation, one-record-per-parent IDs across devices (UUID v5 + merge-create), photo upload with SAS, sync triggers that let a serverless DB pause, examples, mistakes, checklist.

**Related skills:** `azure-low-cost-poc-hosting`, `entra-id-msal-pwa-sign-in`
