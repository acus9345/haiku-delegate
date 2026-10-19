# Task: Publish @quillkit/lint 1.2.0 to npm and push tag v1.2.0

You are running a fixed, fully specified job for another Claude session. Run the steps exactly as written, in order. You are not being asked to make decisions: if anything doesn't match this brief, stop and report it. Don't ask questions, because nobody will answer them; put them in your report instead.

## Goal
@quillkit/lint 1.2.0 is on npm as a public package, built from exactly the 4 files listed below, and the annotated tag v1.2.0, pointing at commit 93866923be97b19a0c3cc8c74a8ae8e41292bd17, is on github.com/quillkit/lint.

## Inputs
- Shell: Bash (Git Bash on Windows). Use this shell for every command.
- Working directory: "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/publish-3-packages/with_skill/repos/lint". The path contains a space, so keep the double quotes. Your working directory resets between commands, so every step below starts with its own `cd`. Keep it every time.
- Package: @quillkit/lint
- Version: 1.2.0
- Commit: 93866923be97b19a0c3cc8c74a8ae8e41292bd17 (HEAD of main, already on origin)
- Tag: v1.2.0, annotated, already created locally. Tag object 34d04bc9fd1c45801f9f2c37884d2ff454d7814b, pointing at commit 93866923be97b19a0c3cc8c74a8ae8e41292bd17.
- Remote: origin (https://github.com/quillkit/lint.git)
- Package contents: exactly 4 files (README.md, dist/cli.js, dist/index.js, package.json). Tarball integrity: sha512-u9BrqZW00JiMAiDPNIcNm15FDnICFNv3oU+L1tfP7OD5qOtcfbRVU6liUsp63ZRu7lPjm/tDNjKzG+qniUrBlQ==
- The dist/ folder is ignored by git, so `git status` can't see changes in it. Step 5 checks it instead.
- Pushing the tag starts the repo's `release` workflow on GitHub Actions. That run is expected to fail and is not part of this job.

## Steps
1. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/publish-3-packages/with_skill/repos/lint" && git status --porcelain && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD`
   Expect: no status lines, then `main`, then `93866923be97b19a0c3cc8c74a8ae8e41292bd17`.
2. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/publish-3-packages/with_skill/repos/lint" && node -p "const p=require('./package.json'); p.name+'@'+p.version"`
   Expect: `@quillkit/lint@1.2.0`
3. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/publish-3-packages/with_skill/repos/lint" && git cat-file -t v1.2.0 && git rev-parse v1.2.0 && git rev-parse "v1.2.0^{commit}"`
   Expect: `tag`, then `34d04bc9fd1c45801f9f2c37884d2ff454d7814b`, then `93866923be97b19a0c3cc8c74a8ae8e41292bd17`.
4. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/publish-3-packages/with_skill/repos/lint" && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git ls-remote origin refs/heads/main refs/tags/v1.2.0`
   Expect: exit code 0 and exactly one line: `93866923be97b19a0c3cc8c74a8ae8e41292bd17`, a tab, `refs/heads/main`. There must be no line containing `refs/tags/v1.2.0`. If a tag line appears, or main shows a different SHA, stop and report `failed` with the full output. Do not publish.
5. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/publish-3-packages/with_skill/repos/lint" && npm pack --dry-run --json --ignore-scripts`
   Expect: exit code 0 and JSON containing `"integrity": "sha512-u9BrqZW00JiMAiDPNIcNm15FDnICFNv3oU+L1tfP7OD5qOtcfbRVU6liUsp63ZRu7lPjm/tDNjKzG+qniUrBlQ=="` and `"entryCount": 4`. Lines starting with `npm notice` are fine. This command only lists the files; it writes nothing. If the integrity differs in any character, or entryCount isn't 4, stop and report `failed` with the integrity and entryCount you got. Do not publish.
6. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/publish-3-packages/with_skill/repos/lint" && npm view @quillkit/lint@1.2.0 version --prefer-online`
   Expect: an E404 error ("No match found for version 1.2.0" or "Not Found"), or no output with exit code 0. Both mean 1.2.0 isn't published yet; here they are the expected result, not a failure. If it prints `1.2.0` instead, the version is already published: report the publish item as `skipped` with evidence "1.2.0 already on npm", report the tag item as `skipped`, and stop.
7. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/publish-3-packages/with_skill/repos/lint" && npm publish --access public </dev/null`
   Expect: exit code 0 and a line `+ @quillkit/lint@1.2.0`. Lines starting with `npm notice` or `npm warn` are fine as long as the exit code is 0 and the `+` line appears.
   If the output asks for a one-time password, or shows a URL to open in a browser (for example a line starting `Authenticate your account at`), that is the browser/2FA stop condition: report the publish item as `skipped` with an error that starts `NEEDS_USER:` followed by that URL or prompt text, and report the tag item as `skipped`.
   If the Bash tool times out on this step, do not run it again. Report the publish item as `failed` with all output you saw, including any URL, and report the tag item as `skipped`.
8. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/publish-3-packages/with_skill/repos/lint" && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git push origin refs/tags/v1.2.0`
   Expect: exit code 0 and a line containing `[new tag]` and `v1.2.0 -> v1.2.0`.

## Do not
- Do not force-push: no `--force`, `-f`, `--force-with-lease`, no `+` refspecs.
- Do not delete or move tags, branches, releases, repos or packages: no `git push --delete`, `git tag -d`, `git tag -f`, `gh repo delete`, `gh release delete`, `npm unpublish`, `npm deprecate`.
- Do not edit, create or delete files except: none.
- Do not run any command or tool call that isn't in Steps. The only exception is read-only commands to capture evidence: `git status`, `git log -1`, `git rev-parse`, `git ls-remote`, `npm view`, `gh api` GET requests.
- Do not enter passwords, tokens, OTPs or 2FA codes, and do not run login commands (`npm login`, `npm adduser`, `gh auth login`).
- Do not try to fix, work around or rerun a failed step, except as the stop conditions allow.
- Do not put secret values in your report. Give the file and line only.
- Do not create or change tags (`git tag`), and do not push anything except `refs/tags/v1.2.0`: no branch pushes, no `git push --tags`, no `--follow-tags`.
- Do not look at, wait for, rerun or cancel GitHub Actions runs.
- Do not run `npm run build`, `npm install`, `npm ci`, `npm version`, `npm dist-tag`, `npm access`, `npm trust`, or `npm pack` without `--dry-run`.
- Do not run `gh release create`.

## Stop conditions
- Stop at the first error: a nonzero exit code, an error message, or output that doesn't match Expect. Don't run any later step. Report every item you didn't finish as `skipped`, with the reason.
- Rate limit (E429, `429`, "Too Many Requests", "rate limit", "secondary rate limit", "created too many repositories", "was submitted too quickly"): stop at once. Never retry.
- Auth error (401, 403, E401, E403, ENEEDAUTH, "Bad credentials", "Permission denied", "requires authentication", "terminal prompts disabled", "could not read Username", a prompt to log in): stop at once. Never retry.
- Browser or 2FA approval (a request for a one-time password, or a URL to approve in a browser): stop. Report the item as `skipped` with an error that starts `NEEDS_USER:` followed by the URL or the prompt text.
- Network timeout (ETIMEDOUT, ECONNRESET, ESOCKETTIMEDOUT, "network timeout" printed by the program): you may rerun that one step once. If it fails again, stop. If the tool itself times out instead (the command is cut off with no error from the program), that is not a network timeout: stop and report, unless the step says otherwise. Never rerun a publish or push that was cut off.
- Anything unexpected (a missing file, a different version, a dirty working tree, a prompt you didn't expect): stop and report it. Don't adapt.

## Report
End your reply with one block for each of these report items, in this order: `npm publish @quillkit/lint@1.2.0` (steps 1–7), `push tag v1.2.0` (step 8). Use exactly this shape, and put nothing after the last block:

```
{
  "item": "npm publish @quillkit/lint@1.2.0",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<the `+ @quillkit/lint@1.2.0` line and https://www.npmjs.com/package/@quillkit/lint/v/1.2.0>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```

```
{
  "item": "push tag v1.2.0",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<the `[new tag]` line from step 8>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```
