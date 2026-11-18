# Testing skills

Skills are tested two ways: **static checks** (structure, manifests, privacy) and **evals** (does Claude answer better *with* the skill than without it?).

## 1. Static checks
```bash
scripts/check.sh            # every plugin listed, README present, ≥2 eval cases, name = folder,
                            # description ≤ 1,024 chars, SKILL.md ≤ 500 lines, required sections,
                            # no GUIDs / emails / real org URLs
claude plugin validate .    # marketplace and plugin manifests (Claude Code CLI)
```
`scripts/check.sh` also runs in GitHub Actions on every push and pull request (`.github/workflows/check.yml`).

## 2. Evals (`claude plugin eval`)
Each plugin has `evals/<case>/`:
```
evals/<case>/
  prompt.md            # frontmatter (max_turns, allowed_tools) + a realistic user request
  graders/point-1.md   # frontmatter (type: llm, weight) + ONE checkable statement
  graders/point-2.md
```
Run:
```bash
claude plugin eval plugins/<technology> --runs 1 --no-publish          # quick
claude plugin eval plugins/<technology> --runs 3 -j 3 --no-publish     # before a release
claude plugin eval plugins/<technology> --case <case-name> --runs 1    # one case
```
By default each case runs **with** the plugin and **without** it (a baseline) and reports the difference (Δ). A useful skill scores higher with than without; a case where both score 1.00 is too easy — make it about something only the skill knows (a field-tested fact, a current limit, a house rule).

Results go to `plugins/<technology>/evals/results/` (git-ignored) with an HTML report.

## Writing good graders (lessons from this repo)
1. **One statement per grader file.** A single grader that bundled four points failed every run, even for correct answers; split into one statement each, the same answers passed.
2. Write the statement as `The response <does X>.` — observable in the answer text.
3. Grade the **main** points only. Optional extras ("bonus") in a grader make the judge fail good answers.
4. Ask for an explanation when the eval has no project files (`allowed_tools: [Read, Glob, Grep, Skill]` can't build anything).
5. Test with at least one case where the baseline is wrong — that's where the skill earns its place.

## 3. Trigger check (does the right skill load?)
Ask Claude Code a realistic request in a scratch project and check which skill it used (the transcript shows the Skill tool call). If a skill doesn't load when it should, make its `description` more specific about the words people use and the situations it covers; if it loads when it shouldn't, add what it is *not* for.

## Sources
- `claude plugin eval --help` and `claude plugin validate --help` (Claude Code CLI)
- Anthropic's public skills repository (`anthropics/skills`): skill structure, progressive disclosure, keeping `SKILL.md` under ~500 lines, and the skill-creator eval workflow (with-skill vs baseline runs, graded expectations)
