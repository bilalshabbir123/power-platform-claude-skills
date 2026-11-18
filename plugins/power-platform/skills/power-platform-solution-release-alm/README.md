# power-platform-solution-release-alm

**Problem it solves:** production releases of a code app and its flows that ship untested changes, carry DEV environment variable values, flip flow on/off states, or can't be verified afterwards.

**Use it when:** preparing or importing a managed solution, deciding if a release is ready, or checking production after an import.

**What's inside (`SKILL.md`):**
- DEV/TEST/PROD strategy with managed solutions; prod read-only for builders
- The release checklist where untested = blocker
- Export, zip inspection, env var definitions without values
- Flow-state snapshot and post-import read-only verification
- Pipeline example, mistakes table, checklist

**Related skills:** `power-apps-code-app-deployment`, `power-automate-dataverse-triggered-flows`, `dataverse-security-roles-for-code-apps`
