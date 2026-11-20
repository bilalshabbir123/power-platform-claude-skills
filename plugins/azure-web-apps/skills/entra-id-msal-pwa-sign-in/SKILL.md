---
name: entra-id-msal-pwa-sign-in
description: Microsoft Entra ID (Microsoft 365) sign-in for an installable PWA with an ASP.NET Core API — MSAL redirect flow that works in an installed iPhone/iPad app, app roles enforced on the server, offline use after one online sign-in, "sign in to sync" without losing queued changes, guest (B2B) users such as subcontractors, and a development-only fake sign-in that refuses to start anywhere else. Use it when someone asks to "add Microsoft 365 login to my React app", "MSAL popup doesn't work on iPad", "roles not in the token", "app works offline but sync needs login", "let subcontractors sign in", or "fake login for local dev".
---

# Entra ID sign-in for an offline PWA

## Purpose
- **What it does:** a sign-in design for a React PWA + ASP.NET Core API that works installed on iOS/Android/desktop, keeps working offline, and enforces roles on the server.
- **When to use it:** any internal line-of-business PWA for a Microsoft 365 organisation, including external subcontractors as B2B guests.
- **Expected outcome:** one sign-in online, then offline use; sync quietly refreshes tokens; role checks on every endpoint; local dev never blocked on app registrations.

## Expertise
- **Architects** use two app registrations: the **API** (exposes scope `access_as_user`, defines **app roles**) and the **SPA** (redirect URIs for localhost and the deployed URL). Roles come from the `roles` claim, assigned in *Enterprise applications → Users and groups*.
- **Field-tested practice:** popups are unreliable in installed PWAs on iOS; use the **redirect flow only**.

## Instructions

### Design approach
1. MSAL (`@azure/msal-browser` + `@azure/msal-react`), **redirect flow**, `cacheLocation: "localStorage"` so an installed PWA keeps the session; mitigate XSS with a strict CSP (`default-src 'self'`, `connect-src 'self' https://login.microsoftonline.com <blob host>`, `frame-ancestors 'none'`) and no `dangerouslySetInnerHTML`.
2. API validates JWTs with `Microsoft.Identity.Web`; policies per endpoint (`RequireRole`), plus **resource checks** (own jobs only). Hidden UI is not security.
3. First sign-in upserts an `AppUser` row from claims (`oid`, `name`, `preferred_username`).
4. **Offline rule:** after one online sign-in, all local reads/writes work with no token. Sync calls `acquireTokenSilent` only when online. On `InteractionRequiredAuthError` show "Sign in to sync your changes" and **keep the outbox**.
5. Per-user local database (`app_<oid>`). Sign-out wipes it, but if there are unsynced changes, warn and require confirmation (default: sync first).

### Development standards — development-only fake sign-in
- `Auth:Mode = Dev` registers a fake authentication scheme where the developer picks a seeded persona/role.
- **Throw at startup if Dev mode is configured outside `Development`:**
  ```csharp
  if (mode == "Dev" && !env.IsDevelopment())
      throw new InvalidOperationException(
          $"Auth:Mode 'Dev' is only allowed in the Development environment (current: '{env.EnvironmentName}').");
  ```
- Test that startup fails in `Production` with Dev mode — a misconfigured app setting must never become "anyone is admin".

### Governance and DLP
- Assign roles to users or groups; one app role per assignment. **[Field-tested]** "Add user/group" can be greyed out unless you are an Owner of the enterprise app or have *Cloud Application Administrator*.
- Role changes apply after the user signs out and in (new token).
- Subcontractors: invite as **B2B guests**; give them the most limited role (e.g. read-only "My week"). Conditional Access/MFA applies to them in your tenant.

### Security
- Server returns 401 (no/invalid token) and 403 (wrong role or not their resource) as ProblemDetails without internals. Test role/token tampering and IDOR.
- Never put secrets in the SPA; the SPA registration has no client secret.
- Log security events (sign-in, 403) without personal data.

### Performance
- Token acquisition happens only when online and when sync runs; don't block the UI on it.
- The MSAL bundle is large; precache it for offline use and consider code-splitting later.

### ALM (deployment)
- Build-time config via `import.meta.env` (`VITE_ENTRA_CLIENT_ID`, `VITE_ENTRA_TENANT_ID`, `VITE_API_SCOPE`) read from a git-ignored `.env.production.local`. Tenant and client IDs aren't secrets but keep them out of a public repo.
- Add the deployed URL as an SPA redirect URI **exactly** (including the full host name the platform gives you).
- **[Field-tested]** Test on a real iPad early: install the PWA (Share → Add to Home Screen), sign in with MFA, close and reopen offline. Device tests need HTTPS (dev tunnel or the cloud deployment), not a LAN IP.

### Licensing
Entra ID sign-in is included with Microsoft 365; B2B guests are covered by the MAU-based External ID billing (first 50,000 MAU free at the time of writing — check current pricing). MSAL and Microsoft.Identity.Web are MIT.

## Examples

### Beginner — redirect sign-in
```ts
const msal = new PublicClientApplication({
  auth: { clientId: import.meta.env.VITE_ENTRA_CLIENT_ID,
          authority: `https://login.microsoftonline.com/${import.meta.env.VITE_ENTRA_TENANT_ID}`,
          redirectUri: window.location.origin },
  cache: { cacheLocation: 'localStorage' },
});
await msal.initialize();
await msal.handleRedirectPromise();
if (!msal.getActiveAccount()) await msal.loginRedirect({ scopes: [import.meta.env.VITE_API_SCOPE] });
```

### Intermediate — token for sync, never for local work
```ts
try {
  const { accessToken } = await msal.acquireTokenSilent({ scopes: [apiScope], account });
  await sync(accessToken);
} catch (e) {
  if (e instanceof InteractionRequiredAuthError) setState('signInRequired'); // outbox kept
  else throw e;
}
```

### Advanced (enterprise) — resource check
```csharp
group.MapGet("/jobs/{id:guid}", async (Guid id, ICurrentUser user, IJobRepository jobs, CancellationToken ct) =>
{
    var job = await jobs.Find(id, ct);
    if (job is null) return Results.NotFound();
    if (user.IsInRole(Roles.Surveyor) && job.SurveyorId != user.Id) return Results.Forbid();
    return Results.Ok(JobDto.From(job));
}).RequireAuthorization(Policies.CanReadJobs);
```

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Popup flow in an installed iOS PWA | Sign-in window lost / blocked | Redirect flow only |
| Requiring a token for local reads | App unusable offline | Token only for sync |
| Clearing the outbox when the token expires | Field work lost | Keep it; show "Sign in to sync" |
| Fake dev auth without a startup guard | Production open to anyone if a setting leaks | Throw outside Development; test it |
| Role checks only in the UI | Users call the API directly | Policy + resource check on the server |
| Expecting new roles immediately | User still gets 403 | Sign out and in |

## Validation checklist

### Security
- [ ] 401/403 tests per endpoint; IDOR tests (user A vs B, guest writes)
- [ ] App fails to start with Dev auth outside Development
- [ ] CSP set; no secrets in the SPA
### Performance
- [ ] Silent token only on sync; UI never waits for auth offline
### ALM
- [ ] Redirect URIs for localhost and the exact deployed URL
- [ ] Entra values in git-ignored env files
### Solution packaging
- [ ] App roles defined on the API registration and assigned to groups
### Deployment readiness
- [ ] Real-device test: install, MFA sign-in, offline reopen, sign-in-to-sync recovery

## Troubleshooting
| Symptom | Likely cause | Fix |
|---|---|---|
| `AADSTS50011` redirect mismatch | URI not registered exactly | Add the exact origin as an SPA redirect URI |
| Token has no `roles` | Role not assigned, or token for the wrong audience | Assign in Enterprise apps; request the API scope |
| Can't assign users | Not an app Owner / Cloud Application Administrator | Ask the tenant admin |
| Sign-in loop in installed iOS app | Popup flow or missing `handleRedirectPromise` | Redirect flow; await `handleRedirectPromise()` on start |

## References
- [Microsoft] MSAL.js redirect vs popup — https://learn.microsoft.com/entra/identity-platform/scenario-spa-sign-in
- [Microsoft] App roles — https://learn.microsoft.com/entra/identity-platform/howto-add-app-roles-in-apps
- [Microsoft] Microsoft.Identity.Web — https://learn.microsoft.com/entra/msal/dotnet/microsoft-identity-web/
- [Microsoft] B2B collaboration — https://learn.microsoft.com/entra/external-id/what-is-b2b
- [Field-tested] Lesson 48 in `docs/lessons-learned.md`
