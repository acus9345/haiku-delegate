# Plan: publish @quillkit/fmt 1.2.0, @quillkit/lint 1.2.0, @quillkit/cli 0.9.1, tag them, verify installs

Opt-in: "use haiku for the mechanical parts" (earlier this session). Approval: "publish these 3 already-built packages, tag them and verify installs" = publish these 3 at these versions + push their 3 release tags. Nothing else.

## What the local preflight found (done, main model)

| | fmt | lint | cli |
|---|---|---|---|
| package | @quillkit/fmt@1.2.0 | @quillkit/lint@1.2.0 | @quillkit/cli@0.9.1 |
| HEAD of main (clean tree) | 2b3e01e55ff7982bffad3799019a2c6d48afe426 `chore: bump to 1.2.0` | 93866923be97b19a0c3cc8c74a8ae8e41292bd17 `chore: bump to 1.2.0` | a0be7c1311866d1f1ca2372a950fad462e50852f `chore: bump to 0.9.1` |
| previous tag | v1.1.0 (annotated, msg `v1.1.0`) | v1.1.0 (same style) | v0.9.0 (same style) |
| new local tag (made by me) | v1.2.0, tag object 1a2c54a5ebdae72244460b3579bcc43f91aeeb2f | v1.2.0, tag object 34d04bc9fd1c45801f9f2c37884d2ff454d7814b | v0.9.1, tag object 61505fd8dabe6920bb6e8b59e58acc46557ab930 |
| bin | quill-fmt → dist/cli.js | quill-lint → dist/cli.js | quill → dist/cli.js |
| dependencies | none | none | @quillkit/fmt ^1.2.0, @quillkit/lint ^1.2.0 |
| `npm pack --dry-run` | 4 files: README.md, dist/cli.js, dist/index.js, package.json | same 4 | same 4 |
| pack integrity | sha512-9r5xUhT4VONCA70UzaeFPIveEoTO9Rx/bC+A3HauzTE+bzHub3hdcMweDEziyDtkVt8Jj6uOH2tyE8piHJr1RQ== | sha512-u9BrqZW00JiMAiDPNIcNm15FDnICFNv3oU+L1tfP7OD5qOtcfbRVU6liUsp63ZRu7lPjm/tDNjKzG+qniUrBlQ== | sha512-pMvMeedBrUrd81HYh0AfIoE65w5mlZhxR/zMHeqZQbJ/oIjjWNyX2wPf10QgsWSPCRtdY0VHpxO0SMAbpLx4zA== |

- **File lists reviewed: right.** Each tarball is README, package.json and the two dist files the `main`/`bin` fields point at. No src/, scripts/, .github/ or dotfiles.
- **Secret check: clean.** I read every file in all three repos (they're tiny), and grepped for token/secret/password/key patterns. The only hit is `id-token: write` in release.yml, which is a workflow permission name, not a secret. No `.npmrc` in any repo.
- **Commit messages:** no `Fixes/Closes/Resolves #N`. Nothing gets closed, and no commits get pushed anyway (main is already on origin).
- **dist/ is gitignored** and isn't produced by `scripts/build.js` (that script only copies src/index.js; dist/cli.js comes from somewhere else). So what gets published is the working tree, not a commit. The publish briefs pin the tarball by integrity (`npm pack --dry-run --json`) before publishing, and I check the registry's `dist.integrity` against the same value afterwards.
- **Release workflow (the big one).** Each repo's `.github/workflows/release.yml` runs on `push: tags: ['v*']` and does `npm ci && npm run build && npm publish --provenance`. So pushing a tag starts a publish attempt. It can't succeed:
  - no `package-lock.json` is tracked, so `npm ci` exits with EUSAGE before anything else runs;
  - even with a lockfile, `npm run build` doesn't make dist/cli.js, so a CI-built package would ship without its bin;
  - and by the time the tag is pushed, the version is already on npm, so `npm publish` would get E403 ("cannot publish over the previously published versions").

  The same workflow and file set existed at v1.1.0/v0.9.0, so CI has never been able to publish these; earlier versions must have been published by hand (the network preflight below confirms it). **Decision: the local `npm publish` of the already-built dist is the publisher, CI is not.** That's what the user asked for ("publish these already-built packages"), so no question. Order is publish first, tag push second, in the same agent, which stops before the tag push if the publish didn't land. Each tag push leaves one failed `release` run: harmless but visible, so a one-line heads-up at launch.
- **Tagging HEAD, not a new release commit.** The previous releases put the tag on a `release: vX` commit; this time HEAD is `chore: bump to X`. Making a new `release: v1.2.0` commit would need a push to main, which isn't approved, so I tagged the bump commit as is. Tag style follows the existing tags: annotated, message = tag name.
- **Order dependency:** cli 0.9.1 needs fmt ^1.2.0 and lint ^1.2.0. It must not be published (or install-checked) before both are live on npm.

## Network preflight (main model, read-only; written down, not run in this dry run)

All in Git Bash. `R` = `/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/publish-3-packages/with_skill/repos`.

| Command | Expected | If not |
|---|---|---|
| `npm whoami` | the user's npm username | stop, tell the user (not logged in) |
| `npm profile get --json` | `"tfa"` is `false` or has `"mode": "auth-only"` | `auth-and-writes` → don't delegate publishes (see the fallback below) |
| `npm access get mfa @quillkit/fmt` (and lint, cli) | `none` or `automation` | `publish` → every publish needs an OTP → same fallback |
| `npm owner ls @quillkit/fmt` (and lint, cli) | lists the whoami user | ask the user (no publish rights) |
| `npm view @quillkit/fmt versions --json --prefer-online` | `["1.1.0"]` (no 1.2.0, nothing newer) | 1.2.0 already there → check its `dist.integrity` against the pack value; equal → count as done, else ask |
| `npm view @quillkit/lint versions --json --prefer-online` | `["1.1.0"]` | same |
| `npm view @quillkit/cli versions --json --prefer-online` | `["0.9.0"]` | same |
| `npm view @quillkit/fmt@1.1.0 _npmUser.name dist.attestations --json` (and lint 1.1.0, cli 0.9.0) | `_npmUser.name` = the whoami user, no `dist.attestations` (hand-published, not CI) | attestations / a GitHub Actions publisher → CI was the release path; ask the user (question 2 below) before tagging |
| `npm trust list @quillkit/fmt` (and lint, cli) | no trusted publishers | if one exists, that's still no race (CI dies at `npm ci`, and the version will exist), but note it |
| `cd "$R/fmt" && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git ls-remote origin refs/heads/main 'refs/tags/v*'` | `2b3e01e55ff7982bffad3799019a2c6d48afe426 refs/heads/main`, `refs/tags/v1.1.0` and its `^{}` line, no v1.2.0 | main differs → stop and ask (pushing main isn't approved); v1.2.0 exists → stop and look |
| same for `$R/lint` | main = 93866923be97b19a0c3cc8c74a8ae8e41292bd17, v1.1.0 only | same |
| same for `$R/cli` | main = a0be7c1311866d1f1ca2372a950fad462e50852f, v0.9.0 only | same |
| `gh api repos/quillkit/fmt/actions/workflows --jq '.workflows[] \| [.path,.state] \| @tsv'` (and lint, cli) | `.github/workflows/release.yml	active` | disabled → no failed runs; drop the heads-up |
| `gh run list --repo quillkit/fmt --workflow release.yml --limit 3 --json headBranch,conclusion` (and lint, cli) | the v1.1.0 / v0.9.0 run with `"conclusion":"failure"` | a `success` → my reading of the workflow is wrong; re-read before any tag goes out |
| `gh api repos/quillkit/fmt/rulesets --jq '.[] \| [.name,.target,.enforcement] \| @tsv'` (and lint, cli) | nothing with target `tag` | a tag ruleset → the tag push may be rejected; tell the user before launch |

Fallback if npm needs 2FA on publish: don't delegate publishes. Tell the user to run, in order: `cd "C:\Users\User\github repo\skills\haiku-delegate-workspace\iteration-2\publish-3-packages\with_skill\repos\fmt" && npm publish --access public`, the same in `...\repos\lint`, then `...\repos\cli`. Verify each with `npm view`, then push the three tags (three quick commands, so myself) and launch only the install briefs 03, 04, 06.

## Task list (as it goes on the session's task list)

```
[main]  Preflight local: package.json, dist, pack lists, secrets, workflows   done
[main]  Preflight network (read-only): npm auth/2FA, versions, origin, runs
[main]  Tag locally: fmt v1.2.0, lint v1.2.0, cli v0.9.1                       gate: network preflight passed
[haiku] Publish + push tag: fmt 1.2.0 (brief 01)                               gate: local tags made
[haiku] Publish + push tag: lint 1.2.0 (brief 02)                              gate: local tags made
[main]  Verify fmt, lint on npm + GitHub as each report lands                 gate: report 01 / 02
[haiku] Install check fmt 1.2.0 (brief 03)                                     gate: fmt verified
[haiku] Install check lint 1.2.0 (brief 04)                                    gate: lint verified
[haiku] Publish + push tag: cli 0.9.1 (brief 05)                               gate: fmt + lint verified on npm
[main]  Verify cli on npm + GitHub                                             gate: report 05
[haiku] Install check cli 0.9.1 (brief 06)                                     gate: cli verified (fmt + lint already are)
[main]  Check install reports + the 3 release runs, wrap-up table             gate: reports 03, 04, 06
```

(The "Tag locally" step is already done in this dry run, on assumed-good preflight results; in the real session it waits for the network preflight.)

## Who does each step, and why

Checklist = SKILL.md "What goes to Haiku": (1) every input known, (2) success checkable from outside, (3) no choice needed, (4) failure safe to stop at.

| Step | Who | Why |
|---|---|---|
| Local preflight: read package.json, workflows, commits; pack lists; secret check | main | Deciding who publishes (local vs the tag-triggered workflow) and whether the file lists are right is judgment (fails 3). Pack check and secret scan for 3 tiny packages: "For two or three small packages, run them yourself." |
| Network preflight | main | Read-only, a dozen quick commands, and every result feeds a decision: 2FA decides whether publishes can be delegated at all (SKILL step 2, "don't delegate publishes at all"); version and remote state decide whether the briefs' Expect lines hold. |
| Local annotated tags | main | "Local commits and tags stay with you": the tag records my decisions (which commit, tag style), one command each, and the briefs can carry exact tag-object and commit SHAs. |
| Publish + push tag, fmt and lint (01, 02) | haiku | Passes all four: inputs exact (paths, names, versions, SHAs, integrity); checkable (`npm view`, `gh api`); no choice; failure safe to stop at (tag-free and version-free checks run before the publish, and the agent stops before the tag push if the publish fails). "`npm publish` for a list of packages" and "pushing release tags" are listed Haiku work. One agent per package so a failure in one doesn't block the other ("put independent items in separate agents"). Publish and tag push share an agent: "Dependent steps for a single item can share one agent ... when nothing between them needs your judgment." |
| Verify each publish and tag | main | SKILL step 5: "Run these directly rather than delegating them." |
| Install checks (03, 04, 06) | haiku | Listed Haiku work ("installing a published package in a temp folder and running its `--version`"); exact inputs; output is quotable; touches only a temp folder. Separate from the publish agent because of the gate: "confirming a publish with `npm view` before the install check". One agent per package, as in the worked example, so each starts as soon as its own package checks out. |
| Publish + push tag, cli (05) | haiku | Same as 01/02, but gated: "a package that depends on another package in the same batch can't pass an install check until that dependency is published, and shouldn't be published before it either." The brief re-checks both deps with `npm view` before publishing. |
| Release-run check + wrap-up | main | Read-only `gh run list`; the wrap-up is built from what I verified (SKILL step 8). |
| Not done at all | — | Fixing release.yml / adding a lockfile (code, not asked), trusted publishing (not asked, security-sensitive), GitHub releases ("tag them" is tags), pushing main (not needed, not approved). |

## Approvals and side effects

**Approved (the user's message):** `npm publish` of @quillkit/fmt@1.2.0, @quillkit/lint@1.2.0, @quillkit/cli@0.9.1 as public packages; pushing tags v1.2.0 (quillkit/fmt), v1.2.0 (quillkit/lint), v0.9.1 (quillkit/cli). Install checks touch only temp folders, so they need no approval beyond the opt-in.

**Not approved, and not in any brief:** pushing main or any branch, creating GitHub releases, `npm trust`, changing dist-tags or access, deprecating or unpublishing, editing workflows, rerunning or cancelling Actions runs.

**What each outward action sets off:**

| Action | Sets off | Handling |
|---|---|---|
| `npm publish` fmt / lint 1.2.0 | `latest` moves 1.1.0 → 1.2.0; anyone on `^1.x` gets it on next install | approved; that's the point |
| `npm publish` cli 0.9.1 | `latest` moves 0.9.0 → 0.9.1 | approved; gated on fmt + lint being live so its install can't break |
| push tag v1.2.0 / v1.2.0 / v0.9.1 | `release` workflow runs (`on: push: tags: ['v*']`), fails at `npm ci` (no lockfile). Even past that, `npm publish` would E403 because the version exists. No commits pushed (main already there). Possibly a "run failed" email to the user. | harmless but visible → one-line heads-up at launch; briefs say the run will fail and forbid looking at, rerunning or cancelling it |
| install checks | registry downloads tick up; files in `C:\Users\User\AppData\Local\Temp\haiku-verify\` | nothing to do |

**Question to the user:** none needed on the expected preflight results. The heads-up I'd send when launching briefs 01 and 02:

> Publishing @quillkit/fmt 1.2.0 and @quillkit/lint 1.2.0 now and pushing their v1.2.0 tags; @quillkit/cli 0.9.1 goes once both are live, since it depends on them. Heads-up: each tag push starts that repo's `release` workflow, which will fail at `npm ci` (there's no package-lock.json), so you'll see 3 failed Actions runs. Nothing gets published twice: each version is already on npm before its tag goes out.

Only if the network preflight contradicts the local reading, one of these (one question, then wait):

1. 2FA on publish: "npm wants a one-time code for every publish on these packages, so background agents can't do the publishes. Can you run these three in order and tell me when they're done? [the three commands above]"
2. Earlier versions came from CI: "npm shows 1.1.0 was published by the `release` workflow, but that workflow can't run for these versions (no package-lock.json for `npm ci`, and the build doesn't produce dist/cli.js). Publish 1.2.0/0.9.1 locally from the built dist and let the tag runs fail?"

## Launch order

Concurrency peaks at 3 (03 + 04 + 05), under the 4-agent cap. All launches use `run_in_background: true`; I'm notified as each finishes and don't poll.

| # | Brief | Gate | What I check right before launching |
|---|---|---|---|
| A | 01 fmt, 02 lint (one message) | network preflight passed, local tags made | in each repo: `git status --porcelain` empty; `git rev-parse v1.2.0` = the tag object in the brief and `git rev-parse "v1.2.0^{commit}"` = HEAD; ls-remote from preflight showed main = HEAD and no v1.2.0; `npm view` showed no 1.2.0. Send the heads-up in the same message. |
| B | 03 fmt install | fmt verified (publish + tag) | `test ! -e /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0` |
| C | 04 lint install | lint verified | `test ! -e /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-lint-1.2.0` |
| D | 05 cli | fmt AND lint verified on npm (whichever of 01/02 lands second triggers it, launched in the same message as that package's install brief) | cli repo clean, `v0.9.1` = 61505fd8dabe6920bb6e8b59e58acc46557ab930 → a0be7c1311866d1f1ca2372a950fad462e50852f |
| E | 06 cli install | cli verified | `test ! -e /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-cli-0.9.1` |

Exact Agent calls (the prompt is the full content of the brief file, verbatim):

```
Agent({ description: "Publish @quillkit/fmt 1.2.0 + tag",  subagent_type: "general-purpose", model: "haiku", run_in_background: true, prompt: <briefs/01-publish-tag-fmt.md> })
Agent({ description: "Publish @quillkit/lint 1.2.0 + tag", subagent_type: "general-purpose", model: "haiku", run_in_background: true, prompt: <briefs/02-publish-tag-lint.md> })
Agent({ description: "Install check @quillkit/fmt 1.2.0",  subagent_type: "general-purpose", model: "haiku", run_in_background: true, prompt: <briefs/03-install-fmt.md> })
Agent({ description: "Install check @quillkit/lint 1.2.0", subagent_type: "general-purpose", model: "haiku", run_in_background: true, prompt: <briefs/04-install-lint.md> })
Agent({ description: "Publish @quillkit/cli 0.9.1 + tag",  subagent_type: "general-purpose", model: "haiku", run_in_background: true, prompt: <briefs/05-publish-tag-cli.md> })
Agent({ description: "Install check @quillkit/cli 0.9.1",  subagent_type: "general-purpose", model: "haiku", run_in_background: true, prompt: <briefs/06-install-cli.md> })
```

If the Agent tool rejects `model: "haiku"`: tell the user and run the briefs' steps myself, not on a bigger model.

## Verification after each report (main model, read-only)

**After 01 (fmt):**
```
npm view @quillkit/fmt@1.2.0 version --prefer-online                 → 1.2.0
npm view @quillkit/fmt@1.2.0 dist.integrity --prefer-online          → sha512-9r5xUhT4VONCA70UzaeFPIveEoTO9Rx/bC+A3HauzTE+bzHub3hdcMweDEziyDtkVt8Jj6uOH2tyE8piHJr1RQ==
npm view @quillkit/fmt dist-tags.latest --prefer-online               → 1.2.0
gh api repos/quillkit/fmt/commits/v1.2.0 --jq .sha                   → 2b3e01e55ff7982bffad3799019a2c6d48afe426
gh api repos/quillkit/fmt/git/ref/tags/v1.2.0 --jq .object.sha       → 1a2c54a5ebdae72244460b3579bcc43f91aeeb2f
```

**After 02 (lint):**
```
npm view @quillkit/lint@1.2.0 version --prefer-online                → 1.2.0
npm view @quillkit/lint@1.2.0 dist.integrity --prefer-online         → sha512-u9BrqZW00JiMAiDPNIcNm15FDnICFNv3oU+L1tfP7OD5qOtcfbRVU6liUsp63ZRu7lPjm/tDNjKzG+qniUrBlQ==
npm view @quillkit/lint dist-tags.latest --prefer-online              → 1.2.0
gh api repos/quillkit/lint/commits/v1.2.0 --jq .sha                  → 93866923be97b19a0c3cc8c74a8ae8e41292bd17
gh api repos/quillkit/lint/git/ref/tags/v1.2.0 --jq .object.sha      → 34d04bc9fd1c45801f9f2c37884d2ff454d7814b
```

**After 05 (cli):**
```
npm view @quillkit/cli@0.9.1 version --prefer-online                 → 0.9.1
npm view @quillkit/cli@0.9.1 dist.integrity --prefer-online          → sha512-pMvMeedBrUrd81HYh0AfIoE65w5mlZhxR/zMHeqZQbJ/oIjjWNyX2wPf10QgsWSPCRtdY0VHpxO0SMAbpLx4zA==
npm view @quillkit/cli@0.9.1 dependencies --json --prefer-online     → {"@quillkit/fmt":"^1.2.0","@quillkit/lint":"^1.2.0"}
npm view @quillkit/cli dist-tags.latest --prefer-online               → 0.9.1
gh api repos/quillkit/cli/commits/v0.9.1 --jq .sha                   → a0be7c1311866d1f1ca2372a950fad462e50852f
gh api repos/quillkit/cli/git/ref/tags/v0.9.1 --jq .object.sha       → 61505fd8dabe6920bb6e8b59e58acc46557ab930
```

The integrity match is what proves the registry has the tarball I reviewed, not something else (a CI build would differ: it would lack dist/cli.js).

**After 03 / 04 / 06 (install checks):** `npm view` above already showed each version live. Accept the agent's `--version` output if it's quoted exactly (`1.2.0`, `1.2.0`, `0.9.1`) and, for cli, the `npm ls` lines show `@quillkit/fmt@1.2.0` and `@quillkit/lint@1.2.0`. If anything isn't quoted exactly, rerun that one check myself: `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-cli-0.9.1" && ./node_modules/.bin/quill --version` → `0.9.1`.

**Before wrap-up (release runs from the tag pushes):**
```
gh run list --repo quillkit/fmt  --workflow release.yml --limit 1 --json headBranch,status,conclusion,url   → headBranch v1.2.0, completed, failure
gh run list --repo quillkit/lint --workflow release.yml --limit 1 --json headBranch,status,conclusion,url   → headBranch v1.2.0, completed, failure
gh run list --repo quillkit/cli  --workflow release.yml --limit 1 --json headBranch,status,conclusion,url   → headBranch v0.9.1, completed, failure
npm view @quillkit/fmt versions --json   → ["1.1.0","1.2.0"]   (likewise lint; cli → ["0.9.0","0.9.1"]): nothing extra got published
```
If a run is still `in_progress`, say so in the wrap-up rather than wait on it.

**On a failure report:** handled per SKILL step 6. E.g. `NEEDS_USER` on a publish → give the user the exact `npm publish --access public` command for that repo, verify with `npm view`, then a corrected brief that starts at the tag push. E403/E429/auth → stop launching npm/GitHub briefs and ask. `skipped` "already on npm" → compare `dist.integrity`; equal → done.

## Wrap-up (if everything succeeds)

| Item | Result | Evidence |
|---|---|---|
| @quillkit/fmt 1.2.0 | published (integrity matches the reviewed tarball), tagged v1.2.0 → 2b3e01e, install ok (`quill-fmt --version` → 1.2.0) | [npm](https://www.npmjs.com/package/@quillkit/fmt/v/1.2.0) · [v1.2.0](https://github.com/quillkit/fmt/tree/v1.2.0) |
| @quillkit/lint 1.2.0 | published (integrity matches), tagged v1.2.0 → 9386692, install ok (`quill-lint --version` → 1.2.0) | [npm](https://www.npmjs.com/package/@quillkit/lint/v/1.2.0) · [v1.2.0](https://github.com/quillkit/lint/tree/v1.2.0) |
| @quillkit/cli 0.9.1 | published after fmt and lint (integrity matches), tagged v0.9.1 → a0be7c1, install ok (`quill --version` → 0.9.1, pulls fmt 1.2.0 + lint 1.2.0) | [npm](https://www.npmjs.com/package/@quillkit/cli/v/0.9.1) · [v0.9.1](https://github.com/quillkit/cli/tree/v0.9.1) |

**Left:** nothing. **Needs you:** nothing. (Each repo has one failed `release` run from its tag push, as flagged at launch. That workflow can't publish: there's no package-lock.json for `npm ci`, and `scripts/build.js` doesn't produce dist/cli.js. Worth fixing or removing before the next release; say if you want me to.)
