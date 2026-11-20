# CLAUDE.md

<!-- Copy to the project root as CLAUDE.md. Keep it under ~200 lines; move long topics to .claude/rules/<topic>.md. -->

## Project overview

One paragraph: what the app is, who uses it, and the main technology (e.g. Power Apps code app, React 19 + Vite, Dataverse).

## Commands

```bash
npm run dev      # local dev server
npm run build    # must pass before every deploy
npm run lint
npm test
```

## Rules (always / never, with the reason)

1. **Never** change production. Deploy and test in the test environment only. (Production is live client data.)
2. **Always** run `npm run build` and the tests before saying a change is done.
3. **Always** commit and push each finished change.
4. Test emails or messages go only to `<your test address>`. (Never contact clients from tests.)

## Architecture (short)

- Where the data access layer lives and how to add a table.
- The one or two non-obvious things that break if you don't know them.

## Topic files

- `.claude/rules/deployment.md` — build and publish steps.
- `.claude/rules/handover.md` — current status and next steps; update at the end of each session.

## How I like replies

Short, plain English, numbered steps. Explain any command I must run myself.
