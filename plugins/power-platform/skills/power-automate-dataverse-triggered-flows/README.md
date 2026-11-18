# power-automate-dataverse-triggered-flows

**Problem it solves:** flows behind a code app that create duplicates, loop, fail only for long emails, silently stop picking up mail, can't be switched on because of mixed connection owners, or send test messages to real people.

**Use it when:** building or changing a Dataverse- or mailbox-triggered flow, or diagnosing missing, failed or duplicated runs.

**What's inside (`SKILL.md`):**
- Narrow triggers, no self-loops, concurrency-safe create-if-missing (alternate key, concurrency 1, claim)
- Text length, GUID validation, lookup binding, reply matching for support mailboxes
- Mandatory test mode (test-recipient and live-switch environment variables)
- Connection ownership, shared-mailbox send rights, trigger-history monitoring
- Request limits, ALM for env vars, programmatic edit safety
- Beginner / intermediate / enterprise examples, mistakes, checklist

**Related skills:** `power-platform-solution-release-alm`, `power-apps-code-app-business-rules-testing`
