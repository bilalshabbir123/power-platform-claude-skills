# power-apps-code-app-dataverse-data-access

**Problem it solves:** code app lists that silently stop at 500 rows, saves that fail or lose fields between environments, OData filters that break on apostrophes, duplicate submits, and throttling.

**Use it when:** writing or reviewing the Dataverse service layer of a code app, or when totals look wrong or saves "don't stick".

**What's inside (`SKILL.md`):**
- A complete paging helper (`skipToken`, no `$top`) and how to prove it
- OData escaping, exact-match after `contains()`, GUID validation
- Rollout-safe writes (drop only the missing column), MaxLength checks, read-modify-write
- Optimistic updates with exact rollback and a double-submit guard
- Service protection limits and request entitlements with Microsoft references
- Beginner / intermediate / enterprise examples, mistakes table, checklist

**Related skills:** `dataverse-security-roles-for-code-apps`, `power-apps-code-app-business-rules-testing`
