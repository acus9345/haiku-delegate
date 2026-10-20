# Plan: publish @quillkit/fmt 1.2.0, @quillkit/lint 1.2.0, @quillkit/cli 0.9.1

Opt-in: "use haiku for the mechanical parts" (earlier this session). Approved now: npm publish of these 3 versions + push of their release tags. Nothing else.

## Task list

1. [main] Read-only preflight (local done; network commands below)
2. [main] Decide who publishes: local `npm publish`, not the tag-triggered workflow (see Side effects)
3. [main] Create local annotated tags `v1.2.0` (fmt, lint), `v0.9.1` (cli) on HEAD (done)
4. [haiku] 01 fmt: publish, push tag, clean install. Gate: steps 1-3 done, preflight matched
5. [haiku] 02 lint: publish, push tag, clean install. Gate: same as 4 (launch with 4)
6. [main] Verify 01 and 02
7. [haiku] 03 cli: publish, push tag, clean install. Gate: fmt 1.2.0 **and** lint 1.2.0 verified on npm (cli depends on `^1.2.0` of both)
8. [main] Verify 03, check the 3 tag-triggered runs, wrap up

| Step | Who | Why |
|---|---|---|
| Preflight (ls-remote, npm view, 2FA, owner, pack values) | main | Judgment on results; values become brief inputs; few quick commands |
| Publisher choice (local vs CI) | main | Judgment, release-safety call |
| Local tags | main | Skill: local commits/tags stay with main; one command each, briefs pin tag object SHAs |
| Publish + tag push + install, per package | haiku | All inputs known, checkable from registry/GitHub, no choices, stops safely; long waits + noisy output. One agent per package (quick steps ride with the long wait) |
| Verification | main | Every claim checked read-only |
| Failure diagnosis, workflow problems, wrap-up text | main | Debugging / user-facing |

## Preflight (main, read-only)

Done locally (results pinned in briefs):

| Repo | HEAD (main, clean) | version | pack integrity | entryCount | prior tag |
|---|---|---|---|---|---|
| fmt | 2b3e01e55ff7982bffad3799019a2c6d48afe426 | 1.2.0 | sha512-9r5xUhT4…r1RQ== | 4 | v1.1.0 (annotated, msg "v1.1.0") |
| lint | 93866923be97b19a0c3cc8c74a8ae8e41292bd17 | 1.2.0 | sha512-u9BrqZW0…rBlQ== | 4 | v1.1.0 (annotated) |
| cli | a0be7c1311866d1f1ca2372a950fad462e50852f | 0.9.1 | sha512-pMvMeedB…bpLx4zA== | 4 | v0.9.0 (annotated) |

Files per tarball: README.md, package.json, dist/cli.js, dist/index.js (dist/ gitignored, already built, `--version` prints package.json version). No lifecycle scripts besides `build`/`test`, no package-lock.json.

Network preflight (not run in dry run; expected result):

| Command (per repo / pkg) | Expect |
|---|---|
| `git ls-remote origin refs/heads/main refs/tags/<tag>` | one line: `<HEAD sha>	refs/heads/main`, no tag line |
| `npm view @quillkit/<name> versions --json --prefer-online` | lists 1.1.0 (fmt, lint) / 0.9.0 (cli), not the new version |
| `npm whoami` and `npm owner ls @quillkit/<name>` | user's npm name, listed as owner |
| `npm profile get --json` | `tfa` false or mode `auth-only`. If `auth-and-writes`: don't delegate publishes; user runs `npm publish --access public` in each repo, agents get tag-push + install only |
| `gh run list --repo quillkit/<name> --workflow release.yml --limit 3 --json headBranch,conclusion` | informational: no successful release run (confirms CI isn't the working publish path). If one succeeded, stop and ask the user who publishes |

Local tags created (step 3): fmt `v1.2.0` = tag obj 811a8ab4449f777b5dffade98a29a27bcd59cbfb; lint `v1.2.0` = 856b04a8c5aa6a07f8567ebfbba53424434ebddc; cli `v0.9.1` = d55b0414578ac959d0e5943409df014306a9b866. Each on its HEAD, same style as prior tags (`git tag -a vX -m vX`).

## Approvals and side effects

- Publishes + tag pushes: approved by the user's message.
- **Each repo has `.github/workflows/release.yml` on `push: tags: v*` running `npm ci && npm run build && npm publish --provenance`.** Pushing a tag *would* be a publish, racing the local one. It can't succeed here: no package-lock.json (`npm ci` fails), `scripts/build.js` doesn't produce `dist/cli.js`, and by then the version is already on npm. The user said to publish the already-built packages, so local publish is the publisher; briefs publish before pushing the tag, so the race can't produce a broken tarball even if CI got further than expected.
- Heads-up to user (one line, before launch): "Each tag push will trigger `release.yml`, which will fail (no lockfile; the version is already published). That's expected, harmless, and I'm not touching the workflow unless you ask."
- No commits, no `Fixes #N`, no branch pushes, no GitHub releases.

## Launch order

Message 1 (both in one message, gate met after preflight + heads-up):

```
Agent({ description: "Publish @quillkit/fmt 1.2.0", subagent_type: "haiku-worker", model: "haiku", run_in_background: true, prompt: <briefs/01-publish-fmt.md> })
Agent({ description: "Publish @quillkit/lint 1.2.0", subagent_type: "haiku-worker", model: "haiku", run_in_background: true, prompt: <briefs/02-publish-lint.md> })
```

Message 2 (only after fmt **and** lint publish verified):

```
Agent({ description: "Publish @quillkit/cli 0.9.1", subagent_type: "haiku-worker", model: "haiku", run_in_background: true, prompt: <briefs/03-publish-cli.md> })
```

If fmt or lint fails, cli does not launch; diagnose per skill step 6.

## Verification after each report (read-only)

For fmt (lint identical with its values):

| Check | Expect |
|---|---|
| `npm view @quillkit/fmt@1.2.0 version dist.integrity --prefer-online` | `version = '1.2.0'`, `dist.integrity = 'sha512-9r5xUhT4VONCA70UzaeFPIveEoTO9Rx/bC+A3HauzTE+bzHub3hdcMweDEziyDtkVt8Jj6uOH2tyE8piHJr1RQ=='` |
| `gh api repos/quillkit/fmt/git/ref/tags/v1.2.0 --jq '.object.type+" "+.object.sha'` | `tag 811a8ab4449f777b5dffade98a29a27bcd59cbfb` |
| `gh api repos/quillkit/fmt/commits/v1.2.0 --jq .sha` | `2b3e01e55ff7982bffad3799019a2c6d48afe426` |
| install | accept quoted `1.2.0` and `@quillkit/fmt`; otherwise rerun the `npm view` above and report install unverified |
| `gh run list --repo quillkit/fmt --workflow release.yml --limit 1 --json headBranch,conclusion` | `v1.2.0`, `failure` (expected) — and the npm integrity above still equals the local pack value, so CI didn't publish |

lint: integrity `sha512-u9BrqZW00JiMAiDPNIcNm15FDnICFNv3oU+L1tfP7OD5qOtcfbRVU6liUsp63ZRu7lPjm/tDNjKzG+qniUrBlQ==`, tag `tag 856b04a8c5aa6a07f8567ebfbba53424434ebddc`, commit `93866923be97b19a0c3cc8c74a8ae8e41292bd17`.
cli: `npm view @quillkit/cli@0.9.1 version dist.integrity dependencies --prefer-online` → `0.9.1`, `sha512-pMvMeedBrUrd81HYh0AfIoE65w5mlZhxR/zMHeqZQbJ/oIjjWNyX2wPf10QgsWSPCRtdY0VHpxO0SMAbpLx4zA==`, deps `^1.2.0` both; tag `tag d55b0414578ac959d0e5943409df014306a9b866`, commit `a0be7c1311866d1f1ca2372a950fad462e50852f`; install quotes `0.9.1` and `@quillkit/fmt@1.2.0` / `@quillkit/lint@1.2.0`.

## Wrap-up (if everything verified)

| Item | Result | Evidence |
|---|---|---|
| @quillkit/fmt 1.2.0 | published, tagged, install ok | [npm](https://www.npmjs.com/package/@quillkit/fmt/v/1.2.0) · [v1.2.0](https://github.com/quillkit/fmt/tree/v1.2.0) · `quill-fmt --version` → 1.2.0 |
| @quillkit/lint 1.2.0 | published, tagged, install ok | [npm](https://www.npmjs.com/package/@quillkit/lint/v/1.2.0) · [v1.2.0](https://github.com/quillkit/lint/tree/v1.2.0) · `quill-lint --version` → 1.2.0 |
| @quillkit/cli 0.9.1 | published, tagged, install ok | [npm](https://www.npmjs.com/package/@quillkit/cli/v/0.9.1) · [v0.9.1](https://github.com/quillkit/cli/tree/v0.9.1) · `quill --version` → 0.9.1, deps fmt/lint 1.2.0 |

**Left:** nothing from the request. Temp install folders under `C:\Users\User\AppData\Local\Temp\haiku-verify\` can be deleted.
**Needs you:** the three `release` runs failed as expected. `release.yml` can't publish as written (no package-lock.json for `npm ci`, and `scripts/build.js` doesn't build `dist/cli.js`). Want me to fix it, or remove the tag trigger, before the next release?
