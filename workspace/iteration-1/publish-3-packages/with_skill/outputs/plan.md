# Plan: publish, tag and install-check @quillkit/fmt, @quillkit/lint, @quillkit/cli

Session context: the user opted in earlier ("use haiku for the mechanical parts"). The request now is "publish these 3 already-built packages, tag them and verify installs".

## 0. What the main model already found (local, read-only, actually run)

| Repo | package.json | HEAD of main (clean, = `chore: bump to …`) | Last tag | bin | Notes |
|---|---|---|---|---|---|
| fmt | `@quillkit/fmt` 1.2.0, `publishConfig.access: public`, `files: ["dist"]` | `2b3e01e55ff7982bffad3799019a2c6d48afe426` | `v1.1.0` (annotated, message `v1.1.0`) | `quill-fmt` → dist/cli.js | |
| lint | `@quillkit/lint` 1.2.0, same shape | `93866923be97b19a0c3cc8c74a8ae8e41292bd17` | `v1.1.0` (annotated, message `v1.1.0`) | `quill-lint` → dist/cli.js | |
| cli | `@quillkit/cli` 0.9.1, same shape | `a0be7c1311866d1f1ca2372a950fad462e50852f` | `v0.9.0` (annotated, message `v0.9.0`) | `quill` → dist/cli.js | depends on `@quillkit/fmt ^1.2.0`, `@quillkit/lint ^1.2.0` |

- The only change since each repo's last tag is the version line in package.json.
- `dist/` exists in all three, is git-ignored, and `dist/index.js` is byte-identical to `src/index.js`. `dist/cli.js` prints `require('../package.json').version` on `--version`.
- `npm pack --dry-run --offline` (run by me, npm cache pointed at the scratchpad): each tarball has exactly 4 files: README.md, dist/cli.js, dist/index.js, package.json. Integrity:
  - fmt: `sha512-9r5xUhT4VONCA70UzaeFPIveEoTO9Rx/bC+A3HauzTE+bzHub3hdcMweDEziyDtkVt8Jj6uOH2tyE8piHJr1RQ==`
  - lint: `sha512-u9BrqZW00JiMAiDPNIcNm15FDnICFNv3oU+L1tfP7OD5qOtcfbRVU6liUsp63ZRu7lPjm/tDNjKzG+qniUrBlQ==`
  - cli: `sha512-pMvMeedBrUrd81HYh0AfIoE65w5mlZhxR/zMHeqZQbJ/oIjjWNyX2wPf10QgsWSPCRtdY0VHpxO0SMAbpLx4zA==`
- Secret check: I read all 4 published files in each package myself (they are 35 to 469 bytes). Nothing secret. No scanner needed.
- Git: origin is `https://github.com/quillkit/<name>.git`. There's no local `origin/main` ref, so "main is pushed" has to be confirmed on GitHub (preflight below). `user.name`/`user.email` are set, so `git tag -a` will work. The credential helper is Git Credential Manager (`manager`), which can open a GUI login window and hang a background command. The briefs set `GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never` on every git network command so that fails loudly instead.
- Tools: node v24.16.0, npm 12.2.0, git 2.45.1.windows.1. `C:\Users\User\AppData\Local\Temp\haiku-verify\` doesn't exist yet. The install briefs create it with `mkdir -p`.
- **Surprise: tag-triggered release workflow.** Each repo has `.github/workflows/release.yml` on `push: tags: ['v*']` that runs `npm ci && npm run build && npm publish --provenance`. No repo has a package-lock.json, so that run fails at `npm ci` before it can publish. So pushing our tags can't double-publish, but it will leave one failed Actions run per repo. (Even with a lockfile, `scripts/build.js` only copies index.js and never produces dist/cli.js, so CI-built packages would ship without their bin.) The user didn't ask for this to be fixed, so I'm leaving it alone and reporting it.
- Side note: cli 0.9.0 already declared `^1.2.0` deps, so if 0.9.0 is on npm it can't be installed today. It will start resolving once fmt/lint 1.2.0 are out. Not in scope, so I'll mention it only if preflight shows 0.9.0 is published.

Tag names and messages follow the repos' existing convention: annotated `vX.Y.Z` with message `vX.Y.Z`, on the exact HEAD SHA above (not on whatever HEAD is at run time).

## 1. Task list (as it goes on the session's task list)

```
[main]  Preflight: manifests, dist/, pack file lists, git state, tag convention
[main]  Preflight (read-only network): npm auth/2FA/access, versions free, remote main SHAs, tags absent, release.yml history
[haiku] Wave 1: publish + tag @quillkit/fmt 1.2.0 (agent 01)
[haiku] Wave 1: publish + tag @quillkit/lint 1.2.0 (agent 02)
[main]  Verify fmt and lint on npm and GitHub
[haiku] Wave 2: publish + tag @quillkit/cli 0.9.1, after fmt+lint verified (agent 03)
[haiku] Wave 2: install check @quillkit/fmt 1.2.0, after fmt verified (agent 04)
[haiku] Wave 2: install check @quillkit/lint 1.2.0, after lint verified (agent 05)
[main]  Verify cli on npm and GitHub; check fmt/lint install reports
[haiku] Wave 3: install check @quillkit/cli 0.9.1 (agent 06)
[main]  Verify cli install; wrap-up table
```

## 2. Every step: who and why

Checklist = the four tests in SKILL.md "What goes to Haiku": (1) every input known, (2) success checkable from outside, (3) no choice needed, (4) failure safe to stop at.

| # | Step | Who | Why |
|---|---|---|---|
| P1 | Read package.json, dist/, src/, README, workflows, build script | main | Understanding the repos is the deliverable here: this is where the release.yml and build.js problems turned up. Fails (3). The worked example also does this on main ("Main model first"). |
| P2 | `npm pack --dry-run` ×3 and judge the file lists | main | The skill lists this as Haiku work, but it's 3 fast local commands ("one or two quick commands are cheaper to run yourself"), and judging the list is mine anyway (not-for-haiku.md gray area). |
| P3 | Secret check | main | 12 tiny files that I'd already read. A scanner plus triage would cost more than reading them. Triage is mine regardless (not-for-haiku.md). |
| P4 | Local git state, existing tag convention, pin SHAs | main | Choosing the tag name/message and the commit is naming/judgment. Fails (3) until decided, then becomes an exact input. |
| P5 | Network preflight: `npm whoami`, 2FA mode, access, versions free, remote main SHA, tags absent, past release.yml runs | main | Read-only checks whose results decide whether the plan holds at all (e.g. 2FA-on-publish makes every publish brief a guaranteed NEEDS_USER). That's a judgment call. Fails (3). |
| P6 | Order: cli after fmt+lint are live | main | Cross-item dependency (SKILL.md step 1). Publishing cli first would put an uninstallable 0.9.1 on npm if fmt/lint then failed, and only unpublish could undo that, which fails (4). |
| H1 | 01: publish + tag fmt | haiku | Passes all four. (1) name, version, SHA, tag, message, remote are exact. (2) `npm view`, `gh api`. (3) no choices left. (4) pre-checks run before publish, and a failure after publish leaves only a missing tag, which a tag-only brief can add. "`npm publish` for a list of packages" and "pushing release tags" are both on the typical-Haiku list. Publish and tag share one agent, as SKILL.md step 4 allows for a single item. |
| H2 | 02: publish + tag lint | haiku | Same as H1. Separate agent from fmt so one failure doesn't block the other (brief-template "Several items in one agent"). |
| V1 | Verify fmt, lint | main | SKILL.md step 5: reports are claims, so I run cheap read-only checks myself. |
| H3 | 03: publish + tag cli | haiku | Same as H1, gated on V1 for both deps. The brief also re-reads both deps on npm before publishing. |
| H4 | 04: install check fmt | haiku | On the typical list. Local temp folder only, no approval needed beyond the opt-in. Noisy install output stays out of my context. Separate from 01 so the publish agent's file rules stay "none", and so a propagation ETARGET doesn't get mixed into the publish chain. |
| H5 | 05: install check lint | haiku | Same as H4. |
| V2 | Verify cli; read 04/05 evidence | main | SKILL.md step 5. |
| H6 | 06: install check cli | haiku | Same as H4. Needs cli live (V2), and fmt/lint live (V1). |
| V3 | Verify 06, final informational CI check | main | SKILL.md step 5. |
| W | Wrap-up table | main | User-facing writing (not-for-haiku.md), built from verified results only (SKILL.md step 8). |
| F | Any failure diagnosis / corrected briefs | main | SKILL.md step 6, not-for-haiku.md "Debugging failures". |

Not doing at all, because nobody asked: GitHub releases, trusted publishing / `npm trust`, fixing release.yml or build.js, adding lockfiles, pushing to main, dist-tag changes.

## 3. Approvals

- **Already approved by the user's message:** `npm publish` of `@quillkit/fmt@1.2.0`, `@quillkit/lint@1.2.0` and `@quillkit/cli@0.9.1` as public packages (all three already have `publishConfig.access: public`), and pushing tags `v1.2.0` (quillkit/fmt), `v1.2.0` (quillkit/lint) and `v0.9.1` (quillkit/cli) to their origins.
- **Needs no approval:** install checks in fresh folders under `C:\Users\User\AppData\Local\Temp\haiku-verify\` (local, outside the user's repos), and every read-only preflight/verification command.
- **Not approved, and not in the plan:** pushing branches, creating GitHub releases, trusted publishing, editing workflows/build scripts/package files, changing git credential config (e.g. `gh auth setup-git`), rerunning or cancelling Actions runs.
- **Blocking question before launch:** none, if preflight comes back as expected. What I'd send instead, as a one-line heads-up while wave 1 launches:
  > Heads-up: pushing each `v*` tag triggers the repo's release.yml. It will fail at `npm ci` (none of the repos has a package-lock.json), so it can't publish anything twice, but you'll see 3 failed Actions runs. I'm not touching the workflow.
- **Conditional questions** (only if a preflight check comes back differently; written now so they're exact):
  - If `npm profile get --json` shows `"tfa":{"mode":"auth-and-writes"…}` (every publish needs an OTP), I don't launch wave 1, since all three publish briefs would stop at NEEDS_USER. I'd ask:
    > npm asks for a 2FA code on every publish for your account, and neither I nor the agents can enter one. Could you run `npm publish --access public` yourself in `repos\fmt` and `repos\lint` (and in `repos\cli` once those two are live), then tell me? Haiku will then push the three tags and run the install checks.
  - If a past release.yml run shows **success** (meaning CI can publish on tag push after all), pushing the tag would race our manual publish. I'd ask:
    > Your release workflow published v1.1.0 from the tag push. Do you want me to publish from here and then push the tags (the CI run will then fail with "cannot publish over existing version"), or only push the tags and let CI publish?
  - If any `npm view <pkg>@<new version>` already returns the version, or a tag already exists on GitHub, or remote main ≠ local HEAD, I stop and show the user what exists. I don't guess.

## 4. Preflight (network, read-only; main model runs these directly; written down, not run in this dry run)

| Command | Expected |
|---|---|
| `npm whoami` | the user's npm username (no ENEEDAUTH) |
| `npm profile get --json` | `"tfa"` is `false` or `{"mode":"auth-only"}`. If it's `auth-and-writes`, see the conditional question above |
| `npm access list collaborators @quillkit/fmt --json` (and lint, cli) | an object that includes the user with `"read-write"` |
| `npm view @quillkit/fmt versions --json --prefer-online` | includes `"1.1.0"`, not `"1.2.0"` |
| `npm view @quillkit/lint versions --json --prefer-online` | includes `"1.1.0"`, not `"1.2.0"` |
| `npm view @quillkit/cli versions --json --prefer-online` | includes `"0.9.0"`, not `"0.9.1"` |
| `gh api repos/quillkit/fmt/commits/main --jq .sha` | `2b3e01e55ff7982bffad3799019a2c6d48afe426` |
| `gh api repos/quillkit/lint/commits/main --jq .sha` | `93866923be97b19a0c3cc8c74a8ae8e41292bd17` |
| `gh api repos/quillkit/cli/commits/main --jq .sha` | `a0be7c1311866d1f1ca2372a950fad462e50852f` |
| `gh api repos/quillkit/fmt/git/matching-refs/tags/v1.2.0 --jq '.[].ref'` (lint: `v1.2.0`, cli: `v0.9.1`) | empty output |
| `gh api repos/quillkit/fmt --jq .permissions.push` (and lint, cli) | `true` |
| `gh run list --repo quillkit/fmt --workflow release.yml --limit 3 --json headBranch,conclusion` (and lint, cli) | the `v1.1.0` / `v0.9.0` runs have `"conclusion":"failure"`, or there are no runs. Either way CI didn't publish |

## 5. Launch order and Agent parameters

All six agents use `subagent_type: "general-purpose"`, `model: "haiku"`, `run_in_background: true`. The `prompt` is the full text of the brief file named, verbatim.

### Wave 1: one message, two Agent calls

```
Agent({ description: "Publish+tag @quillkit/fmt 1.2.0",  subagent_type: "general-purpose", model: "haiku", run_in_background: true, prompt: <briefs/01-publish-tag-fmt.md> })
Agent({ description: "Publish+tag @quillkit/lint 1.2.0", subagent_type: "general-purpose", model: "haiku", run_in_background: true, prompt: <briefs/02-publish-tag-lint.md> })
```

While these run: in a real session I'd write briefs 03–06 now. All their inputs are already fixed, and none depends on wave 1 output. Then I wait for the notifications, without polling.

**Gate before wave 2:** each package's checks from section 6 pass (version live, integrity equals my local pack, tag ref is an annotated tag, tag commit = pinned SHA).

### Wave 2: launched per gate, at most 3 running at once

- As soon as **fmt** is verified:
  `Agent({ description: "Install-check @quillkit/fmt 1.2.0", subagent_type: "general-purpose", model: "haiku", run_in_background: true, prompt: <briefs/04-install-check-fmt.md> })`
- As soon as **lint** is verified:
  `Agent({ description: "Install-check @quillkit/lint 1.2.0", subagent_type: "general-purpose", model: "haiku", run_in_background: true, prompt: <briefs/05-install-check-lint.md> })`
- As soon as **both** are verified:
  `Agent({ description: "Publish+tag @quillkit/cli 0.9.1", subagent_type: "general-purpose", model: "haiku", run_in_background: true, prompt: <briefs/03-publish-tag-cli.md> })`

If both wave 1 reports arrive before I've verified either, I verify both and launch 03, 04 and 05 in one message.

**Gate before wave 3:** cli's checks from section 6 pass. fmt and lint are already verified live, which 06's dependency install needs.

### Wave 3

`Agent({ description: "Install-check @quillkit/cli 0.9.1", subagent_type: "general-purpose", model: "haiku", run_in_background: true, prompt: <briefs/06-install-check-cli.md> })`

## 6. Verification after each report (main model, read-only, run directly)

**After 01 (fmt):**
```
npm view @quillkit/fmt@1.2.0 version --prefer-online          → 1.2.0
npm view @quillkit/fmt@1.2.0 dist.integrity --prefer-online   → sha512-9r5xUhT4VONCA70UzaeFPIveEoTO9Rx/bC+A3HauzTE+bzHub3hdcMweDEziyDtkVt8Jj6uOH2tyE8piHJr1RQ==
gh api repos/quillkit/fmt/git/ref/tags/v1.2.0 --jq '.ref + " " + .object.type'   → refs/tags/v1.2.0 tag
gh api repos/quillkit/fmt/commits/v1.2.0 --jq .sha            → 2b3e01e55ff7982bffad3799019a2c6d48afe426
```

**After 02 (lint):**
```
npm view @quillkit/lint@1.2.0 version --prefer-online         → 1.2.0
npm view @quillkit/lint@1.2.0 dist.integrity --prefer-online  → sha512-u9BrqZW00JiMAiDPNIcNm15FDnICFNv3oU+L1tfP7OD5qOtcfbRVU6liUsp63ZRu7lPjm/tDNjKzG+qniUrBlQ==
gh api repos/quillkit/lint/git/ref/tags/v1.2.0 --jq '.ref + " " + .object.type'  → refs/tags/v1.2.0 tag
gh api repos/quillkit/lint/commits/v1.2.0 --jq .sha           → 93866923be97b19a0c3cc8c74a8ae8e41292bd17
```

**After 03 (cli):**
```
npm view @quillkit/cli@0.9.1 version --prefer-online          → 0.9.1
npm view @quillkit/cli@0.9.1 dist.integrity --prefer-online   → sha512-pMvMeedBrUrd81HYh0AfIoE65w5mlZhxR/zMHeqZQbJ/oIjjWNyX2wPf10QgsWSPCRtdY0VHpxO0SMAbpLx4zA==
gh api repos/quillkit/cli/git/ref/tags/v0.9.1 --jq '.ref + " " + .object.type'   → refs/tags/v0.9.1 tag
gh api repos/quillkit/cli/commits/v0.9.1 --jq .sha            → a0be7c1311866d1f1ca2372a950fad462e50852f
```

An integrity mismatch isn't automatically "failed", but I don't call the item done until I've explained it. npm pack output is deterministic, so a mismatch would mean dist/ changed between my preflight and the publish.

**After 04 / 05 / 06 (install checks):** `npm view` was already confirmed in the previous gate. Per the SKILL.md table, I accept the agent's `--version` output if it's quoted exactly:
- 04: evidence contains `1.2.0` (from `quill-fmt --version`), `@quillkit/fmt`, and a line with `@quillkit/fmt@1.2.0`.
- 05: evidence contains `1.2.0` (from `quill-lint --version`), `@quillkit/lint`, and a line with `@quillkit/lint@1.2.0`.
- 06: evidence contains `0.9.1` (from `quill --version`), `@quillkit/cli`, and lines with `@quillkit/cli@0.9.1`, `@quillkit/fmt@1.2.0`, `@quillkit/lint@1.2.0`.
If any quote is missing or paraphrased, I rerun one local check myself, e.g.
`cd /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-cli-0.9.1 && ./node_modules/.bin/quill --version` → `0.9.1` (local, read-only).

**Final, informational (after all tags):**
```
gh run list --repo quillkit/fmt  --workflow release.yml --limit 1 --json headBranch,status,conclusion  → [{"conclusion":"failure","headBranch":"v1.2.0","status":"completed"}]
gh run list --repo quillkit/lint --workflow release.yml --limit 1 --json headBranch,status,conclusion  → [{"conclusion":"failure","headBranch":"v1.2.0","status":"completed"}]
gh run list --repo quillkit/cli  --workflow release.yml --limit 1 --json headBranch,status,conclusion  → [{"conclusion":"failure","headBranch":"v0.9.1","status":"completed"}]
```
(Or `in_progress` if I'm early. That's fine, I don't wait on it.) I'm not reading the logs. If one shows `success`, it means CI published something, which contradicts preflight, so I'd look at `npm view <pkg> time --json` and tell the user.

## 7. Failure handling, decided in advance

| Report | What I do |
|---|---|
| 01/02/03 `skipped` with `NEEDS_USER:` (OTP or web-auth URL at publish) | Don't relaunch. The agent's npm process is gone, so approving that URL now does nothing. Ask the user to run `npm publish --access public` in that repo themselves, verify with `npm view`, then send a corrected brief that starts at the tag step (tag-absence check, `git tag -a`, push). |
| E401/E403/ENEEDAUTH on publish | Stop and ask the user (auth or permission problem). No relaunch. |
| E429 from npm | Launch nothing else that talks to npm (that's every remaining brief). Tell the user what's done and pending, with the exact error text. Retry only when they say. |
| Publish ok, push failed (credential manager / "terminal prompts disabled" / 403) | The package is live and the local tag exists. Ask the user to fix git credentials (I won't change credential config without their yes), then send a corrected brief: check `git rev-parse "v1.2.0^{commit}"` = pinned SHA, then `git push origin refs/tags/v1.2.0`. |
| `skipped` "already on npm" / tag already exists | Verify: integrity matches my local pack, and the tag commit equals the pinned SHA. If both match, count it as done. Otherwise show the user. |
| 04/05/06 ETARGET / E404 right after publish | Re-confirm with `npm view … --prefer-online`. If it shows the version, wait a couple of minutes, then send a corrected brief with a new temp folder (`…-1.2.0-2`), because step 1 refuses an existing folder. |
| 06 fails on a dependency | Check fmt/lint again. Debugging stays on main. |

## 8. Wrap-up table (if everything succeeded)

| Item | Result | Evidence |
|---|---|---|
| @quillkit/fmt 1.2.0 | published (integrity matches local pack), tagged v1.2.0 at 2b3e01e, install ok (`quill-fmt --version` → 1.2.0) | [npm](https://www.npmjs.com/package/@quillkit/fmt/v/1.2.0) · [v1.2.0](https://github.com/quillkit/fmt/tree/v1.2.0) |
| @quillkit/lint 1.2.0 | published (integrity matches local pack), tagged v1.2.0 at 9386692, install ok (`quill-lint --version` → 1.2.0) | [npm](https://www.npmjs.com/package/@quillkit/lint/v/1.2.0) · [v1.2.0](https://github.com/quillkit/lint/tree/v1.2.0) |
| @quillkit/cli 0.9.1 | published (integrity matches local pack), tagged v0.9.1 at a0be7c1, install ok (`quill --version` → 0.9.1; resolves fmt 1.2.0 + lint 1.2.0) | [npm](https://www.npmjs.com/package/@quillkit/cli/v/0.9.1) · [v0.9.1](https://github.com/quillkit/cli/tree/v0.9.1) |

**Left:** nothing from this request. Install-check folders are left in `C:\Users\User\AppData\Local\Temp\haiku-verify\` if you want to poke at them.
**Needs you:** a decision on release.yml. The tag pushes started 3 runs that failed at `npm ci` (no package-lock.json), as expected, so nothing was published twice. Even with a lockfile, `scripts/build.js` doesn't produce `dist/cli.js`, so a CI release would ship without the bin. Say if you want that fixed.
