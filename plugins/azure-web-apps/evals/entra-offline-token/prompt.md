---
max_turns: 10
allowed_tools: [Read, Glob, Grep, Skill]
---

Our React PWA uses MSAL with Entra ID. Surveyors work offline all day. When they come back online the token has expired and acquireTokenSilent throws InteractionRequiredAuthError. What should the app do with the changes they made offline?
