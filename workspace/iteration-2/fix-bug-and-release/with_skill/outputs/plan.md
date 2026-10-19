# Plan: fix #41 in @quillkit/slug and release 2.3.1

Repo: `C:\Users\User\github repo\skills\haiku-delegate-workspace\iteration-2\fix-bug-and-release\with_skill\repos\slug` (origin `github.com/quillkit/slug`, main pushed at `7d0bf66`, last release `v2.3.0`).
Opt-in: the user said "delegate the busywork" earlier in the session. Approval: "release it" = the RELEASING.md flow (commit to main, push main, push the tag, let the workflow publish). Nothing else is approved.

## 1. Task list (as put on the session's task list)

```
[main]  Read BUG.md, RELEASING.md, release.yml, src, tests                          done
[main]  Fix #41 + regression tests; npm test 6/6                                    done
[main]  Bump to 2.3.1, CHANGELOG entry, commit chore(release): v2.3.1, tag v2.3.1   done (local only)
[main]  Preflight, read-only: trust list, workflow active, last release run ok,
        origin main = 7d0bf66, v2.3.1 free on origin, 2.3.1 not on npm
[haiku] Push main + push tag v2.3.1 + watch release run (1 agent)    gate: local commits/tag checked + preflight passed
[main]  Verify: main and tag SHAs on GitHub, run success, npm 2.3.1 with gitHead 234cf81, #41 still open
[haiku] Install check @quillkit/slug@2.3.1 in a temp folder (1 agent) gate: 2.3.1 verified on npm, published from the tag
[main]  Check install report + wrap-up table
```

Only one agent runs at any time; the second is gated on the verified result of the first.

## 2. Who does each step, and why

Checklist = the four tests in SKILL.md "What goes to Haiku": (1) every input known, (2) success checkable from outside, (3) no choice needed, (4) failure safe to stop at.

| Step | Who | Why |
|---|---|---|
| Read BUG.md, RELEASING.md, release.yml, code | main | Understanding is the deliverable (not-for-haiku: reading unfamiliar code/APIs). Fails (3). |
| Write the fix and the regression tests | main | Designing/writing code. Fails (1) and (3). |
| Run `npm test` | main | Eligible, but it's one quick command inside my own edit-test loop; SKILL.md: "one or two quick commands are cheaper to run yourself". |
| Choose patch vs minor, write CHANGELOG text | main | Gray area, judgment half (not-for-haiku "Version bumps and changelog entries"). Fails (3). |
| Local fix commit, release commit, annotated tag | main | SKILL.md "Local commits and tags stay with you": they record my decisions, are one command each, and let the brief pin exact SHAs. |
| Preflight of the CI publish pipeline | main | SKILL.md "Releases where CI publishes: check the pipeline before the tag goes out ... on the main model, read-only". Trusted-publishing config is also security-sensitive (not-for-haiku). |
| Push main, push tag, find and watch the release run | haiku (brief 01) | Passes all four: SHAs, remote state and commands are pinned (1); `gh api` / `gh run list` / `npm view` check it (2); no choices (3); stop-at-first-error leaves at worst main pushed without a tag, which is harmless and resumable (4). It's a long wait with noisy output, and SKILL.md says one agent for the remote half of a single-item CI release (Example 4). |
| Verify each report | main | SKILL.md section 5: "Run these directly rather than delegating them". |
| Install check from the registry | haiku (brief 02) | Passes all four; listed under "Typical Haiku work"; gated after `npm view` per SKILL.md section 4 bullet 3 and Example 4's context. |
| Diagnose a failed push or run; decide fix-forward vs moving the tag | main / user | Debugging stays on main; "Whether to fix forward as a new patch version or move the tag is the user's call." |
| Wrap-up | main | Built from verified state (section 8). |

## 3. What I did on the main model (local, done)

**Diagnosis.** `slugify` strips everything except `a-z0-9`, whitespace and `-`, then maps each whitespace character to `-` on its own (`.replace(/\s/g, '-')`). So `'Hello   World'` gives three dashes, and `'Rock - Paper'` keeps its literal dash between two converted spaces, giving `rock---paper`. Punctuation stripped from between spaces (`'Salt & Pepper'`) has the same problem.

**Fix.** Replace each run of whitespace and dashes with one dash: `.replace(/[\s-]+/g, '-')`. I kept it to the reported bug. Leading or trailing dashes (`' - Hello - '` now gives `-hello-`, before the fix `--hello--`) are a separate behaviour change that nobody asked for, so I didn't touch them.

**Version.** This is a fix, so a patch: 2.3.0 → 2.3.1 (RELEASING.md step 1). I edited the version line by hand, which leaves the rest of package.json alone.

**Changelog.** I matched the existing style (one bullet with an example, no issue numbers): `- Collapse runs of spaces and dashes into a single dash (`Rock - Paper` → `rock-paper`).`

**Commits and tag** (local, not pushed):

| Object | SHA | Content |
|---|---|---|
| fix commit | `41a4b3c3473e351286d9f459575b1bf650a56804` | `fix: collapse repeated separators into a single dash (#41)` + body + `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>` |
| release commit | `234cf81a0d49c8a23fa8e04889205780180e290a` | `chore(release): v2.3.1` + the same trailer (RELEASING.md step 3) |
| tag `v2.3.1` | tag object `c0b90a51136abcb074392f9c2d79eeb753f77be5` → `234cf81…` | annotated, message `v2.3.1`, the same form as `v2.3.0` (RELEASING.md step 4) |

The commit says `(#41)`, not `Fixes #41`. A grep of the outgoing messages for `fix(es|ed)? #`, `close[sd]? #` and `resolve[sd]? #` finds nothing.

**Diff** (`git diff 7d0bf66..main`):

```diff
--- a/CHANGELOG.md
+++ b/CHANGELOG.md
@@ -1,5 +1,9 @@
 # Changelog
 
+## 2.3.1
+
+- Collapse runs of spaces and dashes into a single dash (`Rock - Paper` → `rock-paper`).
+
 ## 2.3.0
--- a/package.json
+++ b/package.json
-  "version": "2.3.0",
+  "version": "2.3.1",
--- a/src/index.js
+++ b/src/index.js
@@ -12,7 +12,7 @@ function slugify(input) {
     .replace(/[^a-z0-9\s-]/g, '')
-    .replace(/\s/g, '-');
+    .replace(/[\s-]+/g, '-');
 }
--- a/test/slugify.test.js
+++ b/test/slugify.test.js
@@ -14,3 +14,17 @@
+test('collapses repeated spaces into one dash (#41)', () => {
+  assert.strictEqual(slugify('Hello   World'), 'hello-world');
+  assert.strictEqual(slugify('Hello\t\n World'), 'hello-world');
+});
+
+test('collapses spaces around a dash into one dash (#41)', () => {
+  assert.strictEqual(slugify('Rock - Paper'), 'rock-paper');
+  assert.strictEqual(slugify('Rock -- Paper'), 'rock-paper');
+});
+
+test('collapses separators left by stripped punctuation (#41)', () => {
+  assert.strictEqual(slugify('Salt & Pepper'), 'salt-pepper');
+});
```

The accent regex on line 11 (literal U+0300–U+036F) is byte-for-byte unchanged; I checked it with `od -c` before and after the edit.

**Tests.** Before the fix, the three new tests failed (`ℹ tests 6`, `ℹ pass 3`, `ℹ fail 3`, exit 1). After the fix (Node v24.16.0, the same major version as the workflow's `node-version: 24`):

```
✔ lowercases and dashes words (0.4921ms)
✔ strips punctuation (0.0688ms)
✔ removes accents (0.0785ms)
✔ collapses repeated spaces into one dash (#41) (0.06ms)
✔ collapses spaces around a dash into one dash (#41) (0.0679ms)
✔ collapses separators left by stripped punctuation (#41) (0.0512ms)
ℹ tests 6
ℹ pass 6
ℹ fail 0
exit=0
```

**Other local checks.**
- `git status --porcelain` is empty.
- HEAD is `234cf81`. `git cat-file -t v2.3.1` prints `tag`, and `v2.3.1^{commit}` resolves to `234cf81`.
- `npm pack --dry-run --offline` lists `package.json` and `src/index.js`, version 2.3.1, 2 files, which is what `files: ["src"]` should give.
- I ran the exact `node -e` line from brief 02 against `./src/index.js` and it printed `hello-world rock-paper creme-brulee`.

## 4. Approvals and side effects

**Already approved** (by "release it", read against RELEASING.md):
- pushing `main` from `7d0bf66` to `234cf81`, which adds two commits;
- pushing the annotated tag `v2.3.1`;
- the `release` workflow publishing `@quillkit/slug@2.3.1` to npm, which moves `latest` to 2.3.1;
- the install check, which only touches a temp folder and needs nothing beyond the opt-in.

**Not approved, and kept out of the plan:**
- closing issue #41: the commit uses `(#41)` instead of a closing keyword;
- creating a GitHub Release: the workflow doesn't create one, and the brief forbids `gh release create`;
- commenting on the issue;
- any local `npm publish`;
- rerunning or cancelling runs;
- moving or deleting tags;
- deleting BUG.md.

**What each outward action sets off** (checked in `.github/workflows/`, which has only `release.yml`, triggered on `push: tags: ['v*']`):

| Action | Sets off | Handling |
|---|---|---|
| `git push origin main` | No workflow, because nothing triggers on branch pushes. GitHub adds a "referenced this issue" event to #41's timeline because the subject says `(#41)`. It does not close the issue. | Harmless and visible. Brief 01 tells the agent to leave the issue alone. |
| `git push origin refs/tags/v2.3.1` | The `release` run starts: `npm test`, then `npm publish --provenance` through trusted publishing (OIDC). 2.3.1 goes public and can't really be taken back. | This is the approved publish. Nothing else publishes 2.3.1, so there's no race. Brief 01 forbids `npm publish` outright and watches the run without touching it. |
| install check | Downloads 2.3.1 from the registry into a temp folder. | None needed. |

**Message to the user at launch.** It's a heads-up, not a question, because nothing outside the approval is left:

> Releasing @quillkit/slug 2.3.1. A Haiku agent is pushing main (2 commits: the #41 fix and the release commit) and tag v2.3.1. The tag push starts the `release` workflow, which publishes to npm. The fix commit references #41 but doesn't close it.

## 5. Preflight, before brief 01 launches (main, read-only, network)

I haven't run these, because the dry run allows no network. These are the commands and what each should print. If any differs, I stop and don't launch.

| # | Command | Expected |
|---|---|---|
| P1 | `npm trust list @quillkit/slug` | one GitHub Actions trusted publisher with repository `quillkit/slug` and workflow file `release.yml` (no environment, since release.yml sets none) |
| P2 | `gh api repos/quillkit/slug/actions/workflows --jq '.workflows[] \| [.path,.state] \| @tsv'` | exactly `.github/workflows/release.yml	active` |
| P3 | `gh run list --repo quillkit/slug --workflow release.yml --limit 1 --json headBranch,conclusion` | `[{"conclusion":"success","headBranch":"v2.3.0"}]` |
| P4 | `npm view @quillkit/slug@2.3.0 gitHead --prefer-online` | `7d0bf664bb487e6172eb006e38a3d4501545f225` (2.3.0 came from the tag through CI, so gitHead is a valid check later) |
| P5 | `npm view @quillkit/slug dist-tags --json --prefer-online` and `npm view @quillkit/slug@2.3.1 version --prefer-online` | `{"latest": "2.3.0"}`; then E404 "No match found for version 2.3.1" (or empty output, exit 0) |
| P6 | `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/fix-bug-and-release/with_skill/repos/slug" && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git ls-remote origin refs/heads/main refs/tags/v2.3.1` | exactly `7d0bf664bb487e6172eb006e38a3d4501545f225	refs/heads/main`, no tag line |

In P2, `\|` is the Markdown table escape for `|`. The real command is `gh api repos/quillkit/slug/actions/workflows --jq '.workflows[] | [.path,.state] | @tsv'`.

The local clone has no `origin/main` tracking ref (`git branch -a` lists only `main`). So P6 is the only source for the "origin/main before this job" value in brief 01. The scenario says main is pushed at `7d0bf66`, and the brief uses that.

Skipped on purpose:
- `npm profile get --json` (the 2FA mode): nothing is published locally, and trusted publishing doesn't use the user's npm 2FA.
- `gh auth status`: the scenario says gh is logged in, and brief 01 stops on any auth error anyway.

If a preflight check fails:
- P1, P2 or P3: the pipeline isn't trustworthy. Tell the user and don't push the tag. Trusted-publishing config is theirs to approve.
- P4 differs: the gitHead check can't be relied on, so verification falls back to run success plus `npm view` version, and I'd say so.
- P5 shows 2.3.1: someone already published it. Stop and ask.
- P6 shows main moved: rebase my two commits onto the new origin/main myself, rerun the tests, recreate the local tag (it's unpushed, so that's safe), update the SHAs in brief 01, and rerun P6.

## 6. Launch order and Agent parameters

**Brief 01**, `briefs/01-push-release-watch.md`
- Gate: local commits and tag checked (done) and preflight P1–P6 as expected.
- Right before launch I re-check locally:
  - `git status --porcelain` is empty;
  - `git rev-parse HEAD` is `234cf81a0d49c8a23fa8e04889205780180e290a`;
  - `git rev-parse v2.3.1 "v2.3.1^{commit}"` gives `c0b90a51136abcb074392f9c2d79eeb753f77be5` and `234cf81a0d49c8a23fa8e04889205780180e290a`.
- Then I send the heads-up from section 4 in the same message as the launch.

```
Agent({
  description: "Push slug v2.3.1, watch release",
  subagent_type: "general-purpose",
  model: "haiku",
  run_in_background: true,
  prompt: "<full contents of briefs/01-push-release-watch.md>"
})
```

**Brief 02**, `briefs/02-install-check.md`
- Gate: brief 01's three items verified (section 7), including `npm view @quillkit/slug@2.3.1 version` = `2.3.1` and gitHead = `234cf81…`.
- Right before launch: `test ! -e "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1" && echo free` prints `free`. If the folder exists from an earlier attempt, I change the folder name in all five steps of the brief, say to `quillkit-slug-2.3.1-b`, and don't delete the old one.

```
Agent({
  description: "Install-check @quillkit/slug 2.3.1",
  subagent_type: "general-purpose",
  model: "haiku",
  run_in_background: true,
  prompt: "<full contents of briefs/02-install-check.md>"
})
```

Both briefs run in the background (SKILL.md default), so the user can talk to me while the release run takes its few minutes. I wrote brief 02 before brief 01 launched, so it's ready the moment the gate opens.

## 7. Verification (main, read-only)

**After brief 01 reports** (`push main`, `push tag v2.3.1`, `release run`):

| Claim | Command | Should print |
|---|---|---|
| main pushed | `gh api repos/quillkit/slug/commits/main --jq .sha` | `234cf81a0d49c8a23fa8e04889205780180e290a` |
| tag pushed, on the right commit | `gh api repos/quillkit/slug/commits/v2.3.1 --jq .sha` | `234cf81a0d49c8a23fa8e04889205780180e290a` |
| tag is my annotated tag object | `gh api repos/quillkit/slug/git/ref/tags/v2.3.1 --jq '.object.type + " " + .object.sha'` | `tag c0b90a51136abcb074392f9c2d79eeb753f77be5` |
| CI result | `gh run list --repo quillkit/slug --commit 234cf81a0d49c8a23fa8e04889205780180e290a --json databaseId,workflowName,status,conclusion` | one entry: `workflowName` `release`, `status` `completed`, `conclusion` `success`, `databaseId` = the run ID in the report |
| published | `npm view @quillkit/slug@2.3.1 version --prefer-online` | `2.3.1` |
| published from the tag | `npm view @quillkit/slug@2.3.1 gitHead --prefer-online` | `234cf81a0d49c8a23fa8e04889205780180e290a` |
| is latest | `npm view @quillkit/slug dist-tags.latest --prefer-online` | `2.3.1` |
| side effect avoided | `gh api repos/quillkit/slug/issues/41 --jq .state` | `open` |

If any check disagrees with the report, the check wins and the item counts as failed (SKILL.md section 5).

Failure paths:
- `push main` rejected: I diagnose it (most likely main moved). I rebase locally, retest, recreate the unpushed tag, and write a corrected brief 01.
- `push tag` failed after main went out: if it's mechanical (say a transient network failure), a corrected brief starts at the tag push. For auth or rate-limit errors, I ask the user.
- `release run` failed: I read `gh run view <id> --repo quillkit/slug --log-failed` myself. The tag is now public with nothing on npm, so I tell the user the cause and ask whether to fix forward as 2.3.2 or move the tag.
- `npm view` lags after a successful run: I rerun the `--prefer-online` check myself a few times before launching brief 02.

**After brief 02 reports** (`install @quillkit/slug@2.3.1`):
- The report quotes `added 1 package`, a line containing `@quillkit/slug@2.3.1`, and exactly `hello-world rock-paper creme-brulee`. `npm view` already showed 2.3.1 is live, so I accept it if the quotes are exact (verify table, "install check").
- If the quote is paraphrased or missing, I rerun the step-5 `node -e` line myself in the same temp folder.

## 8. Wrap-up (if everything succeeds)

| Item | Result | Evidence |
|---|---|---|
| Bug #41 (repeated separators) | fixed in `41a4b3c`, 3 regression tests, 6/6 pass locally and in CI | [41a4b3c](https://github.com/quillkit/slug/commit/41a4b3c3473e351286d9f459575b1bf650a56804) |
| main | pushed `7d0bf66..234cf81` | [commits/main](https://github.com/quillkit/slug/commits/main) |
| tag v2.3.1 | pushed, annotated, points at `234cf81` | [v2.3.1](https://github.com/quillkit/slug/tree/v2.3.1) |
| release workflow | `success` (run `<id>`) | `https://github.com/quillkit/slug/actions/runs/<id>` |
| @quillkit/slug 2.3.1 | on npm, `latest`, gitHead `234cf81` (published from the tag by CI) | [npm](https://www.npmjs.com/package/@quillkit/slug/v/2.3.1) |
| install check | clean install from the registry; `slugify` gives `hello-world rock-paper creme-brulee` | report from brief 02 |

**Left:** nothing.
**Needs you:** issue [#41](https://github.com/quillkit/slug/issues/41) is still open on purpose (closing it wasn't part of "release it"); close it if you want. BUG.md is still in the repo.
