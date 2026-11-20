---
name: pwa-client-requirements-clarification-doc
description: Turn discovery-call and demo transcripts into a client-ready "roles, screens and features" clarification document for a business web app or PWA — journey of a job, roles, a screen-by-role access matrix, high-level branded mock screens, features by role, system rules, open questions with your suggested answers, and next steps — before writing the proposal. Use it when someone says "prepare a document for the client listing features per role", "screen vs role matrix", "high-level mock-ups for the proposal", "turn these meeting transcripts into requirements", or "clarification document before the proposal". Not for technical specs or code.
---

# Client requirements clarification document (roles, screens, features)

## Purpose
- **What it does:** a repeatable way to go from meeting transcripts (discovery call, demo) to a short, branded, client-facing document the client can comment on, so the proposal is priced on agreed scope.
- **When to use it:** after a discovery call or demo, before the proposal; when the client must confirm who sees what.
- **Expected outcome:** a .docx (or doc) with clear scope, a screen × role matrix, mock screens, and numbered questions the client can answer in one pass.

## Expertise
- **Consultants** write for the business owner, not developers: plain English, their own words for things ("fitting diary", "sales floor"), no technology jargon.
- **Architects** make every rule enforceable later: each matrix cell maps to a server-side permission, each "rule" to a domain check.
- **Field-tested practice:** a question table with *our suggestion* pre-filled gets answers in days; open-ended questions get none.

## Instructions

### Design approach
1. **Extract from transcripts** (not the AI meeting summary alone — check it against the transcript): current manual process, pain points, what Phase 1 must replace, what was explicitly deferred, roles and head-count, devices, licences, things the client called "essential".
2. **Use the client's list if they gave one** (roles, screens). If something they asked for in the meetings is missing from it (e.g. "price list in the system"), add it as **"(proposed)"** and raise a question — never silently add or drop scope.
3. **Document structure** (keep this order):
   1. Cover (branded) + document table (prepared for/by, purpose, version, date) + "how to review" + "mock-ups are illustrative".
   2. What Phase 1 does: the paperwork it replaces; the journey of a job as a table (stage / what happens / who); **not in Phase 1** list.
   3. Who uses it: roles table (who, main tasks, how they sign in — e.g. subcontractors with their own email, no extra licence).
   4. Screens at a glance: **screen × role matrix** with words **Full / View / Own / —** (colour as a second cue only) + a key.
   5. Screens in detail: one mock per screen, 3–5 bullets, then "By role:".
   6. Features by role: grouped table (feature × role).
   7. Rules the system will follow (numbered, testable).
   8. Questions for you: # / question / our suggestion / your answer.
   9. Next steps (review → call → proposal → walkthrough).

### Development standards — mock screens
- Build mocks as **one HTML file** using the client's brand tokens (colours, fonts, logo on the background it was designed for), one `<section id>` per screen, then screenshot each section with Playwright at `deviceScaleFactor: 2`.
- Desktop frames ~1280×780, tablet ~1100×760, phones side by side for field roles. Show realistic states: offline badge, clash warning, overdue items.
- Label every mock "Illustrative mock-up"; use **fictional** names, postcodes masked (`NN6 7XX`), example prices.
- Keep the generator (HTML, screenshot script, doc builder) next to the deliverable so v0.2 is a quick edit.

### Governance
- Client documents and transcripts are **never committed** to source control; the project repo records only decisions and a pointer to the file.
- Record scope differences against the build brief as "to reconcile after client answers" rather than changing the brief early.

### Security
- No real customer data in mocks. No tenant IDs, URLs or internal hostnames in the document.
- State that access is enforced by the system, not just hidden on screen — and design it that way.

### Performance
- Keep the document short (10–15 pages). One mock per screen; images ~620 px wide on A4.

### ALM
- Version the document (v0.1 draft → v1.0 agreed). Answers to the questions feed the proposal and the backlog.

### Licensing
- Fonts: if the brand fonts aren't standard, use a common font (Arial) in the .docx and let the mock images carry the brand fonts — the client may not have them installed.

## Examples

### Beginner
Client lists 4 roles and 7 screens → matrix 7×4 with Full/View/Own/—, key underneath, one mock per screen.

### Intermediate
Client asked in the demo for "the price list in the system", but it's not in their screen list → add row "Price list (proposed)", note why, and question "Include in Phase 1? Our suggestion: yes, Admin only."

### Advanced (enterprise)
Several transcripts disagree (warehouse in Phase 1 vs Phase 2) → take the latest statement, list the earlier one as a question, and mark the build brief "to reconcile".

## Common mistakes
| Mistake | What happens | How to avoid |
|---|---|---|
| Relying on the AI meeting summary only | Wrong names, invented commitments | Check each point against the transcript |
| Matrix uses colour only | Unreadable printed in black and white; fails accessibility | Words in every cell; colour as a second cue |
| Open questions without a suggestion | Client doesn't answer | Pre-fill "our suggestion" |
| Silently adding requested-but-unlisted screens | Scope dispute later | Mark "(proposed)" and ask |
| Real customer names in mocks | Privacy breach | Fictional data, masked postcodes |
| Brand fonts in the .docx | Odd substitution on the client's PC | Common font in text; brand fonts in images |
| Logo on the wrong background | Logo invisible or off-brand | Use the variant designed for that background |

## Validation checklist

### Security
- [ ] No real customer data, IDs or internal URLs
### Performance
- [ ] 10–15 pages, images readable when printed
### ALM
- [ ] Version and date on the cover; generator saved next to the file
### Solution packaging
- [ ] Every matrix cell maps to a permission the system can enforce
### Deployment readiness
- [ ] Not-in-Phase-1 list present; every deferred item from the meetings appears there
- [ ] Every question has a suggestion and an answer column

## Troubleshooting
| Symptom | Likely cause | Fix |
|---|---|---|
| Screenshots show fallback fonts | Fonts not loaded before capture | `await page.evaluate(() => document.fonts.ready)` |
| Images blurry in Word | 1× capture | `deviceScaleFactor: 2`, insert at ~620 px |
| Client rewrites the whole matrix | Roles unclear | Add a "who uses it" table before the matrix |

## References
- [Vendor docs] Playwright screenshots — https://playwright.dev/docs/screenshots
- [Vendor docs] docx (npm) — https://docx.js.org/
- [Microsoft] Word comments — search "Insert or delete a comment" on support.microsoft.com
- [Field-tested] Lessons 50–51 in `docs/lessons-learned.md`
