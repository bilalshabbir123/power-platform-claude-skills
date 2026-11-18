# power-apps-code-app-business-rules-testing

**Problem it solves:** a code app creates records automatically at the wrong time (e.g. "raise invoice" for an already-invoiced project), creates duplicates after a rename, shows wrong "today/this week" numbers, or has UI bugs that only appear inside the Power Apps player.

**Use it when:** adding "when X changes, create Y" behaviour, fixing a wrong automatic record, or setting up unit tests and a release test plan.

**What's inside (`SKILL.md`):**
- Trigger vs precondition, one shared rule module, idempotency by stable key
- App vs flow/plug-in: where a must-happen rule belongs
- Vitest patterns, break tests, stress tests, date/week rules
- Player pitfalls: overlay z-index, `blob:` images, storage, deep links, date inputs
- Checking a rule against read-only production data before release

**Related skills:** `power-apps-code-app-dataverse-data-access`, `power-automate-dataverse-triggered-flows`
