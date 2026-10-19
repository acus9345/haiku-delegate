# Task: Push main and tag v2.3.1 of quillkit/slug, then watch the release workflow

You are running a fixed, fully specified job for another Claude session. Run the steps exactly as written, in order. You are not being asked to make decisions: if anything doesn't match this brief, stop and report it. Don't ask questions, because nobody will answer them; put them in your report instead.

## Goal
Branch main of github.com/quillkit/slug points at 234cf81a0d49c8a23fa8e04889205780180e290a, the annotated tag v2.3.1 (pointing at that commit) is on github.com/quillkit/slug, and the `release` run that the tag push starts has finished with conclusion `success`.

## Inputs
- Shell: Bash (Git Bash on Windows, so paths look like `/c/Users/...`). Use this shell for every command.
- Working directory: "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/fix-bug-and-release/with_skill/repos/slug". The path contains a space, so keep the double quotes exactly as written. Your working directory resets between commands, so every step below starts with its own `cd`. Keep it every time.
- GitHub repo: quillkit/slug. Remote: origin (https://github.com/quillkit/slug.git). Branch: main.
- npm package: @quillkit/slug. Version being released: 2.3.1 (not on npm yet).
- Local main to push: 234cf81a0d49c8a23fa8e04889205780180e290a. It is two commits ahead of origin/main: 41a4b3c3473e351286d9f459575b1bf650a56804 `fix: collapse repeated separators into a single dash (#41)`, then 234cf81a0d49c8a23fa8e04889205780180e290a `chore(release): v2.3.1`.
- origin/main before this job: 7d0bf664bb487e6172eb006e38a3d4501545f225
- Tag: v2.3.1, annotated, already created locally. Tag object c0b90a51136abcb074392f9c2d79eeb753f77be5, pointing at 234cf81a0d49c8a23fa8e04889205780180e290a.
- Pushing main starts no workflow.
- Workflow: `release` (.github/workflows/release.yml). It starts by itself when the tag is pushed, runs `npm test`, and publishes @quillkit/slug 2.3.1 to npm with trusted publishing. You never publish anything yourself.
- The fix commit mentions issue #41 as `(#41)`. On GitHub that links the commit to the issue but does not close it. Leave the issue alone.

## Steps
1. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/fix-bug-and-release/with_skill/repos/slug" && git status --porcelain && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD`
   Expect: no status lines, then `main`, then `234cf81a0d49c8a23fa8e04889205780180e290a`. A line starting `warning: in the working copy of` and ending `LF will be replaced by CRLF the next time Git touches it` is harmless noise and is fine. Any status line (for example one starting with ` M`, `M `, `A `, `D ` or `??`) is not fine: stop.
2. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/fix-bug-and-release/with_skill/repos/slug" && git cat-file -t v2.3.1 && git rev-parse v2.3.1 && git rev-parse "v2.3.1^{commit}"`
   Expect: `tag`, then `c0b90a51136abcb074392f9c2d79eeb753f77be5`, then `234cf81a0d49c8a23fa8e04889205780180e290a`.
3. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/fix-bug-and-release/with_skill/repos/slug" && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git ls-remote origin refs/heads/main refs/tags/v2.3.1`
   Expect: exit code 0 and exactly one line, `7d0bf664bb487e6172eb006e38a3d4501545f225	refs/heads/main` (a tab between the SHA and the ref name), and no line for the tag. Anything else means the remote changed: stop and report `push main` as `failed` with the full output, and the other two items as `skipped`.
4. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/fix-bug-and-release/with_skill/repos/slug" && npm view @quillkit/slug@2.3.1 version --prefer-online`
   Expect: an E404 error ("No match found for version 2.3.1" or "Not Found"), or no output with exit code 0. Both mean 2.3.1 isn't published yet; here they are the expected result, not a failure. If it prints `2.3.1` instead, the version is already on npm: stop, report `push main` as `failed` with evidence "2.3.1 already on npm", report the other two items as `skipped`, and push nothing.
5. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/fix-bug-and-release/with_skill/repos/slug" && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git push origin main`
   Expect: exit code 0 and a line containing both `7d0bf66..234cf81` and `main -> main`. If the push is rejected for any reason (`[rejected]`, `non-fast-forward`, `fetch first`, a hook error), stop. Do not pull, fetch, rebase, merge or force.
6. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/fix-bug-and-release/with_skill/repos/slug" && GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git push origin refs/tags/v2.3.1`
   Expect: exit code 0 and a line containing `[new tag]` and `v2.3.1 -> v2.3.1`.
7. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/fix-bug-and-release/with_skill/repos/slug" && gh run list --repo quillkit/slug --workflow release.yml --commit 234cf81a0d49c8a23fa8e04889205780180e290a --json databaseId,headBranch,status,conclusion,url`
   Expect: a JSON array with exactly one object whose `headBranch` is `v2.3.1`. Its `databaseId` is the run ID; you need it in steps 8 and 9.
   GitHub takes a few seconds to register the run, so `[]` here is expected at first and is not an error. If you get `[]`, run exactly the same command again, up to 10 runs of this command in total. If it's still `[]` after the 10th run, stop and report `release run` as `failed` with error `no release run found after 10 checks`. If the array has more than one object, or its one object has a `headBranch` other than `v2.3.1`, stop and report the full output.
8. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/fix-bug-and-release/with_skill/repos/slug" && gh run watch RUN_ID --repo quillkit/slug --exit-status --interval 10`
   Replace `RUN_ID` with the `databaseId` from step 7, and nothing else. Set the Bash tool timeout to 600000 for this step.
   Expect: exit code 0 and a final line saying the run completed with `success`. The repeated status lines it prints while it waits are normal.
   If it exits nonzero, the run failed: stop and report `release run` as `failed` with the run URL from step 7 and the names of the failed job and step exactly as printed. Do not open logs, rerun, cancel or retry the run.
   If the Bash tool itself times out before the run finishes, run this same command once more with the same timeout. If it times out again, stop and report `failed` with error `run RUN_ID still in progress after 20 minutes` (with the real run ID in place of RUN_ID).
9. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-2/fix-bug-and-release/with_skill/repos/slug" && gh run view RUN_ID --repo quillkit/slug --json status,conclusion,url`
   Replace `RUN_ID` as in step 8. Expect: `status` is `completed` and `conclusion` is `success`. Put the `url` in evidence.

## Do not
- Do not force-push: no `--force`, `-f`, `--force-with-lease`, no `+` refspecs.
- Do not delete or move tags, branches, releases, repos or packages: no `git push --delete`, `git tag -d`, `git tag -f`, `gh repo delete`, `gh release delete`, `npm unpublish`, `npm deprecate`.
- Do not edit, create or delete files except: none.
- Do not run any command or tool call that isn't in Steps. The only exception is read-only commands to capture evidence: `git status`, `git log -1`, `git rev-parse`, `git ls-remote`, `npm view`, `gh api` GET requests.
- Do not enter passwords, tokens, OTPs or 2FA codes, and do not run login commands (`npm login`, `npm adduser`, `gh auth login`).
- Do not try to fix, work around or rerun a failed step, except as the stop conditions allow.
- Do not put secret values in your report. Give the file and line only.
- Do not run `npm publish` under any circumstances, even if the workflow fails. This repo publishes only from the `release` workflow.
- Do not run `git pull`, `git fetch`, `git merge`, `git rebase`, `git reset`, `git commit`, `git tag`, `git stash` or `git checkout`.
- Do not push anything except `main` in step 5 and `refs/tags/v2.3.1` in step 6: no `git push --tags`, no `--follow-tags`, no other branches or tags.
- Do not run `gh run rerun`, `gh run cancel`, `gh workflow run`, `gh release create`, `gh issue close`, `gh issue comment`, or any `gh api` call that isn't a GET.
- Do not open or read workflow logs (`gh run view --log`, `gh run view --log-failed`).

## Stop conditions
- Stop at the first error: a nonzero exit code, an error message, or output that doesn't match Expect. Don't run any later step. Report every item you didn't finish as `skipped`, with the reason.
- Rate limit (E429, `429`, "Too Many Requests", "rate limit", "secondary rate limit", "created too many repositories", "was submitted too quickly"): stop at once. Never retry.
- Auth error (401, 403, E401, E403, ENEEDAUTH, "Bad credentials", "Permission denied", "requires authentication", "terminal prompts disabled", "could not read Username", a prompt to log in): stop at once. Never retry.
- Browser or 2FA approval (a request for a one-time password, or a URL to approve in a browser): stop. Report the item as `skipped` with an error that starts `NEEDS_USER:` followed by the URL or the prompt text.
- Network timeout (ETIMEDOUT, ECONNRESET, ESOCKETTIMEDOUT, "network timeout" printed by the program): you may rerun that one step once. If it fails again, stop. If the tool itself times out instead (the command is cut off with no error from the program), that is not a network timeout: stop and report, unless the step says otherwise. Never rerun a publish or push that was cut off.
- Anything unexpected (a missing file, a different version, a dirty working tree, a prompt you didn't expect): stop and report it. Don't adapt.
- The only repeats allowed beyond the network-timeout rerun are the ones written into steps 7 and 8.

## Report
End your reply with one block for each of these report items, in this order: `push main` (steps 1–5), `push tag v2.3.1` (step 6), `release run` (steps 7–9). Use exactly this shape, and put nothing after the last block:

```
{
  "item": "push main",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<the `7d0bf66..234cf81  main -> main` line from step 5>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```

```
{
  "item": "push tag v2.3.1",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<the `[new tag]` line from step 6>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```

```
{
  "item": "release run",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<run ID, the run url, and the status and conclusion from step 9>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```
