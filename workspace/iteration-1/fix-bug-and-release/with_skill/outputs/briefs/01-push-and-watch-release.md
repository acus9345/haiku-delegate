# Task: Push main and tag v2.3.1 of quillkit/slug, then watch the release workflow

You are running a fixed, fully specified job for another Claude session. Run the steps exactly as written, in order. You are not being asked to make decisions: if anything doesn't match this brief, stop and report it. Don't ask questions, because nobody will answer them; put them in your report instead.

## Goal
Branch main of github.com/quillkit/slug points at commit 9d8f3521c6916ff87d4fdee90e1ada8130464d96, the annotated tag v2.3.1 is on github.com/quillkit/slug, and the `release` workflow run that the tag push starts has finished with conclusion `success`.

## Inputs
- Shell: Bash (Git Bash on Windows). Use this shell for every command.
- Working directory: "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/fix-bug-and-release/with_skill/repos/slug"
  The path contains a space ("github repo"). Always keep it inside double quotes exactly as written in the steps. Your working directory resets between commands, so every step starts with its own `cd`.
- GitHub repo: quillkit/slug
- Remote: origin, URL https://github.com/quillkit/slug.git
- Branch: main
- Local main (the commit to push): 9d8f3521c6916ff87d4fdee90e1ada8130464d96 ("chore(release): v2.3.1")
- origin/main before this job: 7d0bf664bb487e6172eb006e38a3d4501545f225 ("chore(release): v2.3.0")
- Tag: v2.3.1, annotated, already created locally. Tag object 07b5367ee940920a6747ccbea6aeefd7f0f3ac85, pointing at commit 9d8f3521c6916ff87d4fdee90e1ada8130464d96.
- Workflow: `release` (file .github/workflows/release.yml). It starts by itself when a tag matching `v*` is pushed; it runs the tests and publishes @quillkit/slug 2.3.1 to npm. You never publish anything yourself.

## Steps
1. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/fix-bug-and-release/with_skill/repos/slug" && git status --porcelain && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD`
   Expect: no status lines, then `main`, then `9d8f3521c6916ff87d4fdee90e1ada8130464d96`.
2. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/fix-bug-and-release/with_skill/repos/slug" && git cat-file -t v2.3.1 && git rev-parse v2.3.1 && git rev-parse "v2.3.1^{commit}"`
   Expect: exactly three lines: `tag`, then `07b5367ee940920a6747ccbea6aeefd7f0f3ac85`, then `9d8f3521c6916ff87d4fdee90e1ada8130464d96`.
3. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/fix-bug-and-release/with_skill/repos/slug" && git remote get-url origin`
   Expect: exactly `https://github.com/quillkit/slug.git`.
4. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/fix-bug-and-release/with_skill/repos/slug" && git ls-remote origin refs/heads/main refs/tags/v2.3.1`
   Expect: exactly one line: `7d0bf664bb487e6172eb006e38a3d4501545f225	refs/heads/main` (no line for the tag).
   These other results are also allowed, and change what you expect later:
   - The main line shows `9d8f3521c6916ff87d4fdee90e1ada8130464d96` instead: main was already pushed. Continue; in step 5 expect `Everything up-to-date`.
   - A line `07b5367ee940920a6747ccbea6aeefd7f0f3ac85	refs/tags/v2.3.1` is present: the tag was already pushed. Continue; in step 6 expect `Everything up-to-date`.
   Anything else (main at any other SHA, the tag at any other SHA, no main line) means someone else changed the remote: stop and report `failed` with the full output.
5. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/fix-bug-and-release/with_skill/repos/slug" && git push origin main`
   Expect: exit code 0 and a line containing `7d0bf66..9d8f352  main -> main` (or `Everything up-to-date` if step 4 showed main already at 9d8f352). If the push is rejected for any reason (non-fast-forward, protected branch, "fetch first", a required status check), stop. Do not pull, rebase, merge or force.
6. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/fix-bug-and-release/with_skill/repos/slug" && git push origin refs/tags/v2.3.1`
   Expect: exit code 0 and a line containing `[new tag]` and `v2.3.1 -> v2.3.1` (or `Everything up-to-date` if step 4 showed the tag already on origin at 07b5367). If it is rejected ("already exists", "would clobber existing tag"), stop.
7. `cd "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-1/fix-bug-and-release/with_skill/repos/slug" && git ls-remote origin refs/heads/main refs/tags/v2.3.1`
   Expect: these two lines, in either order:
   `9d8f3521c6916ff87d4fdee90e1ada8130464d96	refs/heads/main`
   `07b5367ee940920a6747ccbea6aeefd7f0f3ac85	refs/tags/v2.3.1`
   A third line `9d8f3521c6916ff87d4fdee90e1ada8130464d96	refs/tags/v2.3.1^{}` may also appear; that is fine. Quote the lines in evidence.
8. `gh run list --repo quillkit/slug --workflow release.yml --commit 9d8f3521c6916ff87d4fdee90e1ada8130464d96 --json databaseId,event,headBranch,status,conclusion,url`
   Expect: a JSON array with exactly one object whose `event` is `push` and `headBranch` is `v2.3.1`. Its `databaseId` is the run ID, a number; write it down, you need it in steps 9 and 10.
   GitHub takes a few seconds to register the run after the tag push, so an empty array `[]` here is expected at first and is not an error. If you get `[]`, run exactly the same command again, up to 10 runs of this command in total. If it is still `[]` after the 10th run, stop and report `failed` with error `no release run found for 9d8f352 after 10 checks`. If the array has more than one object, stop and report the full output.
9. `gh run watch RUN_ID --repo quillkit/slug --exit-status --interval 10`
   Replace `RUN_ID` with the `databaseId` number from step 8, and nothing else. Call the Bash tool with its timeout set to 600000 (10 minutes) for this step.
   Expect: exit code 0 and a final line containing `completed with 'success'`.
   If it exits nonzero, the run failed: stop, and report `failed` with the run URL from step 8 and the names of the failed job and step exactly as the output shows them (for example `X publish` and `X Run npm publish --provenance`). Do not open logs, rerun, cancel or retry the run.
   If the Bash tool itself times out before the run finishes, run this same command once more with the same timeout. If it times out a second time, stop and report `failed` with error `run RUN_ID still in progress after 20 minutes` (with the real number).
10. `gh run view RUN_ID --repo quillkit/slug --json status,conclusion,url,jobs --jq '{status: .status, conclusion: .conclusion, url: .url, jobs: [.jobs[] | {name: .name, conclusion: .conclusion}]}'`
    Replace `RUN_ID` with the same number as in step 9.
    Expect: `status` is `completed`, `conclusion` is `success`, and `jobs` has one entry with name `publish` and conclusion `success`. Put the `url` and the conclusion in evidence.

## Do not
- Do not force-push: no `--force`, `-f`, `--force-with-lease`, no `+` refspecs.
- Do not delete or move tags, branches, releases, repos or packages: no `git push --delete`, `git tag -d`, `git tag -f`, `gh repo delete`, `gh release delete`, `npm unpublish`, `npm deprecate`.
- Do not edit, create or delete files except: none.
- Do not run any command or tool call that isn't in Steps. The only exception is read-only commands to capture evidence: `git status`, `git log -1`, `git rev-parse`, `npm view`, `gh api` GET requests.
- Do not enter passwords, tokens, OTPs or 2FA codes, and do not run login commands (`npm login`, `npm adduser`, `gh auth login`).
- Do not try to fix, work around or rerun a failed step, except as the stop conditions allow.
- Do not put secret values in your report. Give the file and line only.
- Do not run `npm publish` under any circumstances, even if the workflow fails. This project publishes only from the `release` workflow.
- Do not run `git pull`, `git fetch`, `git merge`, `git rebase`, `git reset`, `git commit`, `git tag` (creating or changing tags), `git stash` or `git checkout`.
- Do not run `gh run rerun`, `gh run cancel`, `gh workflow run`, `gh release create`, `gh issue close` or `gh issue comment`.

## Stop conditions
- Stop at the first error: a nonzero exit code, an error message, or output that doesn't match Expect. Don't run any later step. Report every item you didn't finish as `skipped`, with the reason.
- Rate limit (E429, `429`, "Too Many Requests", "rate limit", "secondary rate limit", "created too many repositories", "was submitted too quickly"): stop at once. Never retry.
- Auth error (401, 403, E401, E403, ENEEDAUTH, "Bad credentials", "Permission denied", "requires authentication", a prompt to log in): stop at once. Never retry.
- Browser or 2FA approval (a request for a one-time password, or a URL to approve in a browser): stop. Report the item as `skipped` with an error that starts `NEEDS_USER:` followed by the URL or the prompt text.
- Network timeout (ETIMEDOUT, ECONNRESET, ESOCKETTIMEDOUT, "network timeout"): you may rerun that one step once. If it fails again, stop.
- Anything unexpected (a missing file, a different version, a dirty working tree, a prompt you didn't expect): stop and report it. Don't adapt.
- The only repeats allowed beyond the network-timeout rerun are the ones written into steps 8 and 9.

## Report
End your reply with one block per item, in exactly this shape, and nothing after the last block. There are three items, in this order: `push main` (steps 1-5, plus the main line from step 7), `push tag v2.3.1` (step 6, plus the tag line from step 7), `release workflow run` (steps 8-10).

```
{
  "item": "push main",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<URL, version, commit SHA, exit code, or the exact output line that shows the result>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```

```
{
  "item": "push tag v2.3.1",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<URL, version, commit SHA, exit code, or the exact output line that shows the result>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```

```
{
  "item": "release workflow run",
  "status": "ok | failed | skipped",
  "step": "<last step number reached>",
  "evidence": "<URL, version, commit SHA, exit code, or the exact output line that shows the result>",
  "error": "<exact error text, first ~20 lines, or null>"
}
```
