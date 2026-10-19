# Skill feedback: haiku-delegate, fix-bug-and-release dry run

Overall, this scenario fits the skill closely. SKILL.md line 29 spells out the "fix this bug and release it" split, and Example 4 in brief-template.md is nearly this exact job. Brief 01 is mostly Example 4 with the real values filled in. The gaps below are the places where I had to guess or add something.

## Unclear, or in conflict

1. **Install check: delegate it or run it myself?**
   - SKILL.md says "one or two quick commands are cheaper to run yourself".
   - The install check for a zero-dependency library is five quick commands with about ten lines of output. Example 4's context says a separate install-check brief runs after `npm view`.
   - The gap between "one or two" and "five, all quick" is undefined. A cold-start Haiku agent plus a full brief (~2.5k tokens of fixed sections) for a check that adds one package is close to break-even at best.
   - I followed Example 4 and delegated it, but a careful model could reasonably go the other way. Suggestion: state the rule by cost rather than by count. For example: delegate when there's a wait (CI, propagation), a batch, or more than about 30 lines of output you don't need; otherwise run it yourself.

2. **`run_in_background` when nothing else can happen.**
   - SKILL.md says run in the background by default. The Agent tool's own description says to use `false` when the next action depends on the result and nothing else could usefully happen.
   - Brief 01 is exactly that case: I have no main-model work left while it runs, and brief 02 is already written.
   - I kept `true` so the user can interject during a multi-minute CI watch. The skill should say which rule wins, or say why the background is preferred even then.

3. **Closing keyword: avoid it or ask?** SKILL.md says "change the plan to avoid it ... or ask" with no tie-breaker. Here the user plausibly does want #41 closed once it's fixed. I chose to avoid it (`(#41)`) and put "close #41 if you want" under **Needs you**, because asking would block the release on a cosmetic question. Suggested default: avoid the side effect, then list it under Needs you; ask up front only when avoiding it would change what ships.

## Missing

4. **Install check for a library with no bin.**
   - Example 3 and the verify table ("accept the agent's `--version` output") assume a CLI. `@quillkit/slug` has no `bin`.
   - I wrote a `node -e "require(...)"` smoke test whose exact expected output I first confirmed locally against `./src/index.js`.
   - Add a library variant to Example 3, and have the verify-table row say "the agent's quoted smoke-test output" rather than `--version`.

5. **Where "origin/main before this job" comes from.**
   - Example 4 pins `origin/main before this job`, but nothing says how to get that value.
   - In this repo there is no `origin/main` remote-tracking ref (`git branch -a` lists only `main`), so `git rev-parse origin/main` would fail. The only source is `git ls-remote origin refs/heads/main`, which is a network call.
   - Add `git ls-remote origin refs/heads/main refs/tags/<tag>` to the "Check the pipeline before the tag goes out" preflight list. It also catches a moved main before the brief is written around a stale SHA.

6. **No "version not already on npm" check before the tag push in the CI-publish flow.**
   - Example 1 checks `npm view <pkg>@<ver>` before the irreversible step. Example 4 doesn't, even though "Make steps safe to rerun ... check before the irreversible step" applies just as much there: a tag push for an already-published version gives a public tag and a failed run.
   - I added it to brief 01 (step 4) and to preflight (P5). Example 4 should have it, or the text should say preflight covers it.

7. **`npm trust list` output format.** The preflight tells me to confirm that `npm trust list <pkg>` "lists this repo and workflow file", but nothing says what the output looks like. I couldn't write an exact Expect line for P1, only "an entry with repository X and workflow Y". One sample output in the skill would help.

8. **Annotated vs lightweight tag in verification.** The verify table's tag row (`gh api .../commits/<tag> --jq .sha`) peels to the commit, so it can't tell my annotated tag from a lightweight tag that someone else pushed with the same name. I added `gh api repos/<o>/<r>/git/ref/tags/<tag> --jq '.object.type + " " + .object.sha'` to check for `tag <tag-object-sha>`. That's worth adding to the table, since the briefs already pin the tag object SHA.

9. **Non-ASCII in commands on Windows.** Nothing warns that accented characters in a `node -e` argument can be mangled between Git Bash and node.exe. I used `è`-style escapes inside the JS string and told the agent to copy them as written. A line under "Name the shell, and write for it" would help.

10. **CRLF noise on Windows.** This repo has `core.autocrlf=true`, so every `git add`/`git diff` prints `warning: in the working copy of '...', LF will be replaced by CRLF`. Under "Mark expected errors and benign noise", a Haiku agent told to stop on "anything unexpected" could treat that as a reason to stop. I marked it as harmless in brief 01 step 1. The template's benign-noise section could name it, since it shows up on most Windows machines.

11. **Push output format in Expect lines.** Example 4 expects `a83f0c6..c41e9a0  main -> main` with two spaces, and a literal-minded agent may compare whitespace. I wrote "a line containing both `7d0bf66..234cf81` and `main -> main`" instead. The template could say to match on fragments, not on full lines with exact spacing.

12. **Session-required commit trailers vs. RELEASING.md's message format.** RELEASING.md says "Commit as `chore(release): vX.Y.Z`", and the session requires a `Co-Authored-By` trailer. I treated the RELEASING.md text as the subject line and put the trailer in the body. The skill only mentions trailers for briefs ("the full commit message (with any trailer lines the session requires)"), not for the main model's own local commits. A short line would remove the guess.

## Did differently from the skill, and why

- **Brief 01 has an extra npm pre-check (step 4)** that Example 4 doesn't have. See item 6.
- **Verification adds three checks beyond the table:** `dist-tags.latest`, the annotated tag object, and `gh api repos/quillkit/slug/issues/41 --jq .state` → `open`. The last one confirms the side effect I avoided really was avoided. The skill tells you to avoid side effects but has no row for checking that you did.
- **No `npm profile get --json` 2FA preflight.** It only matters for local publishes, and here CI publishes with OIDC. The skill mentions that check without saying it's irrelevant in the CI-publish path; saying so would save a network call.
- **Install check gated on gitHead, not just `npm view` version.** That's stricter than "gate: that package verified". I wanted "published from the tag" confirmed before reporting anything built on it.

## Dry-run-specific notes

- Preflight and verification were written down, not run (no network allowed). Everything local was run for real: the tests (fail then pass), the two commits, the annotated tag, `npm pack --dry-run --offline`, and the brief 02 smoke command against the local source.
- The repo copy now sits at `234cf81` with tag `v2.3.1`, two commits ahead of where the scenario says origin is. Nothing was pushed.
