---
name: power-apps-code-app-dataverse-data-access
description: Read and write Dataverse correctly from a Power Apps code app using the generated data client (getClient, retrieveMultipleRecordsAsync, createRecordAsync, updateRecordAsync). Use when lists stop at 500 rows or totals look too low, saves fail with "property does not exist", text gets cut off, OData filters break on apostrophes, users double-submit, writes need rollback, or the app hits 429 throttling.
---

# Dataverse data access from a code app

## Purpose
- **What it does:** a data-access layer pattern for code apps: complete paging, safe filters, writes that survive schema differences between environments, optimistic updates with rollback, and request budgeting.
- **When to use it:** building or reviewing any service that reads or writes Dataverse from a code app; diagnosing wrong totals, lost saves or throttling.
- **Expected outcome:** lists are complete, saves either land fully or fail visibly, user input can't break or inject into queries, and the app stays well inside service protection limits.

## Expertise
- **Architects** keep all Dataverse calls behind one small module (`dataverse.ts`) so paging, retries and error shapes are solved once.
- **Developers** never trust a default page size, always `$select` columns, and treat every write result as `success | error` — never as truthy.
- **Dataverse specialists** check column metadata (type, MaxLength) before writing and model text length on purpose (String up to 4,000; Multiline up to 1,048,576 characters).
- **MVP practice:** prove paging with a deliberately tiny page size in a test environment before shipping — truncation is silent.

## Instructions

### Design approach
1. **One access module** with `list`, `listPage`, `get`, `create`, `update`, `remove`, all returning `{ success, data, error }`.
2. **Filter on the server** (`$filter`) and fetch only needed columns (`$select`). Code apps don't have canvas-style *delegation*; the equivalent risk is pulling whole tables into the browser.
3. **Lookups:** if your client version can't `$expand`, load the related table once (only the columns you need) and join in memory by ID — never one request per row (N+1).
4. **Lowercase schema names for anything used as a lookup.** **[Field-tested]** The code-app data bridge sends lookup binds using the lowercase logical name (`cr123_projectid@odata.bind`). Columns created with a mixed-case SchemaName (`cr123_ProjectId`) failed on create/update with error `0x80048d19`. Create tables and columns with SchemaName equal to LogicalName (all lowercase) from day one; renaming later is not possible.
5. **Choice values are a contract.** When a script generates option values from a list (`787530000 + index`), only ever append options. Inserting or reordering silently changes the meaning of every existing row.
6. **Large or computed data** (totals across tens of thousands of rows, AI summaries) belongs in a flow, a Dataverse custom API, or a rollup/calculated column — not in the browser.

### Development standards

**Paging — follow `skipToken`, never `$top` for multi-page loads.**
**[Field-tested]** The `@microsoft/power-apps` client sends `Prefer: odata.maxpagesize=500` by default, and returns a `skipToken` for the next page. Sending `$top` makes Dataverse return no next-page link. Either way, a list silently stops at one page. In our case project hours showed 49.6 instead of 452.5.
```ts
import { getClient } from '@microsoft/power-apps/data';
import { dataSourcesInfo } from '../../.power/schemas/appschemas/dataSourcesInfo';
const client = getClient(dataSourcesInfo);
const MAX_PAGE = 5000; // Dataverse ceiling for odata.maxpagesize [Microsoft]

export async function listAll<T>(table: string, q: { select: string[]; filter?: string; orderBy?: string[] }, limit = Infinity): Promise<T[]> {
  const rows: T[] = [];
  let skipToken: string | undefined;
  for (let page = 0; page < 100 && rows.length < limit; page++) {
    const res = await client.retrieveMultipleRecordsAsync<T>(table, {
      select: q.select, filter: q.filter, orderBy: q.orderBy,
      maxPageSize: Math.min(MAX_PAGE, limit - rows.length), skipToken,
    });
    if (!res.success) throw new Error(res.error?.message ?? `Failed to read ${table}`);
    rows.push(...(res.data ?? []));
    if (!res.skipToken) break;
    skipToken = res.skipToken;
  }
  return rows.slice(0, limit);
}
```
Re-check this against your SDK version: open the client's Dataverse executor in `node_modules/@microsoft/power-apps/dist/…` and look for `maxPageSize`.

**Filters — escape user text.** OData string literals escape `'` as `''`. Without it, `O'Neil` breaks the query, and crafted text can change the filter.
```ts
export const odataString = (s: string) => `'${s.replace(/'/g, "''")}'`;
const filter = `contains(cr123_assignedto, ${odataString(name)}) and statecode eq 0`;
```
`contains()` is a substring match: "Jo" matches "Joanna". Use it to narrow the query, then compare exact names in code (split multi-value text on `;` / `,`, trim, compare case-insensitively).

**Values parsed from text** (an ID in an email subject, a URL parameter): validate before putting them in a filter or a URL — e.g. a GUID must match `/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i`.

**Writes — schema can differ between environments.** A new column exists in DEV before the solution reaches TEST/PROD, and Dataverse rejects the **whole** write if one property doesn't exist. Retry by dropping **only the column the error names**:
```ts
export async function writeDroppingMissing(payload: Record<string, unknown>, write: (p: Record<string, unknown>) => Promise<{ success: boolean; error?: string | null }>) {
  let current = payload;
  let res = await write(current);
  for (let i = 0; !res.success && i < 5; i++) {
    const err = (res.error ?? '').toLowerCase();
    const missing = Object.keys(current).find(k => err.includes(`'${k.toLowerCase()}'`) || err.includes(`"${k.toLowerCase()}"`));
    if (!missing) break;
    console.warn(`Column ${missing} not in this environment; saved without it`);
    const { [missing]: _drop, ...rest } = current; current = rest;
    res = await write(current);
  }
  return res;
}
```
**[Field-tested]** A retry that stripped a *fixed list* of "new" columns hid a bug: one unrelated invalid column made every save drop all the new fields, and nobody noticed until production.

**Text length.** Before writing user or email text, know the column's MaxLength and cut to it (leave room for suffixes). Read it from metadata:
`GET /api/data/v9.2/EntityDefinitions(LogicalName='cr123_task')/Attributes(LogicalName='cr123_comments')/Microsoft.Dynamics.CRM.MemoAttributeMetadata?$select=MaxLength`
If users will append history (comments, logs) to one column, make it a Multiline column with a high MaxLength up front, or store each entry as its own row.

**Read-modify-write on shared JSON columns** (comments, checklists stored as JSON): re-read the row immediately before saving and merge, so two users don't overwrite each other.

**Optimistic updates.** Update the UI first, then write; on failure **undo exactly that change** and show the error. Callers must check `result.success`, not `if (result)`.

**Double submit.** Disabling the button isn't enough (Enter key, key repeat, fast double click). Keep an in-flight ref per form and ignore repeats; for "create", reuse an identical in-flight request for a few seconds.

**Find-or-create from two events at once.** **[Field-tested]** A note's blur and a checkbox tick saved the same daily check-in in the same moment. Each callback held a stale list, found no row and created one: twin rows. A per-form ref doesn't help when two components race. Keep a module-level map of in-flight creates keyed by the natural key and await it:
```ts
const inFlight = new Map<string, Promise<string>>(); // key -> id
export async function findOrCreate(key: string, find: () => string | undefined, create: () => Promise<string>) {
  const existing = find(); if (existing) return existing;
  const pending = inFlight.get(key); if (pending) return pending;
  const p = create().finally(() => inFlight.delete(key));
  inFlight.set(key, p); return p;
}
```

**Shared client cache returns copies.** **[Field-tested]** A page called `.sort()` on an array from the shared store and reordered lists on other pages. Return copies (or freeze) from the store; sort with `[...rows].sort()` / `toSorted()`.

**Dates.** Dataverse date-time values are UTC. Decide per column whether it's *date only* or *date and time*, convert to the user's local day for "today/this week" logic, store wall-clock values such as "routine at 07:00" as *time-zone independent* or as `HH:mm` text (**[Field-tested]** UTC-converted times showed an hour late after the clocks changed to summer time), and never act on a native `<input type="date">` `onChange` that links or saves other fields — act on blur (typing passes through years like `0002`).

### Governance and DLP
- The native Dataverse data source is the preferred path; connector-based sources (SharePoint, SQL) are subject to DLP classification — keep them in the same business group as Dataverse.
- Don't build a generic "query anything" helper exposed to user input; whitelist tables and columns.

### Security
- **Client-side filters are not security.** Any user can call Dataverse with their own token. What a user may read or write is decided by **security roles** (see `dataverse-security-roles-for-code-apps`).
- Escape and validate every value that goes into `$filter`.
- Don't log full records containing personal data to the console in production builds.

### Performance
- **Service protection limits** (per user, per web server, 5-minute sliding window) **[Microsoft]**: 6,000 requests; 20 minutes combined execution time; 52 concurrent requests. Exceeding returns **429** with `Retry-After`. Cap parallel requests (e.g. 4–6 at a time), and back off on 429.
- **Power Platform request entitlements (24 h)** **[Microsoft]**: 40,000 per user for Power Apps Premium / per-user licences; 6,000 for per-app, Microsoft 365-seeded and pay-as-you-go users. A home page that fires 30 requests per load × many reloads adds up.
- Load each table once per page/session and share it through React context or a cache; refresh on demand.
- Always `$select`; `$orderby` on indexed columns; avoid `contains()` on very large tables where `eq` or `startswith()` will do.
- Batch bulk writes (Web API `$batch`, max 1,000 operations per batch) or move them to a flow.

### ALM
- Table and column changes go in the **same solution** as the app. Add columns to DEV, add them to the solution, and only then rely on them in code (with the dropping-retry as a safety net during rollout).
- After `pa app add data-source` / `refresh data-source`, commit the generated schema and services together with the code that uses them.
- **Schema as code.** `pac` can't create Dataverse tables or columns **[Field-tested]**. Keep the schema in one script that calls the Web API idempotently (create only what is missing, add the component to the solution) and generates the TypeScript types from the same definition, so code and tables never drift.

### Licensing
- Using Dataverse makes the app **premium** **[Microsoft]**: every user needs Power Apps Premium (or per-app / PAYG / App Pass), which also sets their request entitlement.

## Examples

### Beginner — read active rows with only the needed columns
```ts
const tasks = await listAll<{ cr123_taskid: string; cr123_title: string; cr123_duedate: string | null }>(
  'cr123_tasks',
  { select: ['cr123_taskid', 'cr123_title', 'cr123_duedate'], filter: 'statecode eq 0', orderBy: ['cr123_duedate asc'] },
);
```

### Intermediate — "my items" filter from user input, exact-match after narrowing
```ts
const name = currentUser.fullName;                     // e.g. "Ciara O'Neil"
const rows = await listAll<Task>('cr123_tasks', {
  select: ['cr123_taskid', 'cr123_title', 'cr123_assignedto'],
  filter: `contains(cr123_assignedto, ${odataString(name)})`,
});
const norm = (s: string) => s.trim().toLowerCase();
const mine = rows.filter(r => (r.cr123_assignedto ?? '').split(/[;,]/).some(p => norm(p) === norm(name)));
```

### Advanced (enterprise) — resilient save with rollback, double-submit guard and rollout-safe columns
```ts
const saving = useRef(false);
async function save(task: Task, changes: Partial<Task>) {
  if (saving.current) return;            // Enter + click, key repeat
  saving.current = true;
  const before = task;
  setTasks(ts => ts.map(t => t.id === task.id ? { ...t, ...changes } : t));   // optimistic
  const payload = toDataverse(changes);   // only changed fields
  const res = await writeDroppingMissing(payload, p => client.updateRecordAsync('cr123_tasks', task.id, p));
  if (!res.success) {
    setTasks(ts => ts.map(t => t.id === task.id ? before : t));               // exact undo
    toast.error(`Not saved: ${res.error}`);
  }
  saving.current = false;
}
```
Prove it in TEST: save, refresh the page, and read the row back from Dataverse (not from React state).

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Trusting the default page size / sending `$top` | Lists and totals silently capped (500 rows) | Follow `skipToken`; test with `maxPageSize: 10` |
| Building `$filter` with raw text | Breaks on `'`; filter injection | `odataString()`; validate parsed IDs |
| `contains()` as the final match | "Jo" sees "Joanna"'s items | Narrow with `contains`, confirm with exact compare |
| Stripping a fixed list of columns on any save error | New fields silently never saved | Drop only the column the error names, and log it |
| Writing longer text than the column allows | Save/flow fails only for long input | Read MaxLength; cut; size columns for growth |
| Treating a result object as success | Errors look like saves | Check `success`; roll back on failure |
| Disabled button as the only double-submit guard | Duplicate rows | In-flight ref; reuse in-flight create |
| One request per row for lookups | Slow pages, 429s | Load related table once and join |
| Acting on date `onChange` | Dates like 0002-11-12 saved | Act on blur; validate year |
| Client-side filtering as "security" | Data readable via API | Security roles |

## Validation checklist

### Security
- [ ] Every `$filter` value escaped or validated
- [ ] No access decision relies only on client-side code
- [ ] No personal data logged in production

### Performance
- [ ] Every query has `$select`
- [ ] Paging proven with a small page size; totals match a server count
- [ ] Parallel requests capped; 429 handled with `Retry-After`
- [ ] No N+1 lookups

### ALM
- [ ] New columns are in the solution before code depends on them
- [ ] Generated schema/services committed with the code

### Solution packaging
- [ ] All tables/columns used by the app are in the solution with correct MaxLength
- [ ] Environment-specific values (URLs, IDs) come from environment variables, not code

### Deployment readiness
- [ ] Every changed form: save → refresh → value still there → read back from Dataverse
- [ ] Long-text, apostrophe and empty-value cases tested
- [ ] Failure path tested (bad value → error shown, UI rolled back)

## Troubleshooting
| Symptom | Likely cause | Fix |
|---|---|---|
| Totals or lists too low | Paging stopped at the default 500 rows; `$top` used | `listAll` helper that follows `skipToken`; compare with a server-side count |
| Save says OK but the field is empty after refresh | Retry stripped "unknown" columns; column missing in this environment | Read back after save in tests; retry only for the column the error names |
| Save fails only for long text | Text longer than the column MaxLength | Read MaxLength from metadata; trim or raise the column limit |
| Search breaks on names like O'Brien | Unescaped quote in an OData literal | `odataString()` helper doubles single quotes |
| Search for "Jo" also matches "Joanna" | `contains()` used where an exact match was meant | Exact compare after the server filter |
| Two records from one click | No double-submit guard | `useRef` in-flight flag + disabled button |
| Create/update with a lookup fails with `0x80048d19` | Mixed-case SchemaName; bridge binds with the lowercase name | Create schema names in lowercase (SchemaName = LogicalName) |
| Twin rows for the same day/item | Two events ran find-or-create at once with stale state | Module-level in-flight map keyed by the natural key |
| Lists on another page change order | In-place `.sort()` on a shared store array | Store returns copies; sort a copy |
| 429 errors during bulk work | Service protection limits | Respect `Retry-After`, batch, reduce parallel calls |

Not sure which product applies? Start with the `power-platform-solution-builder` hub skill.

## References
- [Microsoft] [Service protection API limits](https://learn.microsoft.com/power-apps/developer/data-platform/api-limits)
- [Microsoft] [Requests limits and allocations](https://learn.microsoft.com/power-platform/admin/api-request-limits-allocations)
- [Microsoft] [Query data using the Web API (paging, $select, $filter)](https://learn.microsoft.com/power-apps/developer/data-platform/webapi/query-data-web-api)
- [Microsoft] [Code apps: connect to data](https://learn.microsoft.com/power-apps/developer/code-apps/how-to/connect-to-data)
