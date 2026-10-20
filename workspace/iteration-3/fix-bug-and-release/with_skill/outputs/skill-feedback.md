# Skill feedback (haiku-delegate, iteration 3, fix-bug-and-release)

## What worked
- The "fix this bug and release it" split in SKILL.md matched this scenario exactly; I barely had to think about who does what.
- "Local commits and tags stay with you" + "your decisions get pinned" made the brief trivially exact (HEAD, tag object, origin main SHAs).
- releases.md's CI-publish section (no `npm publish`, put it under Do not, pre-tag pipeline checks, verify `gitHead`) covered every release-specific trap here. Example 2 was ~90% of my brief.
- `(#N)` instead of `Fixes #N` was a real catch; I'd otherwise likely have written "Fixes #41".

## Unclear / contradictory
1. **One agent or two for the install check.** SKILL.md says "For a single item, put its quick steps in the same agent as its long wait", and a gate only "when you want to verify an irreversible step first". But releases.md says "One agent does the remote half: push main, push the tag, find the run, watch it", and the examples put the install check (Example 3) in a separate agent, which reads as "gate the install on your gitHead verification". I combined them (one cold start instead of two; install is read-only). State which one you mean for a CI-published single package.
2. **Polling npm after the run.** Nothing in the skill says the package may lag behind a green run. I added a bounded `npm view … version` repeat (step 10) before the install. Worth one line in releases.md or Example 2/3.
3. **Fix commit vs release commit.** Example 2's context implies the fix lives in the `chore(release)` commit; RELEASING.md only names the release commit. I made two commits (`fix: … (#41)` then `chore(release): v2.3.1`). The skill doesn't say; fine to leave, but the example shapes behaviour.
4. **Heads-up for approved effects.** Step 2 says mention "harmless visible ones" in one line and ask about ones needing approval. It doesn't say whether to announce an already-approved publish right before launch. I wrote a one-line heads-up; say if that's wanted or noise.
5. **Two working directories in one brief.** The template has one "Working directory". Combining release + install forced me to add an "Install folder" input and make steps start with their own `cd`. Works with worker rules, but the template could show it.

## Missing
- **Branch protection / push permission on main.** The preflight checks the tag, npm and the workflow, but not whether a direct push to main is allowed (`gh api repos/<o>/<r>/branches/main/protection` or just knowing RELEASING.md says so). A rejected main push is safe (brief stops), so low priority.
- **Brittle Expect on push output.** `7d0bf66..8c9b69f` assumes git's 7-char abbreviation; a longer abbreviation would make a strict Haiku stop on a successful push. Suggest "a line containing `main -> main`" plus the remote SHA check by the main model.
- **No guidance on which preflight items can be skipped.** I skipped the `npm pack` integrity pin (nothing gitignored ships, CI packs from the tag) and the 2FA check (OIDC publish). releases.md implies both are conditional but doesn't say so for CI publishes explicitly.
- **Issue follow-up.** The skill avoids auto-closing the issue but doesn't say to list it under "Needs you". I did.

## Did differently
- Ran preflight myself (5 read-only network commands) rather than delegating: "run one or two quick commands yourself" says two, this was five, but they're instant and feed the brief's inputs, so a cold-start agent would cost more than it saves.
- Edited package.json with sed instead of `npm version` to avoid reformatting/auto-tagging (releases.md only warns to check the diff).
- Did not read `not-for-haiku.md` or `worked-example.md`: no borderline steps, and the skill only points to them conditionally. The slimmer SKILL.md was enough for this case.

## Environment notes (not skill bugs)
- My first sed edit silently didn't match (escaping in Git Bash); caught it only because tests still failed. I then used the Edit tool. Also I first appended tests to a new `test/index.test.js` instead of the existing `test/slugify.test.js`; fixed before committing.
- Git warns LF->CRLF on every touched file (global autocrlf); committed blobs are LF, so no effect on the release.
