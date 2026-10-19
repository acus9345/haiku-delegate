# Task: Install @quillkit/slug 2.3.1 from npm in a temp folder and check that the #41 fix is in it

You are running a fixed, fully specified job for another Claude session. Run the steps exactly as written, in order. You are not being asked to make decisions: if anything doesn't match this brief, stop and report it. Don't ask questions, because nobody will answer them; put them in your report instead.

## Goal
A clean install of @quillkit/slug@2.3.1 from the public npm registry works in an empty temp folder, reports version 2.3.1, and its `slugify` turns `Hello   World` into `hello-world` and `Rock - Paper` into `rock-paper`.

## Inputs
- Shell: Bash (Git Bash on Windows). Use this shell for every command.
- Temp folder: /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1 (it must not exist yet; its parent may or may not exist)
- Package: @quillkit/slug@2.3.1
- Registry: https://registry.npmjs.org/
- The package has no bin and no dependencies. It exports one function, `slugify`.
- Expected output of step 6, exactly these three lines:
  `2.3.1`
  `hello-world`
  `rock-paper`

## Steps
1. `test ! -e /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1 && mkdir -p /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1`
   Expect: exit code 0 and no output. If the folder already exists (exit code 1), stop and report it.
2. `cd /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1 && npm config get registry`
   Expect: exactly `https://registry.npmjs.org/`. Anything else, stop and report it.
3. `cd /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1 && npm init -y`
   Expect: exit code 0 and a line `Wrote to` followed by a path ending in `package.json`.
4. `cd /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1 && npm install --no-audit --no-fund @quillkit/slug@2.3.1`
   Expect: exit code 0 and a line `added 1 package`. Quote that line in evidence.
5. `cd /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1 && npm ls @quillkit/slug`
   Expect: a line containing `@quillkit/slug@2.3.1`. Quote that line in evidence.
6. `cd /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1 && node -e "const { slugify } = require('@quillkit/slug'); console.log(require('@quillkit/slug/package.json').version); console.log(slugify('Hello   World')); console.log(slugify('Rock - Paper'));"`
   Type the command exactly as written: `Hello   World` has three spaces between the words.
   Expect: exactly three lines: `2.3.1`, then `hello-world`, then `rock-paper`. Quote all three lines verbatim in evidence. If any line differs (for example `hello---world`), report `failed` with the exact output; do not change the command.

## Do not
- Do not force-push: no `--force`, `-f`, `--force-with-lease`, no `+` refspecs.
- Do not delete or move tags, branches, releases, repos or packages: no `git push --delete`, `git tag -d`, `git tag -f`, `gh repo delete`, `gh release delete`, `npm unpublish`, `npm deprecate`.
- Do not edit, create or delete files except: inside /c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1, and only through the commands in Steps.
- Do not run any command or tool call that isn't in Steps. The only exception is read-only commands to capture evidence: `git status`, `git log -1`, `git rev-parse`, `npm view`, `gh api` GET requests.
- Do not enter passwords, tokens, OTPs or 2FA codes, and do not run login commands (`npm login`, `npm adduser`, `gh auth login`).
- Do not try to fix, work around or rerun a failed step, except as the stop conditions allow.
- Do not put secret values in your report. Give the file and line only.
- Do not use `npm install -g`, `npm link`, `--registry` overrides, or a local path or tarball instead of the registry.
- Do not open, read or run anything from the source repo of this package; this check is only about what the registry serves.
- Do not delete the temp folder when you're done.

## Stop conditions
- Stop at the first error: a nonzero exit code, an error message, or output that doesn't match Expect. Don't run any later step. Report every item you didn't finish as `skipped`, with the reason.
- Rate limit (E429, `429`, "Too Many Requests", "rate limit", "secondary rate limit", "created too many repositories", "was submitted too quickly"): stop at once. Never retry.
- Auth error (401, 403, E401, E403, ENEEDAUTH, "Bad credentials", "Permission denied", "requires authentication", a prompt to log in): stop at once. Never retry.
- Browser or 2FA approval (a request for a one-time password, or a URL to approve in a browser): stop. Report the item as `skipped` with an error that starts `NEEDS_USER:` followed by the URL or the prompt text.
- Network timeout (ETIMEDOUT, ECONNRESET, ESOCKETTIMEDOUT, "network timeout"): you may rerun that one step once. If it fails again, stop.
- Anything unexpected (a missing file, a different version, a dirty working tree, a prompt you didn't expect): stop and report it. Don't adapt.
- ETARGET, E404 or "No matching version found" on install means the version isn't visible on the registry. Stop and report; don't wait and retry.

## Report
End your reply with one block per item, in exactly this shape, and nothing after the last block:

```
{
  "item": "@quillkit/slug@2.3.1 install check",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<URL, version, commit SHA, exit code, or the exact output line that shows the result>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```
