# Task: Publish @quillkit/fmt 1.2.0 to npm and push tag v1.2.0

You are running a fixed, fully specified job for another Claude session. Run the steps exactly as written, in order. You are not being asked to make decisions: if anything doesn't match this brief, stop and report it. Don't ask questions, because nobody will answer them; put them in your report instead.

## Goal
@quillkit/fmt 1.2.0 is on npm as a public package, and the annotated tag v1.2.0, pointing at commit 2b3e01e55ff7982bffad3799019a2c6d48afe426, is on github.com/quillkit/fmt.

## Inputs
- Shell: Bash (this is Git Bash on Windows). Use this shell for every command.
- Working directory: "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/publish-3-packages/with_skill/repos/fmt"
  The path contains a space, so always keep it in double quotes. Your working directory resets between commands, so every command below starts with its own `cd`. Keep that `cd` every time; never run a step without it.
- Package: @quillkit/fmt
- Version: 1.2.0
- Commit to tag: 2b3e01e55ff7982bffad3799019a2c6d48afe426 (the current HEAD of main, already pushed to origin)
- Tag: v1.2.0, annotated, message "v1.2.0"
- Remote: origin (https://github.com/quillkit/fmt.git)
- Files that must be in the package, and no others: README.md, dist/cli.js, dist/index.js, package.json
- Bash tool timeout: set it to 300000 ms for steps 6 and 9. Use the default for the other steps.

## Steps
1. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/publish-3-packages/with_skill/repos/fmt" && git status --porcelain && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD`
   Expect: no status lines (dist/ is git-ignored, so it does not show up), then `main`, then `2b3e01e55ff7982bffad3799019a2c6d48afe426`.
2. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/publish-3-packages/with_skill/repos/fmt" && node -p "const p=require('./package.json'); [p.name, p.version, p.publishConfig.access].join(' ')"`
   Expect: exactly `@quillkit/fmt 1.2.0 public`
3. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/publish-3-packages/with_skill/repos/fmt" && git tag -l v1.2.0 && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git ls-remote --tags origin refs/tags/v1.2.0`
   Expect: exit code 0 and no output at all, meaning the tag exists neither locally nor on origin. If either command prints a line, stop and report that line. Do not publish.
4. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/publish-3-packages/with_skill/repos/fmt" && npm view @quillkit/fmt@1.2.0 version --prefer-online`
   Expect: no output with exit code 0, or an E404 error. Both mean 1.2.0 isn't published yet; here both are the expected result, not a failure. If it prints `1.2.0` instead, the version is already published: report `skipped` with evidence "1.2.0 already on npm" and stop.
5. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/publish-3-packages/with_skill/repos/fmt" && npm pack --dry-run 2>&1`
   Expect: exit code 0. The output lines start with `npm notice`. The "Tarball Contents" section lists exactly these four files, each with a size in front: README.md, dist/cli.js, dist/index.js, package.json. There is a line ending in `name: @quillkit/fmt`, a line ending in `version: 1.2.0`, and a line ending in `total files: 4`. If any file is missing or extra, or the name or version differs, stop and report the full output. Do not publish.
6. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/publish-3-packages/with_skill/repos/fmt" && npm publish --access public </dev/null`
   Expect: exit code 0 and a line `+ @quillkit/fmt@1.2.0`. Lines starting with `npm notice` or `npm warn` are fine as long as the exit code is 0 and the `+` line appears.
   If the output asks for a one-time password, contains `EOTP`, or prints a URL to open or authenticate in a browser, stop: report `skipped` with an error that starts `NEEDS_USER:` followed by the URL or prompt text exactly as printed.
   If the Bash tool times out on this command, do not rerun it: stop and report `failed` with the error "timed out" plus all the output it printed.
7. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/publish-3-packages/with_skill/repos/fmt" && git tag -a v1.2.0 -m "v1.2.0" 2b3e01e55ff7982bffad3799019a2c6d48afe426`
   Expect: exit code 0 and no output. If it says the tag already exists, stop and report. Do not add `-f`.
8. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/publish-3-packages/with_skill/repos/fmt" && git rev-parse "v1.2.0^{commit}" && git cat-file -t v1.2.0`
   Expect: `2b3e01e55ff7982bffad3799019a2c6d48afe426`, then `tag`.
9. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/publish-3-packages/with_skill/repos/fmt" && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git push origin refs/tags/v1.2.0`
   Expect: exit code 0 and a line containing `[new tag]` and `v1.2.0 -> v1.2.0`. Pushing this tag starts the repo's release workflow on GitHub Actions. That is expected and not part of this job; do not look at it.
   If the Bash tool times out on this command, do not rerun it: stop and report `failed` with the error "timed out" plus all the output it printed.
10. Put this in evidence: the `+ @quillkit/fmt@1.2.0` line from step 6, https://www.npmjs.com/package/@quillkit/fmt/v/1.2.0, and the SHA from step 8 (`v1.2.0 -> <sha>`).

## Do not
- Do not force-push: no `--force`, `-f`, `--force-with-lease`, no `+` refspecs.
- Do not delete or move tags, branches, releases, repos or packages: no `git push --delete`, `git tag -d`, `git tag -f`, `gh repo delete`, `gh release delete`, `npm unpublish`, `npm deprecate`.
- Do not edit, create or delete files except: none. (Step 7 writes the tag inside .git; that is expected.)
- Do not run any command or tool call that isn't in Steps. The only exception is read-only commands to capture evidence: `git status`, `git log -1`, `git rev-parse`, `npm view`, `gh api` GET requests.
- Do not enter passwords, tokens, OTPs or 2FA codes, and do not run login commands (`npm login`, `npm adduser`, `gh auth login`).
- Do not try to fix, work around or rerun a failed step, except as the stop conditions allow.
- Do not put secret values in your report. Give the file and line only.
- Do not run `npm install`, `npm ci`, `npm run build`, `npm version`, or anything else that changes dist/, package.json or node_modules.
- Do not push anything except `refs/tags/v1.2.0`: no branch pushes, no `git push --tags`, no `--follow-tags`.
- Do not look at, wait for, rerun or cancel GitHub Actions runs.
- Do not create a GitHub release, change npm dist-tags, or run `npm trust`, `npm access`, `npm owner` or `gh` commands other than `gh api` GET requests.

## Stop conditions
- Stop at the first error: a nonzero exit code, an error message, or output that doesn't match Expect. Don't run any later step. Report every item you didn't finish as `skipped`, with the reason.
- Rate limit (E429, `429`, "Too Many Requests", "rate limit", "secondary rate limit", "created too many repositories", "was submitted too quickly"): stop at once. Never retry.
- Auth error (401, 403, E401, E403, ENEEDAUTH, "Bad credentials", "Permission denied", "requires authentication", a prompt to log in): stop at once. Never retry.
- Browser or 2FA approval (a request for a one-time password, or a URL to approve in a browser): stop. Report the item as `skipped` with an error that starts `NEEDS_USER:` followed by the URL or the prompt text.
- Network timeout (ETIMEDOUT, ECONNRESET, ESOCKETTIMEDOUT, "network timeout"): you may rerun that one step once. If it fails again, stop. This does not apply to step 6 or step 9 when the Bash tool itself times out; see those steps.
- Anything unexpected (a missing file, a different version, a dirty working tree, a prompt you didn't expect): stop and report it. Don't adapt.
- git says "terminal prompts disabled", "could not read Username", or a credential manager error: that is an auth error. Stop at once.

## Report
End your reply with one block per item, in exactly this shape, and nothing after the last block:

```
{
  "item": "@quillkit/fmt",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<URL, version, commit SHA, exit code, or the exact output line that shows the result>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```
