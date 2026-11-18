# Power Automate cloud flows

Read this for any flow. For Dataverse- or mailbox-triggered flows, hand over to `power-automate-dataverse-triggered-flows` (duplicates, long text, silent stops, connection ownership).

## Design approach
1. **Solution-aware flows only**, with connection references and environment variables.
2. **Narrow triggers:** filter columns + trigger conditions so the flow runs only when needed.
3. **Idempotent:** a re-run (or a duplicate trigger) must not create a second record or send a second message. Use a claim column, alternate key or "find before create", and trigger concurrency = 1 where order matters.
4. **Child flows** for shared logic; keep one flow per business event.
5. **Test-recipient switch:** an env var that redirects every email / Teams message to a tester in DEV/TEST.

## Development standards
- Name: `<App> - <Trigger> - <Action>` (e.g. `Contoso - Request Created - Notify Approver`).
- Structure: `Try` scope → `Catch` scope (run after: failed, timed out) → notify a monitored address with the run URL:
  `concat(workflow()?['tags']?['environmentName'], '/flows/', workflow()?['name'], '/runs/', workflow()?['run']?['name'])`
- Truncate text to the target column length (`substring(x, 0, min(length(x), 1990))` for a 2,000 column).
- Validate IDs before using them in OData filters (GUID pattern).
- Remove **static results** (mocked outputs) before release.

## Governance and DLP
- HTTP, custom connectors and many premium connectors are often blocked by DLP — check per environment.
- Connections owned by a **service account**, not a person.
- "Send as" a shared mailbox needs Send As rights, not just read access **[Field-tested]**.

## Security
- Secure inputs/outputs on actions that handle secrets or personal data (hides them from run history).
- Secrets in Key Vault–backed environment variables, never in the definition.

## Performance and limits **[Microsoft]**
| Limit | Value |
|---|---|
| Outbound synchronous request timeout (e.g. HTTP, custom connector) | 120 seconds |
| Outbound asynchronous request | configurable up to 30 days |
| Inbound request (instant / HTTP-triggered flow response) | 120 seconds |
| Message size | 100 MB (1 GB with chunking) |
| Action burst | 100,000 actions per 5 minutes |
| Custom connector requests | 10,000 per minute per connection |

- Dataverse actions count against the flow owner's Dataverse request limits.
- For long work (e.g. an LLM call that can exceed 120 s) use the asynchronous pattern: start job → `202 Accepted` + `Location` header → poll, or a callback.
- Avoid `Apply to each` over thousands of rows; filter at the source, use `$select`, and use concurrency on loops only when order doesn't matter.

## ALM
- Store exported definitions or generator scripts in Git.
- Snapshot flow on/off states before a managed import and compare after → `power-platform-solution-release-alm`.
- Custom connectors go in a separate solution imported first **[Microsoft]**.

## Testing
- Test every branch, including Catch, with real-shaped data.
- Check **trigger history** as well as run history — a broken trigger shows no failed runs **[Field-tested]**.

## References
- [Microsoft] [Limits and configuration](https://learn.microsoft.com/power-automate/limits-and-config)
- [Microsoft] [Understand platform limits](https://learn.microsoft.com/power-automate/guidance/coding-guidelines/understand-limits)
- [Microsoft] [Custom connector FAQ (limits)](https://learn.microsoft.com/connectors/custom-connectors/faq)
