# Plan: fix #41 in @quillkit/slug and release 2.3.1

Repo: `C:\Users\User\github repo\skills\haiku-delegate-workspace\iteration-1\fix-bug-and-release\with_skill\repos\slug` (origin `github.com/quillkit/slug`, main pushed at `7d0bf66`, last release v2.3.0).
Opt-in: the user said "delegate the busywork" earlier in this session, so Haiku agents are allowed. Approval: "fix this bug and release it", taken as approval for releasing the way RELEASING.md describes.

## 1. Task list (as it goes on the session's task list)

```
[main]  Reproduce #41 with failing tests                               (done)
[main]  Fix slugify separator collapsing, run npm test                 (done)
[main]  Pick version 2.3.1, write CHANGELOG entry                      (done)
[main]  Commit fix + chore(release): v2.3.1, tag v2.3.1 locally        (done)
[main]  Preflight: remote main, tag free, 2.3.1 unpublished, trusted publisher, workflow active
[haiku] Wave 1: push main, push tag v2.3.1, watch release run (1 agent; one chain, stop at first error)
[main]  Verify main SHA, tag ref, run conclusion, npm 2.3.1 live
[haiku] Wave 2: clean install check of @quillkit/slug@2.3.1 (1 agent; only after npm view shows 2.3.1)
[main]  Check install evidence, wrap-up table
```

Waves: wave 1 = brief 01 alone. Wave 2 = brief 02 alone, launched only after wave 1 is verified (it needs 2.3.1 to be on npm, which only happens if the workflow run in wave 1 succeeded).

## 2. Who does each step, and why

Checklist = the four tests in SKILL.md "What goes to Haiku": (1) every input known up front, (2) success checkable from outside, (3) no choice needed, (4) failure safe to stop at. Plus the rule that passing makes a step eligible, not required.

| # | Step | Who | Why |
|---|---|---|---|
| 1 | Read BUG.md, RELEASING.md, code, tests | main | Reading unfamiliar code is the deliverable (not-for-haiku: "reading unfamiliar APIs"). |
| 2 | Write failing tests that reproduce #41 | main | Writing code; fails (3): choosing which cases cover the bug is judgment. |
| 3 | Fix `slugify` | main | Designing/writing code and debugging; fails (1) and (3). |
| 4 | Run `npm test` | main | Passes the checklist, but it's one local 60 ms command whose output I need right away to judge the fix. "One or two quick commands are cheaper to run yourself." |
| 5 | Choose 2.3.1 (patch) | main | Gray area "version bumps": choosing patch/minor/major is judgment. RELEASING.md says patch for fixes. |
| 6 | Write CHANGELOG entry | main | User-facing wording; fails (3). Gray area "changelog entries". |
| 7 | Edit `version` in package.json | main | The mechanical half of the version bump, but it's a one-line edit in the same commit as step 6. Not worth a brief. Done by hand rather than `npm version`, which would re-serialize the compact package.json. |
| 8 | Commit the fix, commit `chore(release): v2.3.1` | main | Local and reversible, but the commit messages are wording (fails (3) until written), and both commits are one command each right after I wrote the content. Keeping them on main lets me check the exact tree before anything leaves the machine. |
| 9 | Create annotated tag v2.3.1 locally | main | One local command; doing it here means the brief carries the exact tag object SHA, so the agent and I can both check it. Skill example 1 has the agent create the tag; I moved it because it's local and makes the brief's Expect lines exact. |
| 10 | Preflight (remote main, tag free on origin, 2.3.1 not on npm, trusted publisher, workflow active, last run green) | main | Read-only network checks. The skill puts verification on main ("Run these directly rather than delegating them"), and the trusted-publisher check is security config (not-for-haiku: "anything security-sensitive"). |
| 11 | Push main, push tag v2.3.1 | haiku (wave 1) | Passes all four: exact SHAs and refs known; checkable by `gh api`; no choices; a rejected push changes nothing. Approved by "release it". Only two commands on its own, so it rides with step 12 in one agent: dependent steps for a single item share one agent, and stop-at-first-error means the tag is never pushed if main fails. |
| 12 | Wait for and watch the `release` workflow run | haiku (wave 1) | Long wait with noisy output: the case where delegation pays off. Passes all four: the commit SHA identifies the run; conclusion is checkable; no choices; watching changes nothing. Reading a failed log stays on main (gray area "CI failures"). |
| 13 | npm publish | nobody directly | The workflow publishes on tag push (RELEASING.md step 6: "Do not run `npm publish` by hand"). Brief 01 forbids `npm publish` explicitly so a failed run can't be "fixed" by hand-publishing. |
| 14 | Verify wave 1 (main SHA, tag ref + SHA, run conclusion, npm version, gitHead) | main | Skill step 5: every report is a claim; check with cheap read-only commands, run directly. |
| 15 | Clean install from npm + run the fixed function | haiku (wave 2) | Listed as typical Haiku work. Passes all four: exact package/version/folder/expected output; output checkable; no choices; only touches an empty temp folder. Borderline on cost (a zero-dependency package installs in seconds), delegated because the user asked for busywork to go out and the skill's own example for this exact request delegates "checks the install". |
| 16 | Wrap-up table, Left / Needs you | main | User-facing writing, built from verified results. |
| - | Close issue #41, create a GitHub Release | not done | Not in RELEASING.md and not approved. Commit messages reference `(#41)` without "Fixes", so pushing main won't auto-close the issue. Offered to the user at the end instead. |

## 3. What I did on the main model

### Reproduce
Added four tests to `test/slugify.test.js` before touching the code. `npm test` before the fix:

```
✔ lowercases and dashes words (0.4666ms)
✔ strips punctuation (0.0666ms)
✔ removes accents (0.0751ms)
✖ collapses repeated spaces into one dash (#41) (0.5038ms)
✖ collapses spaces around a dash into one dash (#41) (0.125ms)
✖ collapses separators left behind by removed punctuation (#41) (0.546ms)
✖ collapses mixed whitespace into one dash (#41) (0.1135ms)
ℹ tests 7
ℹ pass 3
ℹ fail 4
```
(actual values included `'salt--pepper----oil'` and `'tab-here--newline'`.)

### Cause and fix
`slugify` strips punctuation, then replaces each whitespace character with a dash one at a time (`.replace(/\s/g, '-')`). Three spaces become three dashes, and `Rock - Paper` keeps its own dash between two converted spaces, giving `rock---paper`. The fix replaces any run of whitespace and/or dashes with a single dash. This also covers runs created when punctuation between spaces is stripped (`Salt , Pepper` gave `salt--pepper`), which BUG.md's "anything that produces more than one separator in a row" includes.

### Diff (`git diff 7d0bf66..HEAD`)

```diff
diff --git a/CHANGELOG.md b/CHANGELOG.md
@@ -1,5 +1,9 @@
 # Changelog
 
+## 2.3.1
+
+- Collapse repeated spaces and dashes into a single dash (`Rock - Paper` → `rock-paper`, not `rock---paper`). (#41)
+
 ## 2.3.0
diff --git a/package.json b/package.json
@@ -1,6 +1,6 @@
 {
   "name": "@quillkit/slug",
-  "version": "2.3.0",
+  "version": "2.3.1",
diff --git a/src/index.js b/src/index.js
@@ -12,7 +12,7 @@ function slugify(input) {
     .trim()
     .toLowerCase()
     .replace(/[^a-z0-9\s-]/g, '')
-    .replace(/\s/g, '-');
+    .replace(/[\s-]+/g, '-');
 }
diff --git a/test/slugify.test.js b/test/slugify.test.js
@@ -14,3 +14,19 @@ test('strips punctuation', () => {
 test('removes accents', () => {
   assert.strictEqual(slugify('Crème Brûlée'), 'creme-brulee');
 });
+
+test('collapses repeated spaces into one dash (#41)', () => {
+  assert.strictEqual(slugify('Hello   World'), 'hello-world');
+});
+
+test('collapses spaces around a dash into one dash (#41)', () => {
+  assert.strictEqual(slugify('Rock - Paper'), 'rock-paper');
+});
+
+test('collapses separators left behind by removed punctuation (#41)', () => {
+  assert.strictEqual(slugify('Salt , Pepper -- Oil'), 'salt-pepper-oil');
+});
+
+test('collapses mixed whitespace into one dash (#41)', () => {
+  assert.strictEqual(slugify('tab\there\n\nnewline'), 'tab-here-newline');
+});
```

### Tests after the fix (`npm test`, Node v24.16.0, exit 0)

```
✔ lowercases and dashes words (0.4774ms)
✔ strips punctuation (0.0688ms)
✔ removes accents (0.0837ms)
✔ collapses repeated spaces into one dash (#41) (0.0539ms)
✔ collapses spaces around a dash into one dash (#41) (0.0613ms)
✔ collapses separators left behind by removed punctuation (#41) (0.0528ms)
✔ collapses mixed whitespace into one dash (#41) (0.5075ms)
ℹ tests 7
ℹ pass 7
ℹ fail 0
```
Re-run after the version/changelog edit: `tests 7, pass 7, fail 0`, exit 0. The CI workflow uses Node 24 too.

### Version, changelog, commits, tag
- Version: **2.3.1** (patch: bug fix, no API change; RELEASING.md step 1).
- `npm pack --dry-run` (local): 2 files, `package.json` and `src/index.js`, 533 B packed. Same file set as the `files` field intends.
- Commits on local main (author is the user's git identity; trailer per this session's attribution rule):

```
9d8f3521c6916ff87d4fdee90e1ada8130464d96  chore(release): v2.3.1
4f22923ff82af6344561478516477e905d03e7b6  fix: collapse repeated separators into a single dash (#41)
7d0bf664bb487e6172eb006e38a3d4501545f225  chore(release): v2.3.0   (= origin/main)
```

  Full messages:

```
fix: collapse repeated separators into a single dash (#41)

Runs of whitespace and dashes, including ones left behind after
punctuation is stripped, now become one dash: 'Rock - Paper' gives
'rock-paper' instead of 'rock---paper'.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```
```
chore(release): v2.3.1

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
```

- Tag: `git tag -a v2.3.1 -m "v2.3.1"`. `git cat-file -t v2.3.1` → `tag`; tag object `07b5367ee940920a6747ccbea6aeefd7f0f3ac85` → commit `9d8f3521c6916ff87d4fdee90e1ada8130464d96`.
- Working tree clean, on `main`. Nothing pushed (dry run).

Not changed, worth telling the user: inputs that end or start with punctuation still leave an edge dash (`'Hello !'` → `'hello-'`, `'- lead'` → `'-lead'`). That behaviour predates this bug and isn't what #41 reports, so I left it alone.

## 4. Approvals

Already approved ("release it" = release as RELEASING.md describes):
- commit the fix and `chore(release): v2.3.1` to main (done locally);
- push main to origin;
- push annotated tag v2.3.1;
- let the `release` workflow publish @quillkit/slug@2.3.1 to npm.

Needs no approval (local / read-only, per brief-template Example 3): preflight and verification reads, and the install check in a temp folder.

Not approved, and not in the plan:
- `npm publish` by hand (RELEASING.md forbids it anyway);
- creating a GitHub Release, closing or commenting on issue #41;
- rerunning/cancelling workflows, moving or deleting tags, force pushes;
- any change to trusted publishing or repo settings.

Question to ask now: **none**. Every outward action in the plan is covered. Conditional questions, asked only if they come up:
- Preflight shows no trusted publisher for `quillkit/slug` + `release.yml`: "npm has no trusted publisher for @quillkit/slug, so the release workflow can't publish 2.3.1. Want to add one for quillkit/slug, workflow release.yml (you'll need to approve it in the browser), or should I stop before pushing the tag?"
- The release run fails after the tag is pushed: "The release run for v2.3.1 failed at <job/step>: <cause>. The tag is pushed but nothing is on npm. Fix forward as 2.3.2, or delete and re-push v2.3.1 after the fix?" (moving a pushed tag is outside the approval.)

At wrap-up, offered (not done): "Issue #41 is still open. Want me to close it with a comment pointing at v2.3.1?"

## 5. Preflight (main model, read-only; network commands, not run in this dry run)

| Command | Expected result |
|---|---|
| `git ls-remote origin refs/heads/main refs/tags/v2.3.1` | one line: `7d0bf664bb487e6172eb006e38a3d4501545f225	refs/heads/main`, no tag line |
| `gh api repos/quillkit/slug/branches/main --jq .protected` | `false` (if `true`, read the protection rules before letting an agent push directly) |
| `npm view @quillkit/slug version` | `2.3.0` |
| `npm view @quillkit/slug@2.3.1 version` | E404 "No match found for version 2.3.1" (expected: not published yet) |
| `npm trust list @quillkit/slug` | one GitHub Actions trusted publisher: repository `quillkit/slug`, workflow `release.yml`, no environment |
| `gh api repos/quillkit/slug/actions/workflows --jq '.workflows[] \| [.name,.path,.state] \| @tsv'` | `release	.github/workflows/release.yml	active` |
| `gh run list --repo quillkit/slug --workflow release.yml --limit 1 --json headBranch,conclusion` | `[{"conclusion":"success","headBranch":"v2.3.0"}]` (the pipeline worked last time) |

If any line differs, stop and handle it on main before launching wave 1.

## 6. Launch order

### Wave 1 (one agent)

```
Agent({
  description: "Push slug v2.3.1, watch release",
  subagent_type: "general-purpose",
  model: "haiku",
  run_in_background: true,
  prompt: <full text of briefs/01-push-and-watch-release.md>
})
```

While it runs: nothing else is left on main except reviewing brief 02 one more time; I wait for the completion notification and don't poll.

Before wave 2, all of these must hold (section 7, wave 1 checks): main on origin is `9d8f352…`, tag v2.3.1 on origin is tag object `07b5367…`, the release run for `9d8f352…` is `completed/success`, and `npm view @quillkit/slug@2.3.1 version` prints `2.3.1`.

### Wave 2 (one agent)

```
Agent({
  description: "Install-check @quillkit/slug 2.3.1",
  subagent_type: "general-purpose",
  model: "haiku",
  run_in_background: true,
  prompt: <full text of briefs/02-install-check.md>
})
```

Then check its evidence (section 7, wave 2) and write the wrap-up.

## 7. Verification (main model, read-only)

### After the wave 1 report

| Command | Should print |
|---|---|
| `gh api repos/quillkit/slug/commits/main --jq .sha` | `9d8f3521c6916ff87d4fdee90e1ada8130464d96` |
| `gh api repos/quillkit/slug/git/ref/tags/v2.3.1 --jq '.ref + " " + .object.type + " " + .object.sha'` | `refs/tags/v2.3.1 tag 07b5367ee940920a6747ccbea6aeefd7f0f3ac85` |
| `gh run list --repo quillkit/slug --commit 9d8f3521c6916ff87d4fdee90e1ada8130464d96 --json databaseId,workflowName,status,conclusion` | one entry: `workflowName` `release`, `status` `completed`, `conclusion` `success`, `databaseId` equal to the run ID in the agent's evidence |
| `npm view @quillkit/slug@2.3.1 version` | `2.3.1` |
| `npm view @quillkit/slug dist-tags.latest` | `2.3.1` |
| `npm view @quillkit/slug@2.3.1 gitHead` | `9d8f3521c6916ff87d4fdee90e1ada8130464d96` (the published tarball was built from the release commit) |

If the run is green but `npm view` still says E404, check once more a minute later before calling it failed (registry read-after-publish lag); don't launch wave 2 until it shows `2.3.1`.

### After the wave 2 report

Accept the agent's evidence only if it quotes, verbatim: `added 1 package…`, a line containing `@quillkit/slug@2.3.1` from `npm ls`, and the three lines `2.3.1` / `hello-world` / `rock-paper`. If any of them is paraphrased or missing, rerun the one check myself (read-only against the temp folder the agent made):

```
cd /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1 && node -e "const { slugify } = require('@quillkit/slug'); console.log(require('@quillkit/slug/package.json').version); console.log(slugify('Hello   World')); console.log(slugify('Rock - Paper'));"
```
→ `2.3.1`, `hello-world`, `rock-paper`.

### If something fails
- Push rejected (non-fast-forward, protection): main diagnoses; nothing outward has changed yet. Ask the user if it needs a PR flow.
- Tag push fails after main succeeded: main diagnoses; a corrected brief starts at step 6 (step 4's alternatives make reruns safe).
- Run fails: main reads `gh run view <id> --repo quillkit/slug --log-failed`. The tag is already out, so any fix needs the user's call (fix forward as 2.3.2, or move the tag), see section 4.
- `NEEDS_USER`, auth or rate-limit: pass it to the user with the exact text; no relaunch until they say so.

## 8. Wrap-up (if everything succeeded)

| Item | Result | Evidence |
|---|---|---|
| Fix for #41 | committed on main with 4 new tests; 7/7 pass locally and in the release run | [4f22923](https://github.com/quillkit/slug/commit/4f22923ff82af6344561478516477e905d03e7b6) |
| Release commit | `chore(release): v2.3.1` on main | [9d8f352](https://github.com/quillkit/slug/commit/9d8f3521c6916ff87d4fdee90e1ada8130464d96) |
| Tag v2.3.1 | pushed, annotated, points at 9d8f352 | [v2.3.1](https://github.com/quillkit/slug/tree/v2.3.1) |
| Release workflow | succeeded (tests + publish with provenance) | [run &lt;RUN_ID&gt;](https://github.com/quillkit/slug/actions/runs/&lt;RUN_ID&gt;) |
| @quillkit/slug 2.3.1 | on npm as `latest`, built from 9d8f352; clean install prints `hello-world` / `rock-paper` | [npm](https://www.npmjs.com/package/@quillkit/slug/v/2.3.1) |

**Left:** nothing.
**Needs you:** issue [#41](https://github.com/quillkit/slug/issues/41) is still open (the commits reference it without "Fixes"); close it, or tell me to. Separately, input with leading or trailing punctuation still gives an edge dash (`'Hello !'` → `'hello-'`); that predates #41 and I didn't change it.
