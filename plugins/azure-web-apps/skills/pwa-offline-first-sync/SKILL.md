---
name: pwa-offline-first-sync
description: Build safe offline-first sync for a field-service PWA (React + IndexedDB/Dexie on the device, ASP.NET Core + Azure SQL on the server) — outbox, idempotent push, optimistic concurrency with rowversion, conflicts kept for office review, scoped pull with scope reconciliation, photo uploads, and sync triggers that let a serverless database pause. Use it when someone asks to "make the app work offline", "sync when back online", "stop duplicates on retry", "two devices created the same record", "sync keeps failing", "reassigned jobs still show on the tablet", or is building a surveyor / engineer / fitter app used without signal. Not for Power Apps offline profiles or canvas SaveData.
---

# Offline-first sync for a field-service PWA

## Purpose
- **What it does:** gives a proven design for a local-first web app that keeps working with no signal and syncs safely later: no lost changes, no duplicates on retry, no silent overwrites, and devices that only hold the data the user is allowed to see.
- **When to use it:** surveyor, engineer, inspector or fitter apps; any PWA where people capture data and photos on site; when you see duplicates after retries, lost edits, or stale records on devices.
- **Expected outcome:** a generic sync engine where new entities and commands are added by registration, with tests for idempotency, conflicts and scope removal, and a sync badge users understand.

## Expertise
- **Architects** make the device the source of truth for the UI (IndexedDB), and the server the source of truth for business rules. The client never sets status, numbers, ownership or audit fields.
- **Developers** separate *plain data edits* (upsert/delete of allow-listed fields) from *commands* (anything with a business rule: status changes, booking, sending). Commands run a server handler that calls the domain.
- **Field-tested practice:** every bug we hit came from an assumption that a request happens exactly once, on one device, while online. Design for at-least-once, many devices, offline.

## Instructions

### Design approach
1. **Client-generated IDs** (`crypto.randomUUID()` on the device, `Guid.CreateVersion7()` on the server) so records exist before the first sync. Server-assigned human numbers (e.g. `JOB-2026-0001`) are given on first sync; show "Pending" until then.
2. **One record per thing across devices:** if two devices can each create "the survey for job X", derive that ID deterministically — **UUID v5 of (fixed namespace, parent ID)** — and let the server **merge** a create into an existing row instead of rejecting it. **[Field-tested]** Random IDs here gave two surveys for one job (office PC + tablet). Never change the namespace once released.
3. **Outbox in the same IndexedDB transaction** as the local change (Dexie `db.transaction('rw', [table, outbox], …)`). If the change is saved, the operation is queued — never one without the other.
4. **Operation format** (one per change):
   ```json
   { "operationId": "uuid", "type": "upsert|delete|command", "entity": "SurveyRoom", "entityId": "uuid",
     "baseRowVersion": "base64|null", "fields": { "lengthM": 4.2 },
     "command": "CompleteSurvey", "args": { "jobId": "uuid" }, "clientTimestamp": "ISO-8601" }
   ```
   Send **changed fields only**, from an allow-list per entity.
5. **Generic engine:** register each entity (`SyncDefinition`: allowed fields, scope rule, validator) and each command (`CommandDefinition` → application handler). Never `switch` on entity names in the engine.

### Development standards — server push (`POST /api/v1/sync/push`)
Per operation, inside a transaction, in this order:
1. **Idempotency:** look up `ProcessedOperation(OperationId, UserId)`. Found → return the stored result as `duplicate`.
2. **Permission + allow-list:** user may touch this row (resource check, not just role); every field is allowed. Otherwise `rejected(reason)`.
3. **Concurrency:** compare `baseRowVersion` with the row's `rowversion`. Mismatch → **server wins**, store the client payload and server snapshot in `SyncConflict`, return `conflict`.
4. **Validate + apply** (FluentValidation; commands via the domain, e.g. `Job.MoveTo`). Invalid transition → `rejected`.
5. **Record** the result in `ProcessedOperation`.
Limits: max 200 ops and 1 MB per request; the client batches below that (e.g. 900 KB) and pushes in order.

### Development standards — server pull (`GET /api/v1/sync/pull?since=token`)
- Return rows changed since the token, **scoped to the user**, including tombstones (`IsDeleted`).
- Upper bound = `MIN_ACTIVE_ROWVERSION()` so rows from transactions still in flight aren't skipped. Token is opaque; page the response.
- **Scope reconciliation:** for scoped sets (my jobs and their children) also return the **complete list of in-scope IDs**. The client deletes local rows not in the list **unless they have pending outbox operations**. This handles reassignment without tracking scope history.

### Development standards — client engine
- One run = recover interrupted push (`sending` → `pending`, safe because push is idempotent) → push → pull → reconcile.
- Never drop an outbox item. `conflict` / `rejected` become a visible "needs review" item; network errors put items back to `pending`.
- Exponential backoff with jitter on failure. Show **why** sync failed in the outbox panel (HTTP status / message) — **[Field-tested]** "Sync failed – retrying" with no reason cost days of diagnosis.

### Sync triggers (and letting the database sleep)
- Sync on app start, on `online` **confirmed by `GET /api/health`**, 5 s after a local save (debounced), on resume/focus or first touch after idle, and on an interval **only while the page is visible and used in the last 10 minutes**.
- **[Field-tested]** iOS often fires no `online` event after Control Centre / aeroplane mode: also sync on `visibilitychange` and `focus` (throttled).
- **[Field-tested]** A 60-second poll from one open tab kept a serverless Azure SQL database awake 24/7 and used up its free monthly compute. Use ~5 minutes, only when visible and recently used. No Background Sync API (not on iOS).

### Photos and drawings
`<input type="file" accept="image/*" capture="environment">` → compress (≈2048 px, JPEG 0.8) → strip EXIF/GPS (re-encode via canvas) → SHA-256 → store the blob in IndexedDB as `Pending` → when online ask the API for a **write-only, single-blob SAS** (≈10 min) → `PUT` direct to Blob Storage → `POST …/complete` → server checks existence, size ≤ 10 MB, **magic bytes** (JPEG/PNG/WebP/PDF; reject SVG), hash → `Uploaded`, delete the local blob. Attachments are append-only (no conflicts).

### Governance and DLP
- Field allow-lists and server-side commands are the governance boundary: the client can't set status, numbers, branch/tenant or audit fields.
- `SyncConflict` gives the office an audit trail; an admin page re-applies or dismisses each conflict.

### Security
- Every push op gets the same policy + resource check as a normal endpoint (IDOR: surveyor A can't write surveyor B's job by guessing an ID).
- Per-user IndexedDB name (e.g. `app_<oid>`); sign-out wipes it, **but warn and require confirmation if the outbox has unsynced changes** (default action: sync first).
- Tests to have: replayed `operationId`, out-of-scope op, forbidden field, oversized batch, malformed JSON, other user's attachment.

### Performance (limits and paging)
- Pull is paged; scope ID lists only for scoped sets. Keep only today + 7 days + anything with unsynced changes on devices; purge older data after sync.
- `navigator.storage.persist()` after sign-in. **Install the PWA**: Safari may evict storage of non-installed sites after 7 days without use; installed apps are exempt.

### ALM (solutions, source control, deployment)
- Put shared calculation rules in JSON test vectors (`tests/shared-test-vectors/*.json`) that **both** the C# and TypeScript tests run, so the offline estimate and the authoritative server result can't drift.
- Service worker: precache shell, API network-only, `sw.js` and manifest served `no-cache`, "Update available – reload" prompt.

### Licensing
Dexie (Apache-2.0), Workbox / vite-plugin-pwa (MIT), EF Core (MIT). No Power Platform licence involved. Check every package's licence before adding it.

## Examples

### Beginner — save a room offline
```ts
await db.transaction('rw', db.rooms, db.outbox, async () => {
  await db.rooms.put(room);
  await db.outbox.add({ operationId: crypto.randomUUID(), type: 'upsert', entity: 'SurveyRoom',
    entityId: room.id, baseRowVersion: room.rowVersion ?? null, fields: changed, status: 'pending',
    attempts: 0, clientTimestamp: new Date().toISOString() });
});
scheduleSync(); // debounced 5 s
```

### Intermediate — one survey per job across devices
```ts
// Same on every device: SHA-1(namespace bytes + jobId) → UUID v5.
const surveyId = uuidV5(SURVEY_NAMESPACE, jobId); // namespace: a fixed random UUID, never changed
```
Server: definition `MergeCreateIntoExisting = true` → a create (`baseRowVersion: null`) for an existing ID merges allowed fields instead of returning a conflict.

### Advanced (enterprise) — reassignment
Office moves a job from surveyor A to B. A's next pull returns in-scope IDs without that job → A's device deletes the job and children (no pending ops). If A had unsynced edits, keep them; push → server rejects (out of scope) → shown as "needs office review", edits preserved in `SyncConflict`.

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Outbox written after the local save, outside the transaction | Crash between the two loses the change silently | Same Dexie transaction |
| No `operationId` idempotency | Retry after a timeout creates duplicates | `ProcessedOperation` lookup first |
| Random IDs for "one per parent" records | Two devices create two surveys for one job | UUID v5 from the parent ID + server merge-create |
| Client sends `status` as a field | Business rules bypassed | Status changes only via commands |
| Pull without `MIN_ACTIVE_ROWVERSION()` | Rows committed late are never pulled | Use it as the upper bound |
| Deleting out-of-scope rows that have pending ops | Unsynced field work lost | Skip rows with outbox entries |
| Short polling interval | Serverless DB never pauses; free compute used up; DB paused → "Sync failed" | 5 min, visible + recently used only |
| Generic "Sync failed" message | Nobody can tell auth vs DB vs network | Show the reason in the panel |

## Validation checklist

### Security
- [ ] Every op passes policy + resource check; forbidden fields rejected
- [ ] Replay, oversized batch, malformed JSON tests pass
- [ ] Sign-out with pending outbox warns and defaults to sync first
### Performance
- [ ] Push batches ≤ 200 ops / < 1 MB; pull paged
- [ ] Interval sync only when visible and recently used; DB auto-pauses overnight
### ALM
- [ ] Shared test vectors run in both C# and TS
- [ ] Offline E2E (Playwright, `context.setOffline(true)`) for create → reload → online → synced, no duplicates
### Solution packaging
- [ ] New entity added by registration only (no engine changes)
### Deployment readiness
- [ ] Tested on a real installed iPad/iPhone in aeroplane mode (Playwright WebKit ≠ iOS)
- [ ] HTTPS used for device tests (service workers need it): dev tunnel or the cloud deployment

## Troubleshooting
| Symptom | Likely cause | Fix |
|---|---|---|
| Duplicates after poor signal | No idempotency, or random IDs for one-per-parent rows | `operationId` check; UUID v5 + merge-create |
| "Sync failed – retrying" for days | Database paused (free limit used) or token expired | Show reason; see `azure-low-cost-poc-hosting` |
| Reassigned job still on device | No scope reconciliation | Return in-scope IDs and delete the rest |
| No sync after aeroplane mode on iPhone | No `online` event | Sync on `visibilitychange`/`focus` |

## References
- [Vendor docs] Dexie transactions — https://dexie.org/docs/Dexie/Dexie.transaction()
- [Microsoft] `MIN_ACTIVE_ROWVERSION` — https://learn.microsoft.com/sql/t-sql/functions/min-active-rowversion-transact-sql
- [Microsoft] EF Core concurrency tokens — https://learn.microsoft.com/ef/core/saving/concurrency
- [Microsoft] User delegation SAS — https://learn.microsoft.com/azure/storage/blobs/storage-blob-user-delegation-sas-create-dotnet
- [Vendor docs] RFC 4122 name-based UUIDs (v5) — https://www.rfc-editor.org/rfc/rfc4122#section-4.3
- [Field-tested] Lessons 38–41 in `docs/lessons-learned.md`
