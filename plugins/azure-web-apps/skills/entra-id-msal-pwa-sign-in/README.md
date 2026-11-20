# entra-id-msal-pwa-sign-in

**Problem it solves:** Microsoft 365 sign-in that breaks in installed iOS PWAs, blocks offline use, loses queued changes when the token expires, or relies on UI-only role checks.

**Use it when:** adding Entra ID sign-in to a React PWA with an ASP.NET Core API, including subcontractors as B2B guests and a fake sign-in for local development.

**What's inside:** two app registrations, MSAL redirect flow, server roles + resource checks, offline token rule, "sign in to sync", dev-only auth with a startup guard, examples, mistakes, checklist.

**Related skills:** `pwa-offline-first-sync`, `azure-low-cost-poc-hosting`
