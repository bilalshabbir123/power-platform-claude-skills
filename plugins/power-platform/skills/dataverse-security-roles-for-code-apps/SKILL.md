---
name: dataverse-security-roles-for-code-apps
description: Design, script and test Dataverse security roles for a Power Apps code app so access is enforced on the server, not just hidden in the UI. Use when creating Manager / Team Member style roles, when the app reads its own "role assignment" or permissions table, when scripting roles with AddPrivilegesRole / RemovePrivilegeRole, or when asked "can a normal user see or change this?".
---

# Dataverse security roles for a code app

## Purpose
- **What it does:** a least-privilege role design for code apps, a scriptable and repeatable way to create roles in a solution, and the tests that prove what a normal user can and can't do.
- **When to use it:** before a code app goes to real users; when adding a table; when the app has its own in-app roles or admin screens.
- **Expected outcome:** every table has an intended privilege per role, no user can raise their own access, scripts are re-runnable (they add *and* remove privileges), and the design is verified with a non-admin account.

## Expertise
- **Architects** separate two things: *in-app roles* (what screens/buttons appear — convenience) and *Dataverse security roles* (what the API allows — security). The second must hold even if the first is bypassed.
- **Developers** never trust data the user can write to make permission decisions.
- **Dataverse specialists** set privilege **depth** deliberately: Basic (own records), Local (business unit), Deep (BU and children), Global (organisation).
- **MVP practice:** test as a real non-admin user. System Administrators bypass privileges, so admin testing proves nothing.

## Instructions

### Design approach
1. **List tables × roles × verbs** (Create, Read, Write, Delete, Append, AppendTo, Assign, Share) in a matrix before building. Typical code app:
   | Table type | Team Member | Manager |
   |---|---|---|
   | Work tables (tasks, time entries, tickets) | Read Global, Create/Write Global (or Basic), Delete Basic | Full Global |
   | Reference/config (templates, routing rules, settings) | Read Global | Full Global |
   | People / employees | Read Global | Full Global |
   | **Permission tables** (role assignments, app permissions) | **Read only** | Full Global |
2. **Permission tables are write-protected.** If the app decides "admin" from a row in a table, a user who can create or edit rows in that table can make themselves admin.
   **[Field-tested]** A Team Member role had Create on the app's role-assignment table "for self-registration". Any user could add a row `{own email, Admin}` and the app trusted it. Create was removed; admins add people from an admin screen.
3. **Keep the platform's base role.** Assign custom roles **in addition to** *Basic User* (or your org's base role) so standard tables and app access work.
4. **Money and sensitive fields:** use **column security profiles** rather than hiding fields in the UI.
5. **App access ≠ data access.** Sharing the code app lets a user open it; the security role decides the data. Share the app with the same security groups that receive the roles.

### Development standards
- Create roles **in the solution** (`MSCRM.SolutionUniqueName` header on create) so they move with the app.
- Look privileges up by name (`prv<Verb><table logical name>`) and check `canbebasic` / `canbeglobal` before choosing depth.
- **Scripts must converge:** read current privileges (`RetrieveRolePrivilegesRole`), add what's missing, **remove what's not in the spec**, then re-read and compare.
- **Check every HTTP status the script prints**, not just the last line. **[Field-tested]** A role script's "remove" step sent the wrong parameter and returned 400 on every call for weeks; nobody noticed because the script carried on.
- Web API payloads (check against `$metadata` for your org version):
  ```http
  POST roles(<roleid>)/Microsoft.Dynamics.CRM.AddPrivilegesRole
  { "Privileges": [ { "PrivilegeId": "<guid>", "Depth": "Global", "BusinessUnitId": "<root-bu-guid>" } ] }

  POST roles(<roleid>)/Microsoft.Dynamics.CRM.RemovePrivilegeRole
  { "Privilege": { "@odata.type": "Microsoft.Dynamics.CRM.privilege", "privilegeid": "<guid>" } }
  ```
  **[Field-tested]** `RemovePrivilegeRole` with `{ "PrivilegeId": … }` returned 400 on our org; the `$metadata` parameter was `Privilege` (an entity reference). Confirm with `GET $metadata` and search for `RemovePrivilegeRole`.

### Governance
- Role changes are change-controlled: matrix in Git, script in Git, roles in the solution, reviewed per release.
- Owner of role assignment in production is named (e.g. the platform admin), and periodic access reviews are scheduled.
- Avoid giving makers/customizer roles (System Customizer) to end users; it bypasses your design.

### Security
- Server-side enforcement: every check the UI does (e.g. "only managers see invoicing") must also be true at role level, or the data is readable through the API with the user's token.
- Global **Read** on a table means every user can read every row through the API. If that's not acceptable, use Basic/Local depth, business units, teams, or column security.
- Don't use the app's in-app role for anything security-relevant unless its table is write-protected as above.
- Conditional Access and app sharing limits apply to code apps **[Microsoft]**; combine them with roles, they don't replace them.

### Performance
- Prefer **teams** (Entra security-group teams) for role assignment at scale: one assignment per group instead of per user.
- Deep business-unit hierarchies and many sharing records slow queries; keep the model simple.

### ALM
- Roles ship in the managed solution. Role **assignments** are per environment (not in the solution): document who gets which role after import.
- Re-running the role script in DEV after a change, then exporting, keeps PROD in step.

### Licensing
- Roles don't change licensing, but every user who opens the code app needs a premium entitlement **[Microsoft]**.

## Examples

### Beginner — create a role in the solution
```http
POST roles
MSCRM.SolutionUniqueName: ContosoRequests
{ "name": "Contoso Requests - Team Member", "businessunitid@odata.bind": "/businessunits(<root-bu-guid>)" }
```

### Intermediate — converge a role to a spec (Python sketch)
```python
spec = {"cr123_task": {"Create": "Global", "Read": "Global", "Write": "Global", "Delete": "Basic"},
        "cr123_roleassignment": {"Read": "Global"}}          # no Create/Write: no self-promotion
current = get(f"RetrieveRolePrivilegesRole(RoleId={rid})")["RolePrivileges"]
wanted = build_privileges(spec)                              # name -> {PrivilegeId, Depth, BusinessUnitId}
for p in current:
    if p["PrivilegeId"] not in {w["PrivilegeId"] for w in wanted} and is_app_table(p):
        status = post(f"roles({rid})/Microsoft.Dynamics.CRM.RemovePrivilegeRole",
                      {"Privilege": {"@odata.type": "Microsoft.Dynamics.CRM.privilege", "privilegeid": p["PrivilegeId"]}})
        assert status in (200, 204), status                  # never ignore a failed remove
status = post(f"roles({rid})/Microsoft.Dynamics.CRM.AddPrivilegesRole", {"Privileges": wanted})
assert status in (200, 204), status
```

### Advanced (enterprise) — prove the design with a non-admin user
1. Test user with only *Basic User* + *Team Member*, a Power Apps Premium licence, and the app shared through a security group.
2. In the app: every screen loads; restricted screens are hidden.
3. With the user's token (Web API or browser dev tools): `POST cr123_roleassignments` → **403**; `PATCH` a role row → **403**; `DELETE` another user's time entry → **403**; read of a column-secured field → empty.
4. Record the results in the release notes. Repeat for the Manager role.

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| UI hiding as the only control | Data readable/changeable through the API | Enforce in roles; test with API calls |
| Users can create/edit permission rows | Self-promotion to admin | Read-only for permission tables |
| Testing as System Administrator | Everything "works" | Test as a non-admin user |
| Script only adds privileges | Old rights never removed | Converge: add + remove + re-read |
| Ignoring HTTP status in scripts | Silent failures for weeks | Assert every status |
| Wrong parameter shape for RemovePrivilegeRole | 400 every time | Check `$metadata` |
| Replacing Basic User with the custom role | Users can't open standard tables/app | Assign in addition to the base role |
| Giving end users System Customizer | Bypasses the design | Custom least-privilege roles only |

## Validation checklist

### Security
- [ ] Privilege matrix reviewed; permission tables read-only for non-managers
- [ ] Non-admin API tests return 403 where expected
- [ ] Sensitive columns protected by column security

### Performance
- [ ] Roles assigned through group teams where users are many
- [ ] No unnecessary deep BU hierarchy or mass sharing

### ALM
- [ ] Matrix and script in Git; script converges and asserts statuses
- [ ] Assignment list for each environment documented

### Solution packaging
- [ ] Roles are in the solution; every app table is covered by each role

### Deployment readiness
- [ ] Non-admin test done for each role
- [ ] Post-import: assign roles (keep base role), share app with the same groups

## References
- [Microsoft] [Security concepts in Dataverse](https://learn.microsoft.com/power-platform/admin/wp-security-cds)
- [Microsoft] [Security roles and privileges](https://learn.microsoft.com/power-platform/admin/security-roles-privileges)
- [Microsoft] [Column-level security](https://learn.microsoft.com/power-platform/admin/field-level-security)
- [Microsoft] [Code apps — managed platform capabilities](https://learn.microsoft.com/power-apps/developer/code-apps/overview#managed-platform-capability-support)
