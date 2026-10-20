# Plan: fix #41 and release @quillkit/slug 2.3.1

Opt-in: "delegate the busywork" (earlier this session). Approval: "release it" = commit to main, push main, push tag v2.3.1, let `release.yml` publish. Nothing else.

## Task list

1. [main] Reproduce #41, fix `src/index.js`, add regression tests, run tests (done)
2. [main] Bump to 2.3.1, CHANGELOG entry, commit `chore(release): v2.3.1`, annotated tag `v2.3.1` (done)
3. [main] Release preflight (read-only, network). Gate for 4: every check matches below
4. [haiku] Brief 01: push main, push tag, watch `release` run, wait for npm, clean install check. Gate: step 3 passed
5. [main] Verify brief 01's claims with read-only commands. Gate: brief 01 report received
6. [main] Wrap-up table to the user

| Step | Who | Why |
|---|---|---|
| Diagnose + fix + tests | main | Writing code, debugging |
| Version (patch), changelog wording, commit messages | main | Judgment, user-facing text |
| Local commits + annotated tag | main | One command each; lets the brief pin exact SHAs; I see the tree before anything leaves |
| Preflight (ls-remote, npm view, trust list, workflow state) | main | Six quick read-only commands; results become brief inputs; not worth a cold start |
| Push main + tag, find and watch run, wait for npm, install check | haiku (one agent) | Fully specified, long waits (CI, registry), checkable from outside. Single item, so the quick install check rides in the same agent as the long wait |
| Verification | main | Every report is a claim |
| Close issue #41, GitHub Release | nobody | Not approved, not in RELEASING.md |

## Main-model work (done locally)

- Cause: `.replace(/\s/g, '-')` maps every whitespace char to a dash, and `-` survives the punctuation strip, so `'Rock - Paper'` -> `rock---paper`.
- Fix (src/index.js, 1 line): `.replace(/\s/g, '-')` -> `.replace(/[\s-]+/g, '-')`.
- Tests (test/slugify.test.js, +9): `'Hello   World'` -> `hello-world`; `'Rock - Paper'` -> `rock-paper`; `'a--b'` -> `a-b`. Both new tests failed on the old source (2 fail), pass with the fix.
- package.json `2.3.0` -> `2.3.1` (sed, no `npm version`, no reformatting). CHANGELOG.md: new `## 2.3.1` section citing (#41).
- Commits on main (on top of origin main `7d0bf664bb487e6172eb006e38a3d4501545f225`):
  - `18c3ee919ec30fd1b890528591a6041547de9144` fix: collapse runs of spaces and dashes into one dash (#41)
  - `8c9b69f4bf83204a6632546f188b56aae8576bcf` chore(release): v2.3.1
- Tag `v2.3.1`: annotated, message `v2.3.1` (matches v2.3.0's style), tag object `44775b49a046ce8d98fb92edd7afd3108a95eb22` -> commit `8c9b69f…`.
- Diff 7d0bf66..HEAD: 4 files, +15 −2 (CHANGELOG.md +4, package.json ±1, src/index.js ±1, test/slugify.test.js +9).

Test output (at HEAD):
```
✔ lowercases and dashes words
✔ strips punctuation
✔ removes accents
✔ collapses repeated spaces into one dash (#41)
✔ collapses runs of spaces and dashes into one dash (#41)
ℹ tests 5  ℹ pass 5  ℹ fail 0
```
Not fixed (out of scope of #41, pre-existing): leading/trailing separators still give an edge dash, e.g. `'Hello !'` -> `hello-`.

## Approvals and side effects

- Push main (2 commits): no workflow runs on branch pushes. Approved.
- Push tag v2.3.1: starts `release.yml` (`npm test`, `npm publish --provenance` via trusted publishing). That is the publish. Approved. No `npm publish` anywhere in the brief, and it is under Do not.
- Commit messages use `(#41)`, not `Fixes #41`, so issue #41 stays open (closing it was not approved).
- No local publish planned, so no race with CI. No 2FA concern (OIDC publish).
- Heads-up to user (one line, before launch): "Pushing main and v2.3.1 to quillkit/slug now; the tag push makes the release workflow publish 2.3.1 to npm."

## Preflight (main, read-only; network, so written down, not run)

| Command | Expected |
|---|---|
| `git ls-remote origin refs/heads/main refs/tags/v2.3.1` | one line: `7d0bf664bb487e6172eb006e38a3d4501545f225	refs/heads/main` |
| `npm view @quillkit/slug versions --json --prefer-online` | array ending `"2.3.0"`, no `"2.3.1"` |
| `npm trust list @quillkit/slug` | GitHub Actions publisher, repo `quillkit/slug`, workflow `release.yml` |
| `gh api repos/quillkit/slug/actions/workflows --jq '.workflows[] \| [.path,.state] \| @tsv'` | `.github/workflows/release.yml	active` |
| `gh run list --repo quillkit/slug --workflow release.yml --limit 1 --json conclusion` | `[{"conclusion":"success"}]` (the v2.3.0 run) |

Skipped on purpose: `npm pack` integrity pin (nothing gitignored ships; `files: ["src"]` is tracked and CI packs from the tag), `npm profile get` 2FA check (CI publishes). If any row differs: stop, launch nothing, tell the user.

## Launch

One agent, launched as soon as preflight passes:

```
Agent({ description: "Release @quillkit/slug 2.3.1", subagent_type: "haiku-worker",
        model: "haiku", run_in_background: true,
        prompt: <contents of briefs/01-release-slug-2.3.1.md> })
```

## Verification after brief 01 reports

| Claim | Command | Should print |
|---|---|---|
| push main | `gh api repos/quillkit/slug/commits/main --jq .sha` | `8c9b69f4bf83204a6632546f188b56aae8576bcf` |
| push tag | `gh api repos/quillkit/slug/git/ref/tags/v2.3.1 --jq '.object.type+" "+.object.sha'` | `tag 44775b49a046ce8d98fb92edd7afd3108a95eb22` |
| tag commit | `gh api repos/quillkit/slug/commits/v2.3.1 --jq .sha` | `8c9b69f4bf83204a6632546f188b56aae8576bcf` |
| release run | `gh run list --repo quillkit/slug --commit 8c9b69f4bf83204a6632546f188b56aae8576bcf --json workflowName,conclusion` | `[{"conclusion":"success","workflowName":"release"}]` |
| published from tag | `npm view @quillkit/slug@2.3.1 version gitHead --prefer-online` | `version = '2.3.1'`, `gitHead = '8c9b69f4bf83204a6632546f188b56aae8576bcf'` |
| latest | `npm view @quillkit/slug dist-tags.latest --prefer-online` | `2.3.1` |
| install | accept the agent's quoted lines | `hello-world`, `rock-paper`, `@quillkit/slug@2.3.1` |

Failure handling: run failed -> I read the log (debugging is mine); fix-forward as 2.3.2 vs moving the tag is the user's call. Push rejected / auth / NEEDS_USER -> to the user with the exact command. Install skipped because run failed -> nothing to relaunch until the publish exists.

## Wrap-up (if everything verifies)

| Item | Result | Evidence |
|---|---|---|
| Fix #41 | committed | `18c3ee9` on main, 5/5 tests pass |
| main | pushed | [main @ 8c9b69f](https://github.com/quillkit/slug/commit/8c9b69f4bf83204a6632546f188b56aae8576bcf) |
| v2.3.1 tag | pushed (annotated) | [v2.3.1](https://github.com/quillkit/slug/tree/v2.3.1) |
| release run | success | run URL from report, confirmed by `gh run list` |
| @quillkit/slug 2.3.1 | published by CI, gitHead = tagged commit | [npm](https://www.npmjs.com/package/@quillkit/slug/v/2.3.1) |
| clean install | `hello-world`, `rock-paper` | agent's quoted output |

**Left:** issue #41 still open; no GitHub Release (RELEASING.md doesn't ask for one); trailing/leading-dash edge case not addressed.
**Needs you:** close [#41](https://github.com/quillkit/slug/issues/41) if you're happy, or tell me to.
