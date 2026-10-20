# Task: Push main and v2.3.1 of quillkit/slug, watch the release run, check the install
## Goal
main on github.com/quillkit/slug is 8c9b69f4bf83204a6632546f188b56aae8576bcf, tag v2.3.1 is pushed, its `release` run concluded `success`, and a clean registry install of @quillkit/slug@2.3.1 gives the fixed output.
## Inputs
- Shell: Bash
- Working directory: "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-3/fix-bug-and-release/with_skill/repos/slug"
- Install folder: "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1" (step 11 creates it; steps 12-13 start with their own `cd`)
- Origin main before this job: 7d0bf664bb487e6172eb006e38a3d4501545f225
- Release commit: 8c9b69f4bf83204a6632546f188b56aae8576bcf
- Tag object: 44775b49a046ce8d98fb92edd7afd3108a95eb22
- Pushing main starts no workflow. Pushing the tag starts the `release` workflow (.github/workflows/release.yml), which runs the tests and publishes 2.3.1 to npm. You never publish.
## Steps
1. `git status --porcelain && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD`
   Expect: no status lines, `main`, `8c9b69f4bf83204a6632546f188b56aae8576bcf`.
2. `git cat-file -t v2.3.1 && git rev-parse v2.3.1 "v2.3.1^{commit}"`
   Expect: `tag`, `44775b49a046ce8d98fb92edd7afd3108a95eb22`, `8c9b69f4bf83204a6632546f188b56aae8576bcf`.
3. `git ls-remote origin refs/heads/main refs/tags/v2.3.1`
   Expect: exactly one line, `7d0bf664bb487e6172eb006e38a3d4501545f225	refs/heads/main`. Any `refs/tags/v2.3.1` line, or a different main SHA: stop and push nothing.
4. `npm view @quillkit/slug@2.3.1 version --prefer-online`
   Expect: E404 ("No match found" or "Not Found"), or no output with exit 0. If it prints `2.3.1`, stop and push nothing.
5. `git push origin main`
   Expect: exit 0 and a line with `7d0bf66..8c9b69f` and `main -> main`. If rejected, stop: don't pull, rebase or merge.
6. `git push origin refs/tags/v2.3.1`
   Expect: exit 0 and a line with `[new tag]` and `v2.3.1 -> v2.3.1`.
7. `gh run list --repo quillkit/slug --workflow release.yml --commit 8c9b69f4bf83204a6632546f188b56aae8576bcf --json databaseId,headBranch,status,url`
   Expect: one object with `headBranch` `v2.3.1`. `[]` is expected at first: run the same command again, up to 10 runs in total, then stop with `no release run found`. More than one object: stop.
8. `gh run watch RUN_ID --repo quillkit/slug --exit-status --interval 10`
   Replace RUN_ID with the `databaseId` from step 7. Set the Bash timeout to 600000. Expect: exit 0. If it exits nonzero, report `failed` with the run URL and the failed job and step names, and open no logs. If the tool times out, run it once more, then stop with `still in progress`.
9. `gh run view RUN_ID --repo quillkit/slug --json conclusion,url`
   Same RUN_ID. Expect: `conclusion` `success`. Put the url in evidence.
10. `npm view @quillkit/slug@2.3.1 version --prefer-online`
    Expect: exactly `2.3.1`. E404 or no output is expected at first: run the same command again, up to 10 runs in total, then stop with `2.3.1 not on npm after successful run`.
11. `cd /c && test ! -e "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1" && mkdir -p "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1"`
    Expect: exit 0. If the folder exists, stop.
12. `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1" && npm init -y && npm install --no-audit --no-fund --prefer-online @quillkit/slug@2.3.1`
    Expect: exit 0 and `added 1 package`. ETARGET or E404: stop, don't retry.
13. `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-slug-2.3.1" && node -e "const {slugify}=require('@quillkit/slug'); console.log(slugify('Hello   World')); console.log(slugify('Rock - Paper'))" && npm ls @quillkit/slug`
    Expect: `hello-world`, then `rock-paper`, then a line with `@quillkit/slug@2.3.1`. Quote all three lines in evidence.
## Do not
- Run `npm publish`, even if the run fails or 2.3.1 never shows up on npm.
- Run `git pull/fetch/merge/rebase/reset/commit/tag/stash/checkout`, `gh run rerun/cancel`, `gh workflow run`, `gh release create`, or `gh issue close/comment`.
- Use `npm install -g`, `npm link`, or a local path or tarball for the install.
## Report items
`push main` (steps 1-5), `push tag v2.3.1` (step 6), `release run` (steps 7-9), `install @quillkit/slug@2.3.1` (steps 10-13)
