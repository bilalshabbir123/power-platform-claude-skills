# dataverse-security-roles-for-code-apps

**Problem it solves:** code apps that hide things in the UI but leave the data open through the API, users who can promote themselves through the app's own role table, and role scripts that silently fail.

**Use it when:** designing roles before go-live, adding a table, building admin screens, or answering "what can a normal user actually do?".

**What's inside (`SKILL.md`):**
- In-app roles vs Dataverse roles; a table × role privilege matrix
- Write-protecting permission tables; column security; keeping the base role
- Converging role scripts (`AddPrivilegesRole` / `RemovePrivilegeRole` payloads that work), status assertions
- Non-admin API test plan
- Mistakes table and checklist

**Related skills:** `power-apps-code-app-dataverse-data-access`, `power-platform-solution-release-alm`
