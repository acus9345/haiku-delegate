# Haiku brief template

Use this template for every Haiku agent. Fill in every `<placeholder>` and keep every section. A Haiku agent sees only the brief: not the conversation, not the task list, not the other briefs. So the brief has to stand on its own.

## Contents

- The template
- Filling it in
- Example 1: publish a package and push its tag
- Example 2: apply a patch to a repo, test, commit and push
- Example 3: verify an install from npm

## The template

````markdown
# Task: <short title>

You are running a fixed, fully specified job for another Claude session. Run the steps exactly as written, in order. You are not being asked to make decisions: if anything doesn't match this brief, stop and report it. Don't ask questions, because nobody will answer them; put them in your report instead.

## Goal
<One sentence: what is true when you're done.>

## Inputs
- Shell: <Bash | PowerShell>. Use this shell for every command.
- Working directory: "<absolute path>". Your working directory resets between commands, so every step below starts with its own `cd`. Keep it every time.
- <name>: <exact value>
- …

## Steps
1. `cd "<absolute path>" && <exact command or tool call, every argument filled in>`
   Expect: <what success looks like: exit code 0, an output line, a value>
2. …

<For several items: "Run steps 1–N for each item, in this order: A, B, C.">

## Do not
- Do not force-push: no `--force`, `-f`, `--force-with-lease`, no `+` refspecs.
- Do not delete or move tags, branches, releases, repos or packages: no `git push --delete`, `git tag -d`, `git tag -f`, `gh repo delete`, `gh release delete`, `npm unpublish`, `npm deprecate`.
- Do not edit, create or delete files except: <exact list, or "none">.
- Do not run any command or tool call that isn't in Steps. The only exception is read-only commands to capture evidence: `git status`, `git log -1`, `git rev-parse`, `git ls-remote`, `npm view`, `gh api` GET requests.
- Do not enter passwords, tokens, OTPs or 2FA codes, and do not run login commands (`npm login`, `npm adduser`, `gh auth login`).
- Do not try to fix, work around or rerun a failed step, except as the stop conditions allow.
- Do not put secret values in your report. Give the file and line only.

## Stop conditions
- Stop at the first error: a nonzero exit code, an error message, or output that doesn't match Expect. Don't run any later step. Report every item you didn't finish as `skipped`, with the reason.
- Rate limit (E429, `429`, "Too Many Requests", "rate limit", "secondary rate limit", "created too many repositories", "was submitted too quickly"): stop at once. Never retry.
- Auth error (401, 403, E401, E403, ENEEDAUTH, "Bad credentials", "Permission denied", "requires authentication", "terminal prompts disabled", "could not read Username", a prompt to log in): stop at once. Never retry.
- Browser or 2FA approval (a request for a one-time password, or a URL to approve in a browser): stop. Report the item as `skipped` with an error that starts `NEEDS_USER:` followed by the URL or the prompt text.
- Network timeout (ETIMEDOUT, ECONNRESET, ESOCKETTIMEDOUT, "network timeout" printed by the program): you may rerun that one step once. If it fails again, stop. If the tool itself times out instead (the command is cut off with no error from the program), that is not a network timeout: stop and report, and never rerun a publish or push that was cut off.
- Anything unexpected (a missing file, a different version, a dirty working tree, a prompt you didn't expect): stop and report it. Don't adapt.

## Report
End your reply with one block per item, in exactly this shape, and nothing after the last block:

```
{
  "item": "<item name>",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<URL, version, commit SHA, exit code, or the exact output line that shows the result>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```
````

## Filling it in

- **Exact means exact.** Absolute paths, package names with their scope, full versions, the full commit message (with any trailer lines the session requires), and the exact text of any file edit. For edits longer than a line or two, write a patch or message file first and pass its path, which also avoids shell-quoting mistakes.
- **Approval first.** Every outward-facing step must already be approved by the user in this session before it goes into a brief.
- **Every step starts with `cd`, and every path is quoted.** Each of the agent's tool calls starts fresh: the working directory and shell variables don't carry over. So start every command with `cd "<absolute path>" &&`, and pass fixed paths as inputs instead of `$(mktemp -d)` results. Quote paths even when they have no spaces, because the agent copies the style it sees, and Windows paths often do have spaces.
- **Name the shell, and write for it.** On Windows the Bash tool is Git Bash (`/c/Users/...` paths).
- **Pin refs to SHAs.** Give the exact commit SHA for every tag (`git tag -a <tag> -m "<msg>" <sha>`) and check HEAD against it in the first step, so a tag can't land on a commit nobody looked at. Take tag names and messages from the repo's existing tags: `git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(contents:subject)'`.
- **Make steps safe to rerun.** Check whether the thing already exists before creating it, and have the agent report `skipped` with evidence if it does. Put these checks before the irreversible step (check the tag is free before publishing, not after). A corrected brief after a partial failure is then safe to run.
- **Keep network commands non-interactive.** On Windows, Git Credential Manager opens a login window instead of printing a prompt, so a background push hangs until the tool times out. Prefix git network commands (`push`, `pull`, `fetch`, `ls-remote`) with `GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never` so they fail loudly. Run `npm publish` with `</dev/null`. Pass `--yes`/`-y` where the tool has one and the action is approved, and avoid commands that open an editor (`git commit` without `-m`/`-F`, `git tag -a` without `-m`).
- **Mark expected errors and benign noise.** If a step is supposed to fail, say so in its Expect line, or the agent will stop there. `npm view <pkg>@<unpublished version>` gives E404 "No match found for version" on current npm, while older npm versions print nothing and exit 0, so accept both. Also say which extra output is fine (`npm notice`/`npm warn` lines with exit code 0).
- **Use `--prefer-online`** on `npm view` and `npm install` right after a publish, so a stale local cache doesn't give a false "not found".
- **MCP tools are fine.** If the session has a tool for the job (a publishing MCP server, say), list that tool call with exact arguments instead of a shell command. The same rules apply. For a tool that returns a job id, include the polling step and say what result counts as done.
- **Several items in one agent:** list the order explicitly. Stop-at-first-error applies to the whole brief, so put independent items in separate agents when you want one failure not to block the others.

When you send a brief, include every section in full. Examples 2 and 3 below abbreviate the fixed sections to save space in this file; real briefs never do.

## Example 1: publish a package and push its tag

Context: `@acme/core` 1.0.0 is built in `C:\work\acme\packages\core`, which is its own repo with `origin` at `github.com/acme/core` and `main` already pushed at `3f9c2a7…`. The repo's existing tags are annotated with the tag name as the message. The user approved publishing it to npm as a public package and pushing tag `v1.0.0`.

````markdown
# Task: Publish @acme/core 1.0.0 to npm and push tag v1.0.0

You are running a fixed, fully specified job for another Claude session. Run the steps exactly as written, in order. You are not being asked to make decisions: if anything doesn't match this brief, stop and report it. Don't ask questions, because nobody will answer them; put them in your report instead.

## Goal
@acme/core 1.0.0 is on npm as a public package, and the annotated tag v1.0.0, pointing at commit 3f9c2a7e5b1d4c8a9e0f6b2d7c4a1e8f5b3d9c0a, is on github.com/acme/core.

## Inputs
- Shell: Bash. Use this shell for every command.
- Working directory: "/c/work/acme/packages/core". Your working directory resets between commands, so every step below starts with its own `cd`. Keep it every time.
- Package: @acme/core
- Version: 1.0.0
- Commit to tag: 3f9c2a7e5b1d4c8a9e0f6b2d7c4a1e8f5b3d9c0a (HEAD of main, already on origin)
- Tag: v1.0.0, annotated, message "v1.0.0"
- Remote: origin (https://github.com/acme/core.git)

## Steps
1. `cd "/c/work/acme/packages/core" && git status --porcelain && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD`
   Expect: no status lines, then `main`, then `3f9c2a7e5b1d4c8a9e0f6b2d7c4a1e8f5b3d9c0a`.
2. `cd "/c/work/acme/packages/core" && node -p "const p=require('./package.json'); p.name+'@'+p.version"`
   Expect: `@acme/core@1.0.0`
3. `cd "/c/work/acme/packages/core" && git tag -l v1.0.0 && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git ls-remote --tags origin refs/tags/v1.0.0`
   Expect: exit code 0 and no output at all, meaning the tag exists neither locally nor on origin. If either command prints a line, stop and report that line. Do not publish.
4. `cd "/c/work/acme/packages/core" && npm view @acme/core@1.0.0 version --prefer-online`
   Expect: an E404 error ("No match found for version 1.0.0" or "Not Found"), or no output with exit code 0. Both mean 1.0.0 isn't published yet; here they are the expected result, not a failure. If it prints `1.0.0` instead, the version is already published: report `skipped` with evidence "1.0.0 already on npm" and stop.
5. `cd "/c/work/acme/packages/core" && npm publish --access public </dev/null`
   Expect: exit code 0 and a line `+ @acme/core@1.0.0`. Lines starting with `npm notice` or `npm warn` are fine as long as the exit code is 0 and the `+` line appears.
6. `cd "/c/work/acme/packages/core" && git tag -a v1.0.0 -m "v1.0.0" 3f9c2a7e5b1d4c8a9e0f6b2d7c4a1e8f5b3d9c0a`
   Expect: exit code 0 and no output.
7. `cd "/c/work/acme/packages/core" && git rev-parse "v1.0.0^{commit}"`
   Expect: `3f9c2a7e5b1d4c8a9e0f6b2d7c4a1e8f5b3d9c0a`
8. `cd "/c/work/acme/packages/core" && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git push origin refs/tags/v1.0.0`
   Expect: exit code 0 and a line containing `[new tag]` and `v1.0.0 -> v1.0.0`.
9. Put in evidence: the `+ @acme/core@1.0.0` line from step 5, https://www.npmjs.com/package/@acme/core/v/1.0.0, and `v1.0.0 -> 3f9c2a7e5b1d4c8a9e0f6b2d7c4a1e8f5b3d9c0a`.

## Do not
- Do not force-push: no `--force`, `-f`, `--force-with-lease`, no `+` refspecs.
- Do not delete or move tags, branches, releases, repos or packages: no `git push --delete`, `git tag -d`, `git tag -f`, `gh repo delete`, `gh release delete`, `npm unpublish`, `npm deprecate`.
- Do not edit, create or delete files except: none. (Step 6 writes the tag inside .git; that is expected.)
- Do not run any command or tool call that isn't in Steps. The only exception is read-only commands to capture evidence: `git status`, `git log -1`, `git rev-parse`, `git ls-remote`, `npm view`, `gh api` GET requests.
- Do not enter passwords, tokens, OTPs or 2FA codes, and do not run login commands (`npm login`, `npm adduser`, `gh auth login`).
- Do not try to fix, work around or rerun a failed step, except as the stop conditions allow.
- Do not put secret values in your report. Give the file and line only.
- Do not push anything except `refs/tags/v1.0.0`: no branch pushes, no `git push --tags`, no `--follow-tags`.

## Stop conditions
- Stop at the first error: a nonzero exit code, an error message, or output that doesn't match Expect. Don't run any later step. Report every item you didn't finish as `skipped`, with the reason.
- Rate limit (E429, `429`, "Too Many Requests", "rate limit", "secondary rate limit", "created too many repositories", "was submitted too quickly"): stop at once. Never retry.
- Auth error (401, 403, E401, E403, ENEEDAUTH, "Bad credentials", "Permission denied", "requires authentication", "terminal prompts disabled", "could not read Username", a prompt to log in): stop at once. Never retry.
- Browser or 2FA approval (a request for a one-time password, or a URL to approve in a browser): stop. Report the item as `skipped` with an error that starts `NEEDS_USER:` followed by the URL or the prompt text.
- Network timeout (ETIMEDOUT, ECONNRESET, ESOCKETTIMEDOUT, "network timeout" printed by the program): you may rerun that one step once. If it fails again, stop. If the tool itself times out instead (the command is cut off with no error from the program), that is not a network timeout: stop and report, and never rerun a publish or push that was cut off.
- Anything unexpected (a missing file, a different version, a dirty working tree, a prompt you didn't expect): stop and report it. Don't adapt.

## Report
End your reply with one block per item, in exactly this shape, and nothing after the last block:

```
{
  "item": "@acme/core",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<URL, version, commit SHA, exit code, or the exact output line that shows the result>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```
````

## Example 2: apply a patch to a repo, test, commit and push

Context: the main model wrote a fix for a request-timeout bug as `C:\work\acme\patches\http-timeout.patch` (it touches `src/client.js` and `test/client.test.js`) and the commit message as `C:\work\acme\patches\http-timeout.msg`. The user approved committing and pushing it to `main` of `acme/http`. For several repos, send one brief like this per repo, up to 4 at once.

````markdown
# Task: Apply http-timeout.patch to acme/http, run tests, commit and push to main

<preamble, verbatim from the template>

## Goal
The patch is committed on main of github.com/acme/http with the given message, and the tests passed before the commit.

## Inputs
- Shell: Bash. Use this shell for every command.
- Working directory: "/c/work/acme/http". Your working directory resets between commands, so every step below starts with its own `cd`. Keep it every time.
- Patch: "/c/work/acme/patches/http-timeout.patch"
- Commit message file: "/c/work/acme/patches/http-timeout.msg"
- Files the patch changes: src/client.js, test/client.test.js
- Remote: origin (https://github.com/acme/http.git), branch main

## Steps
1. `cd "/c/work/acme/http" && git status --porcelain && git rev-parse --abbrev-ref HEAD`
   Expect: no status lines, then `main`.
2. `cd "/c/work/acme/http" && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git pull --ff-only origin main`
   Expect: exit code 0.
3. `cd "/c/work/acme/http" && git apply --check "/c/work/acme/patches/http-timeout.patch"`
   Expect: no output, exit code 0. If it fails, stop. Do not try `--3way`, `--reject` or editing files by hand.
4. `cd "/c/work/acme/http" && git apply "/c/work/acme/patches/http-timeout.patch"`
   Expect: exit code 0.
5. `cd "/c/work/acme/http" && git status --porcelain`
   Expect: exactly two lines, ` M src/client.js` and ` M test/client.test.js`.
6. `cd "/c/work/acme/http" && npm test`
   Expect: exit code 0. Copy the summary lines (pass/fail counts) into evidence. If any test fails, stop and do not commit.
7. `cd "/c/work/acme/http" && git add src/client.js test/client.test.js && git commit -F "/c/work/acme/patches/http-timeout.msg"`
   Expect: exit code 0.
8. `cd "/c/work/acme/http" && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git push origin main`
   Expect: exit code 0 and a line containing `main -> main`.
9. `cd "/c/work/acme/http" && git rev-parse HEAD`
   Expect: a 40-character SHA. Put it in evidence.

## Do not
<template list, with:>
- Do not edit, create or delete files except: src/client.js and test/client.test.js, and only through `git apply` in step 4.
<plus:>
- Do not run `git stash`, `git reset`, `git checkout -- <file>`, `git rebase` or `npm install`.

## Stop conditions
<verbatim from the template>

## Report
<template block, one item: "acme/http">
````

## Example 3: verify an install from npm

Context: `@acme/cli` 1.0.0 is published (the main model already confirmed it with `npm view`), its bin is `acme`, and it depends on `@acme/core` and `@acme/utils`. The main model picked an empty temp folder for the check. This touches nothing outside that folder, so it needs no approval beyond the opt-in.

````markdown
# Task: Install @acme/cli 1.0.0 from npm in a temp folder and check `acme --version`

<preamble, verbatim from the template>

## Goal
A clean install of @acme/cli@1.0.0 from the public registry works, and `acme --version` prints 1.0.0.

## Inputs
- Shell: Bash. Use this shell for every command.
- Temp folder: "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-cli-1.0.0" (it must not exist yet). Your working directory resets between commands, so every step below starts with its own `cd`. Keep it every time.
- Package: @acme/cli@1.0.0
- Bin: acme
- Expected version output: 1.0.0

## Steps
1. `test ! -e "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-cli-1.0.0" && mkdir -p "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-cli-1.0.0"`
   Expect: exit code 0. If the folder already exists, stop and report.
2. `cd "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-cli-1.0.0" && npm init -y`
   Expect: exit code 0.
3. `cd "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-cli-1.0.0" && npm install --no-audit --no-fund --prefer-online @acme/cli@1.0.0`
   Expect: exit code 0 and a line like `added N packages`.
4. `cd "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-cli-1.0.0" && ./node_modules/.bin/acme --version`
   Expect: exactly `1.0.0`. Quote the output verbatim in evidence.
5. `cd "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-cli-1.0.0" && npm ls @acme/core @acme/utils`
   Expect: both packages listed with a version. Quote those two lines in evidence.

## Do not
<template list, with:>
- Do not edit, create or delete files except: inside the temp folder above, and only through the commands in Steps.
<plus:>
- Do not use `npm install -g`, `npm link`, or a local path or tarball instead of the registry.

## Stop conditions
<verbatim from the template, plus:>
- ETARGET or E404 on install means the version isn't visible on the registry. Stop and report; don't wait and retry.

## Report
<template block, one item: "@acme/cli">
````
