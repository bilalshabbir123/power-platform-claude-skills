# power-platform plugin

Power Apps code apps, canvas apps, Power Automate, Dataverse security and solution ALM, plus a hub skill that routes any Power Platform / Microsoft 365 request to the right technology.

## Skills
- [`dataverse-security-roles-for-code-apps`](skills/dataverse-security-roles-for-code-apps/)
- [`power-apps-code-app-business-rules-testing`](skills/power-apps-code-app-business-rules-testing/)
- [`power-apps-code-app-dataverse-data-access`](skills/power-apps-code-app-dataverse-data-access/)
- [`power-apps-code-app-deployment`](skills/power-apps-code-app-deployment/)
- [`power-automate-dataverse-triggered-flows`](skills/power-automate-dataverse-triggered-flows/)
- [`power-platform-solution-builder`](skills/power-platform-solution-builder/)
- [`power-platform-solution-release-alm`](skills/power-platform-solution-release-alm/)

## Install

```
/plugin marketplace add bilalshabbir123/power-platform-claude-skills
/plugin install power-platform@power-platform-claude-skills
```

## Test

```bash
claude plugin eval plugins/power-platform --runs 1 --no-publish
```
