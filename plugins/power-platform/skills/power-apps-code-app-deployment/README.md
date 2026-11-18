# power-apps-code-app-deployment

**Problem it solves:** a code app publish "succeeds" but users don't see the change, the CLI signs in as the wrong account, or a production app gets changed directly.

**Use it when:** publishing a code app, setting up an environment for code apps, or writing a CI/service-principal deploy.

**What's inside (`SKILL.md`):**
- The fixed build → verify → commit → publish order, and why the publish doesn't rebuild
- The CLI generations (`pa app push`, `power-apps push`, `pac code push`)
- Account checks, service-principal publishing, public-asset security, Conditional Access
- Beginner / intermediate / enterprise examples, including a deploy script that refuses a stale build
- Common mistakes and a validation checklist

**Related skills:** `power-platform-solution-release-alm`, `power-apps-code-app-dataverse-data-access`
