# Task: Install @quillkit/fmt 1.2.0 from npm in a temp folder and check `quill-fmt --version`

You are running a fixed, fully specified job for another Claude session. Run the steps exactly as written, in order. You are not being asked to make decisions: if anything doesn't match this brief, stop and report it. Don't ask questions, because nobody will answer them; put them in your report instead.

## Goal
A clean install of @quillkit/fmt@1.2.0 from the npm registry works in an empty temp folder, and `quill-fmt --version` prints 1.2.0.

## Inputs
- Shell: Bash (Git Bash on Windows). Use this shell for every command.
- Temp folder: "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0" (it must not exist yet). Your working directory resets between commands, so every step below starts with its own `cd`. Keep it every time.
- Package: @quillkit/fmt@1.2.0 (already published; the other session checked it with `npm view`)
- Bin: quill-fmt
- Expected version output: 1.2.0

## Steps
1. `test ! -e "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0" && mkdir -p "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0"`
   Expect: exit code 0 and no output. If the folder already exists (exit code 1), stop and report `failed` with error "temp folder already exists". Do not delete it or pick another folder.
2. `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0" && npm init -y`
   Expect: exit code 0. It prints the package.json it wrote; that's fine.
3. `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0" && npm install --no-audit --no-fund --prefer-online @quillkit/fmt@1.2.0`
   Expect: exit code 0 and a line that starts with `added` (expected: `added 1 package`). Quote that line in evidence. Lines starting with `npm warn` are fine as long as the exit code is 0.
4. `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0" && ./node_modules/.bin/quill-fmt --version`
   Expect: exactly one line, `1.2.0`. Quote the output verbatim in evidence.
5. `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0" && npm ls @quillkit/fmt`
   Expect: exit code 0 and a line containing `@quillkit/fmt@1.2.0`. Quote that line in evidence.

## Do not
- Do not force-push: no `--force`, `-f`, `--force-with-lease`, no `+` refspecs.
- Do not delete or move tags, branches, releases, repos or packages: no `git push --delete`, `git tag -d`, `git tag -f`, `gh repo delete`, `gh release delete`, `npm unpublish`, `npm deprecate`.
- Do not edit, create or delete files except: inside the temp folder above, and only through the commands in Steps. Leave the temp folder in place when you're done.
- Do not run any command or tool call that isn't in Steps. The only exception is read-only commands to capture evidence: `git status`, `git log -1`, `git rev-parse`, `git ls-remote`, `npm view`, `gh api` GET requests.
- Do not enter passwords, tokens, OTPs or 2FA codes, and do not run login commands (`npm login`, `npm adduser`, `gh auth login`).
- Do not try to fix, work around or rerun a failed step, except as the stop conditions allow.
- Do not put secret values in your report. Give the file and line only.
- Do not use `npm install -g`, `npm link`, `npx`, `--registry`, or a local path or tarball instead of the registry.
- Do not open, change or run anything in any folder under "/c/Users/User/github repo/".
- Do not run `npm publish` or any other command that changes anything on npm or GitHub.

## Stop conditions
- Stop at the first error: a nonzero exit code, an error message, or output that doesn't match Expect. Don't run any later step. Report every item you didn't finish as `skipped`, with the reason.
- Rate limit (E429, `429`, "Too Many Requests", "rate limit", "secondary rate limit", "created too many repositories", "was submitted too quickly"): stop at once. Never retry.
- Auth error (401, 403, E401, E403, ENEEDAUTH, "Bad credentials", "Permission denied", "requires authentication", "terminal prompts disabled", "could not read Username", a prompt to log in): stop at once. Never retry.
- Browser or 2FA approval (a request for a one-time password, or a URL to approve in a browser): stop. Report the item as `skipped` with an error that starts `NEEDS_USER:` followed by the URL or the prompt text.
- Network timeout (ETIMEDOUT, ECONNRESET, ESOCKETTIMEDOUT, "network timeout" printed by the program): you may rerun that one step once. If it fails again, stop. If the tool itself times out instead (the command is cut off with no error from the program), that is not a network timeout: stop and report, unless the step says otherwise. Never rerun a publish or push that was cut off.
- Anything unexpected (a missing file, a different version, a dirty working tree, a prompt you didn't expect): stop and report it. Don't adapt.
- ETARGET or E404 on install means the version isn't visible on the registry. Stop and report; don't wait and retry.

## Report
End your reply with one block for each of these report items, in this order: `install @quillkit/fmt@1.2.0` (steps 1–5). Use exactly this shape, and put nothing after the last block:

```
{
  "item": "install @quillkit/fmt@1.2.0",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<the `added` line from step 3, the exact output of step 4, and the `@quillkit/fmt@1.2.0` line from step 5>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```
