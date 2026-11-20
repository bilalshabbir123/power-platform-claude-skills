# azure-web-apps plugin

Custom web apps on Azure for Microsoft 365 organisations, when Power Apps isn't the right fit (for example a field-service PWA that must work with no signal): offline-first sync, low-cost POC hosting, and Entra ID sign-in.

## Skills
- [`pwa-offline-first-sync`](skills/pwa-offline-first-sync/)
- [`azure-low-cost-poc-hosting`](skills/azure-low-cost-poc-hosting/)
- [`entra-id-msal-pwa-sign-in`](skills/entra-id-msal-pwa-sign-in/)
- [`pwa-client-requirements-clarification-doc`](skills/pwa-client-requirements-clarification-doc/)

## Install

```
/plugin marketplace add bilalshabbir123/power-platform-claude-skills
/plugin install azure-web-apps@power-platform-claude-skills
```

## Test

```bash
claude plugin eval plugins/azure-web-apps --runs 1 --no-publish
```
