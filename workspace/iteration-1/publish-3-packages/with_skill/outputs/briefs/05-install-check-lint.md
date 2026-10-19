# Task: Install @quillkit/lint 1.2.0 from npm in a temp folder and check `quill-lint --version`

You are running a fixed, fully specified job for another Claude session. Run the steps exactly as written, in order. You are not being asked to make decisions: if anything doesn't match this brief, stop and report it. Don't ask questions, because nobody will answer them; put them in your report instead.

## Goal
A clean install of @quillkit/lint@1.2.0 from the public npm registry works, `quill-lint --version` prints 1.2.0, and the package's main module loads.

## Inputs
- Shell: Bash (this is Git Bash on Windows). Use this shell for every command.
- Temp folder: /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-lint-1.2.0 (it must not exist yet; its parent folder may or may not exist)
  Your working directory resets between commands, so every command below starts with its own `cd`. Keep that `cd` every time; never run a step without it.
- Package: @quillkit/lint@1.2.0
- Bin: quill-lint
- Expected version output: 1.2.0
- Expected main-module output: @quillkit/lint
- Bash tool timeout: set it to 300000 ms for step 3. Use the default for the other steps.

## Steps
1. `test ! -e /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-lint-1.2.0 && mkdir -p /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-lint-1.2.0`
   Expect: exit code 0 and no output. If the folder already exists (exit code 1), stop and report. Do not delete or reuse it.
2. `cd /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-lint-1.2.0 && npm init -y`
   Expect: exit code 0 and a printed package.json whose name is `quillkit-lint-1.2.0`.
3. `cd /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-lint-1.2.0 && npm install --prefer-online --no-audit --no-fund @quillkit/lint@1.2.0`
   Expect: exit code 0 and a line like `added 1 package`. Lines starting with `npm warn` are fine as long as the exit code is 0.
4. `cd /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-lint-1.2.0 && ./node_modules/.bin/quill-lint --version`
   Expect: exactly `1.2.0` and nothing else. Quote the output verbatim in evidence.
5. `cd /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-lint-1.2.0 && node -p "require('@quillkit/lint').name"`
   Expect: exactly `@quillkit/lint`
6. `cd /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-lint-1.2.0 && npm ls @quillkit/lint`
   Expect: exit code 0 and a line containing `@quillkit/lint@1.2.0`. Quote that line in evidence.
7. Put this in evidence: the exact output of step 4, the exact output of step 5, and the `@quillkit/lint@1.2.0` line from step 6.

## Do not
- Do not force-push: no `--force`, `-f`, `--force-with-lease`, no `+` refspecs.
- Do not delete or move tags, branches, releases, repos or packages: no `git push --delete`, `git tag -d`, `git tag -f`, `gh repo delete`, `gh release delete`, `npm unpublish`, `npm deprecate`.
- Do not edit, create or delete files except: inside /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-lint-1.2.0, and only through the commands in Steps. Do not delete the temp folder when you're done.
- Do not run any command or tool call that isn't in Steps. The only exception is read-only commands to capture evidence: `git status`, `git log -1`, `git rev-parse`, `npm view`, `gh api` GET requests.
- Do not enter passwords, tokens, OTPs or 2FA codes, and do not run login commands (`npm login`, `npm adduser`, `gh auth login`).
- Do not try to fix, work around or rerun a failed step, except as the stop conditions allow.
- Do not put secret values in your report. Give the file and line only.
- Do not use `npm install -g`, `npm link`, `npx`, or a local path or tarball instead of the registry. Do not touch anything under "/c/Users/User/github repo/".
- Do not run `npm publish`, any `git` command, or any `gh` command.

## Stop conditions
- Stop at the first error: a nonzero exit code, an error message, or output that doesn't match Expect. Don't run any later step. Report every item you didn't finish as `skipped`, with the reason.
- Rate limit (E429, `429`, "Too Many Requests", "rate limit", "secondary rate limit", "created too many repositories", "was submitted too quickly"): stop at once. Never retry.
- Auth error (401, 403, E401, E403, ENEEDAUTH, "Bad credentials", "Permission denied", "requires authentication", a prompt to log in): stop at once. Never retry.
- Browser or 2FA approval (a request for a one-time password, or a URL to approve in a browser): stop. Report the item as `skipped` with an error that starts `NEEDS_USER:` followed by the URL or the prompt text.
- Network timeout (ETIMEDOUT, ECONNRESET, ESOCKETTIMEDOUT, "network timeout"): you may rerun that one step once. If it fails again, stop.
- Anything unexpected (a missing file, a different version, a dirty working tree, a prompt you didn't expect): stop and report it. Don't adapt.
- ETARGET, E404 or "No matching version found" on install means the version isn't visible on the registry yet. Stop and report; don't wait and retry.

## Report
End your reply with one block per item, in exactly this shape, and nothing after the last block:

```
{
  "item": "@quillkit/lint",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<URL, version, commit SHA, exit code, or the exact output line that shows the result>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```
