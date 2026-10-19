# haiku-delegate: feedback from the publish-3-packages dry run

Ordered by how much damage each could do in a real run.

## Bugs in the template and examples (a Haiku agent following them literally would go wrong)

1. **Example 1 assumes the working directory persists between commands, and it doesn't.** The agent harness says "Agent threads always have their cwd reset between bash calls". Example 1 `cd`s only in step 1, then runs `npm publish` bare in step 4 and `git tag`/`git push` bare after that. With a reset cwd, `npm publish` runs in whatever the agent's default directory is. If that's another package (here the session root is a skills folder, but in a monorepo it could easily be a package), it **publishes the wrong package**, and only an unpublish can undo that. Example 3 does `cd` on every step, so the two examples disagree. Fix: put a rule in the template ("every command starts with `cd "<dir>" &&`") and fix Example 1. I did `cd` on every step in all six briefs.

2. **`npm view <pkg>@<new-version> version` doesn't return E404 when the package already exists.** For an existing package and an unpublished version, npm prints nothing and exits 0. That was my experience with npm 7–10; I couldn't confirm npm 12 offline. E404 only happens when the whole package name is unknown. Example 1 step 3 says "Expect: an E404 error", so for the most common release (a new version of an existing package, which is this scenario) a literal Haiku sees "no output" ≠ "E404" and stops, or worse, decides for itself what that means. The worked example's preflight ("confirm each name is free (`npm view <pkg>` should return E404)") has the same problem: it only covers first releases. Fix: "Expect: no output with exit 0, or E404; both mean unpublished." Also add `--prefer-online`, because `npm view` can answer from a stale local cache.

3. **Credential prompts hang instead of printing.** The stop conditions catch "a prompt to log in", but on Windows the credential helper is usually Git Credential Manager (it is on this machine: `credential.helper=manager`), and GCM pops a GUI window. The agent never sees a prompt; the command just hangs until the Bash tool times out. npm's web-auth 2FA can also block waiting for input. The template has nothing for this. What I added: `GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never` on every git network command, `</dev/null` on `npm publish`, an explicit Bash timeout (300000 ms) on publish/push/install steps, and a rule that a *tool* timeout on publish or push means "stop, don't rerun" (unlike the template's one-retry for ETIMEDOUT, because the state after a killed publish is unknown). The template should carry some version of this.

4. **The tag isn't pinned to a commit, and remote main isn't checked.** Example 1 runs `git tag -a v1.0.0 -m …` on whatever HEAD is at run time. If the working copy moved, or HEAD is an unpushed commit, `git push origin v1.0.0` uploads that commit too. That effectively publishes unreviewed, unapproved history to GitHub. I added three things: a preflight `gh api repos/<o>/<r>/commits/main --jq .sha` = local HEAD, the SHA as a brief input, `git tag -a <tag> -m <msg> <sha>`, and a `git rev-parse "<tag>^{commit}"` check before pushing. I'd make all of these standard.

5. **The verification table is too weak for tags and publishes.**
   - "tag pushed: `gh api …/git/ref/tags/<tag> --jq .ref`" only proves a tag with that name exists. It doesn't prove the tag points at the right commit or is annotated. I used `--jq '.ref + " " + .object.type'` plus `gh api repos/<o>/<r>/commits/<tag> --jq .sha` compared against the pinned SHA.
   - "npm package published: `npm view <pkg>@<ver> version`" doesn't prove that what got published is the tarball you inspected. `npm view <pkg>@<ver> dist.integrity` compared with the local `npm pack --dry-run --json` integrity does, at zero extra cost. Worth adding to the table.

## Gaps (forced me to make a call)

6. **What happens after NEEDS_USER on a publish?** The skill describes NEEDS_USER as "pass the URL to the user", which works for `npm trust` (approve, then verify). For `npm publish` it doesn't: the agent has already exited, so its npm process is dead, and approving that URL or getting an OTP achieves nothing. The main model can't enter OTPs either. The skill should say what to do: the user runs the publish, or the main model runs it in the background and relays the URL live. It should also say to check `npm profile get --json` (tfa mode) in preflight. If it's `auth-and-writes`, every publish brief is a guaranteed NEEDS_USER, so delegating publishes is pure waste and the plan should change before launch. I added both.

7. **Tag-triggered release workflows aren't mentioned anywhere.** The release chain "repo creation → publish → tag → trusted publishing → install check" never says to look for a workflow that runs on tag push. Here each repo has a release.yml on `v*` tags that would `npm publish --provenance`. It happens to fail at `npm ci` (no lockfile), but if it worked it would race the manual publish, and one of the two would fail with E403. Preflight should include: "read `.github/workflows/*` for `push: tags`; check what past tag runs did (`gh run list --workflow …`); decide publish-locally vs let-CI-publish, and ask if unclear." Briefs should also say "pushing this tag starts a workflow; don't watch, rerun or cancel it". I added that to the Do-not list, otherwise a diligent Haiku might `gh run watch` it.

8. **Waves vs queue is ambiguous.** Step 1 says "a wave starts only after the previous wave's results are verified". Step 4 says "When one finishes, verify its result, then launch the next queued one". With mixed gates, the fmt install check only needs fmt, but cli publish needs fmt *and* lint. It's unclear whether wave 2 waits for the whole of wave 1. I gated each brief on its own dependencies (04 after fmt, 05 after lint, 03 after both). I'd redefine waves as dependency gates per brief, not batch barriers.

9. **Should the install check share the publish agent?** Step 4 says "Dependent steps for a single item can share one agent" (publish → tag), and an install check is a dependent step of the same item. Yet the worked example puts install checks in their own wave. No guidance either way. I kept them separate: different working dir and file-scope rules, a main-model `npm view` gate in between, and registry-propagation ETARGET is a different failure class. That costs 6 cold starts instead of 3. Merging is defensible too. The skill should pick one and say why.

10. **"Don't relaunch an unchanged brief" vs propagation ETARGET.** Example 3 tells the agent "don't wait and retry" on ETARGET. Step 6 says not to relaunch an unchanged brief hoping for a different result. But ETARGET right after a publish is exactly the case where waiting changes the result. And since step 1 of the install brief refuses an existing temp folder, a relaunch *must* change the folder path anyway. I planned "confirm `npm view --prefer-online`, wait a couple of minutes, relaunch with a new folder". The skill should spell that out.

11. **No guidance on side effects of approved actions.** The approvals section covers unapproved actions (ask once). It says nothing about approved actions with side effects the user may not expect (here: 3 failing Actions runs from the tag pushes). I decided on a one-line FYI, not a blocking question. A sentence in step 2 would settle this.

12. **Tag convention is hardcoded.** The examples hardcode "annotated, message v1.0.0". The skill should say to match the repo's existing tags (`git for-each-ref refs/tags --format='%(objecttype) %(contents:subject)'`). Here they were annotated with message = tag name, so the hardcoded value matched by luck.

13. **The "safe to rerun" advice isn't applied in Example 1.** It checks whether the npm version exists, but not whether the tag already exists before publishing. I added a local + remote tag-absence check (`git tag -l`, `git ls-remote --tags`) *before* publish, so a tag conflict stops the agent before the irreversible step. `git ls-remote` isn't in the template's read-only exception list. I put it in Steps explicitly, but it probably belongs in that list.

## Smaller things

14. **Paths with spaces.** Example paths have no spaces and no quotes. The real path here is `/c/Users/User/github repo/…`. Add "quote every path" to Filling it in.
15. **`npx --no-install` (Example 3)** is a legacy flag spelling. I used `./node_modules/.bin/<bin> --version`, which runs the actual installed shim with no npx resolution. I also added `--prefer-online` to `npm install`, so a stale cached packument from the previous version doesn't cause a false ETARGET.
16. **The worked example delegates `npm pack --dry-run` + secret scan as Wave 1**, which nudges a model to always do that. For 3 tiny packages I ran pack myself and read the files. That's what the "one or two quick commands" rule implies, but the example pulls the other way. Add a sentence saying the example's Wave 1 pays off at 5+ packages or with real source trees.
17. **The template's preamble says "Don't ask questions"**, but nothing tells the agent what to do with harmless `npm warn` / `npm notice` lines. A literal Haiku could treat "output that doesn't match Expect" as covering any extra line. I added "warn/notice lines are fine if exit 0 and the `+` line appears". The template could note that Expect lines should say which extra output is benign.
18. **Agent description length.** The skill's example uses "Publish @acme/core 1.0.0". Fine, but nothing says the description should be unique per agent so the notifications are distinguishable. Mine are "Publish+tag …" / "Install-check …".

## Where I deviated from the skill's text

- Ran `npm pack --dry-run` and the secret check on main instead of delegating (item 16).
- Added the pre-publish tag-absence check, the SHA pin, `--prefer-online`, the non-interactive git env vars, `</dev/null`, explicit timeouts, and the "no rerun on tool timeout" rule (items 3, 4, 13).
- Replaced Example 1's E404 Expect with "no output or E404" (item 2).
- Gated wave 2 per brief, not per wave (item 8).
- Checked tag commit, tag type and tarball integrity on top of the table's checks (item 5).
- Added "do not watch/rerun/cancel Actions runs" and "do not touch fmt/lint" (in the cli brief) to the Do-not lists.
