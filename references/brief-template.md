# Haiku briefs

A brief holds only what is specific to one job. The fixed rules are in `worker-rules.md`, which is also the `haiku-worker` agent's system prompt. They cover the `cd` prefix, non-interactive git and npm, no force or deletes, the stop conditions and the report format. Don't repeat them in a brief.

If you launch `general-purpose` instead of `haiku-worker`, make the brief's first line: `First read "<absolute path to references/worker-rules.md>" and follow it.`

## Template

````markdown
# Task: <title>
## Goal
<One sentence: what is true when you're done.>
## Inputs
- Shell: <Bash | PowerShell>
- Working directory: "<absolute path>"
- <name>: <exact value>
- <What any outward action sets off, e.g. "Pushing the tag starts `release`. Don't watch, rerun or cancel it.">
## Steps
1. `<exact command, every argument filled in>`
   Expect: <exit 0, an exact line, a value>
## Do not
- <Only what is specific to this job.>
## Stop
- <Only extra conditions, if any.>
## Report items
`<item>` (steps 1–n), `<item>` (step m)
````

## Filling it in

- **Plain commands only.** Background agents can't answer permission prompts, so a command the permission checker can't verify is refused. Avoid `$?`, shell variables, `VAR=value` prefixes, `$(…)`, loops, `; echo` and `cd … && git` (write `git -C "<dir>"`). One step, one plain command or a short `&&` chain. A wait is a repeat the agent runs, not a shell loop.
- **Exact means exact.** Use absolute quoted paths, scoped package names, full versions and full SHAs. For a commit message or an edit longer than a line, write a file and pass its path.
- **Approval first.** Every outward step must already be approved by the user in this session.
- **Your decisions get pinned.** Make commits and tags that record your decisions locally, before launch. The brief's first steps check HEAD, the tag object SHA (`git rev-parse <tag>`) and its commit.
- **Make steps safe to rerun.** Check that the thing doesn't already exist before the irreversible step: the tag isn't on the remote (`git ls-remote`, not `origin/main`), and the version isn't on npm.
- **Pin the tarball when build output is gitignored.** Before publishing, check the `"integrity"` and `"entryCount"` lines from `npm pack --dry-run --json --ignore-scripts` against your values. Match the lines, not the JSON shape, and forbid rebuilds.
- **Match fragments.** Write Expect as "a line containing `…`". Real output adds trailing commas, quotes and longer abbreviated SHAs (`a83f0c6..c41e9a0` may print longer), and a strict worker stops on any of these. Match the stable part, such as `main -> main`, and check exact SHAs in your own verification.
- **A second directory.** A step that runs outside the working directory (for example an install folder) starts with its own `cd "<path>" &&`. List the folder under Inputs.
- **Install after publish.** When an install check follows a publish in the same brief, put a bounded `npm view <pkg>@<v> version --prefer-online` repeat before the install, because the registry can lag.
- **Mark expected errors and benign noise.** `npm view <pkg>@<unpublished>` gives E404 "No match found for version" on current npm, or nothing with exit 0 on older npm; accept both. `npm notice` and `npm warn` lines with exit 0 are fine.
- **Waits are bounded repeats.** Agents can't sleep. Write "If `[]`, run the same command again, up to 10 runs in total." For `gh run watch`, set the Bash timeout to 600000 and allow one rerun, since watching is read-only.
- **Copied values are identifiers only.** "Replace `RUN_ID` with the `databaseId` from step 7" is fine. Never leave a choice to the agent.
- **Report items.** Make one per package or repo, and one per outward action when there are several (push main, push tag, CI run).
- **Several items in one agent.** State the order. One failure stops the whole brief, so put independent items in separate agents.
- **Windows.** Git Bash paths look like `/c/...`. Keep arguments ASCII, and use `è`-style escapes inside JS strings.

## Example 1: publish a package, push its tag, check the install

Context: `@acme/core` 1.0.0 is built, and `dist/` is gitignored. You tagged `v1.0.0` (annotated) locally on HEAD `3f9c2a7…`, which `git ls-remote` shows is already on origin's main. The tag push starts `release`, which will fail because 1.0.0 is already published, and you told the user. The user approved publishing as public and pushing the tag. Its bin is `acme-core`.

````markdown
# Task: Publish @acme/core 1.0.0, push tag v1.0.0, check a clean install
## Goal
@acme/core 1.0.0 is on npm as public, annotated tag v1.0.0 on commit 3f9c2a7e5b1d4c8a9e0f6b2d7c4a1e8f5b3d9c0a is on github.com/acme/core, and a clean install prints 1.0.0.
## Inputs
- Shell: Bash
- Working directory: "/c/work/acme/packages/core"
- Install folder: "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-core-1.0.0" (step 9 creates it)
- Tag object: 8d4b1f6e2c9a7035b1e8d2f4a6c0e9b3d7f5a128
- Pushing the tag starts `release`, which is expected to fail. Don't look at it.
## Steps
1. `git status --porcelain && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD`
   Expect: no status lines, `main`, `3f9c2a7e5b1d4c8a9e0f6b2d7c4a1e8f5b3d9c0a`.
2. `node -p "const p=require('./package.json'); p.name+'@'+p.version"`
   Expect: `@acme/core@1.0.0`
3. `git cat-file -t v1.0.0 && git rev-parse v1.0.0 "v1.0.0^{commit}"`
   Expect: `tag`, `8d4b1f6e2c9a7035b1e8d2f4a6c0e9b3d7f5a128`, `3f9c2a7e5b1d4c8a9e0f6b2d7c4a1e8f5b3d9c0a`.
4. `git ls-remote --tags origin refs/tags/v1.0.0`
   Expect: no output. Any line: stop, publish nothing.
5. `npm pack --dry-run --json --ignore-scripts`
   Expect: a line containing `"integrity": "sha512-209H7yLh/mXsMPQ2y7LC9xXziLv78j+66lDTWbwhcNDRmohvNAB831OyhKYMS4rGruu//LkKQSm3avXsqn4YTw=="` and a line containing `"entryCount": 7`. If either differs, stop.
6. `npm view @acme/core@1.0.0 version --prefer-online`
   Expect: E404 ("No match found" or "Not Found"), or no output with exit 0. If it prints `1.0.0`, report all items `skipped` ("already on npm") and stop.
7. `npm publish --access public`
   Expect: exit 0 and a line containing `+ @acme/core@1.0.0`.
8. `git push origin refs/tags/v1.0.0`
   Expect: exit 0 and a line containing `[new tag]`.
9. `cd /c && test ! -e "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-core-1.0.0" && mkdir -p "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-core-1.0.0"`
   Expect: exit 0. If the folder exists, stop.
10. `cd "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-core-1.0.0" && npm view @acme/core@1.0.0 version --prefer-online`
    Expect: `1.0.0`. E404 or no output is expected at first: run the same command again, up to 10 runs in total, then stop with `1.0.0 not visible on registry`.
11. `cd "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-core-1.0.0" && npm init -y && npm install --no-audit --no-fund --prefer-online @acme/core@1.0.0 && ./node_modules/.bin/acme-core --version`
    Expect: exit 0, a line containing `added`, then exactly `1.0.0`. Quote the version line.
## Do not
- Push anything but `refs/tags/v1.0.0`, or create or change tags.
- Run `npm run build`, `npm install`, `npm ci`, `npm version`, or `npm pack` without `--dry-run` in the working directory.
- Use `-g`, `npm link`, or a local path or tarball for the install.
- Look at, rerun or cancel Actions runs.
## Report items
`npm publish @acme/core@1.0.0` (steps 1–7), `push tag v1.0.0` (step 8), `install @acme/core@1.0.0` (steps 9–11)
````

## Example 2: push a release that CI publishes, and watch the run

Context: you fixed a bug in `@acme/slug`, committed `chore(release): v2.3.1` at `c41e9a0…`, and tagged `v2.3.1` (tag object `5b7e2d9…`). Origin's main is at `a83f0c6…`. `release.yml` publishes on `v*` tags with trusted publishing, and you ran the CI preflight in `releases.md`. The user approved the release.

````markdown
# Task: Push main and v2.3.1 of acme/slug, watch the release run
## Goal
main on github.com/acme/slug is c41e9a0b7d2f5836e1a4b9c07d3f6e2a8b5c1d94, tag v2.3.1 is pushed, and its `release` run concluded `success`.
## Inputs
- Shell: Bash
- Working directory: "/c/work/acme/slug"
- Origin main before this job: a83f0c6d1e9b2754c8a0f3e6d9b1c4a7e2f5d803
- Tag object: 5b7e2d9c3a1f8e6b4d0c2a9f7e5b3d1c8a6f4e20
- The tag push starts `release`, which publishes 2.3.1 to npm. You never publish.
## Steps
1. `git status --porcelain && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD`
   Expect: no status lines, `main`, `c41e9a0b7d2f5836e1a4b9c07d3f6e2a8b5c1d94`.
2. `git cat-file -t v2.3.1 && git rev-parse v2.3.1 "v2.3.1^{commit}"`
   Expect: `tag`, `5b7e2d9c3a1f8e6b4d0c2a9f7e5b3d1c8a6f4e20`, `c41e9a0b7d2f5836e1a4b9c07d3f6e2a8b5c1d94`.
3. `git ls-remote origin refs/heads/main refs/tags/v2.3.1`
   Expect: exactly one line, `a83f0c6d1e9b2754c8a0f3e6d9b1c4a7e2f5d803	refs/heads/main`.
4. `npm view @acme/slug@2.3.1 version --prefer-online`
   Expect: E404, or no output with exit 0. If it prints `2.3.1`, stop and push nothing.
5. `git push origin main`
   Expect: exit 0 and a line containing `main -> main`. If rejected, stop: don't pull, rebase or merge.
6. `git push origin refs/tags/v2.3.1`
   Expect: exit 0 and a line containing `[new tag]`.
7. `gh run list --repo acme/slug --workflow release.yml --commit c41e9a0b7d2f5836e1a4b9c07d3f6e2a8b5c1d94 --json databaseId,headBranch,status,url`
   Expect: one object with `headBranch` `v2.3.1`. `[]` is expected at first: run the same command again, up to 10 runs in total, then stop with `no release run found`. More than one object: stop.
8. `gh run watch RUN_ID --repo acme/slug --exit-status --interval 10`
   Replace RUN_ID with the `databaseId` from step 7. Set the Bash timeout to 600000. Expect: exit 0. If it exits nonzero, report `failed` with the run URL and the failed job and step names, and open no logs. If the tool times out, run it once more, then stop with `still in progress`.
9. `gh run view RUN_ID --repo acme/slug --json conclusion,url`
   Expect: `conclusion` `success`. Put the url in evidence.
## Do not
- Run `npm publish`, even if the run fails.
- Run `git pull/fetch/merge/rebase/reset/commit/tag/stash/checkout`, `gh run rerun/cancel`, `gh workflow run`, `gh release create`, or `gh issue close/comment`.
## Report items
`push main` (steps 1–5), `push tag v2.3.1` (step 6), `release run` (steps 7–9)
````

To check the install too, append Example 1's steps 9–11 (the version wait comes first) and a fourth report item.

## Example 3: install check on its own

Use this only for a package nothing in this session published. After a publish, the check goes in the publishing agent, as in Example 1.

Context: `@acme/cli@1.0.0` is live, and you saw it with `npm view`. Its bin is `acme`. You picked an unused temp folder. No approval is needed beyond permission to delegate.

````markdown
# Task: Install @acme/cli 1.0.0 in a temp folder and check `acme --version`
## Goal
A clean registry install works and `acme --version` prints 1.0.0.
## Inputs
- Shell: Bash
- Working directory: "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-cli-1.0.0" (step 1 creates it)
## Steps
1. `cd /c && test ! -e "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-cli-1.0.0" && mkdir -p "/c/Users/me/AppData/Local/Temp/haiku-verify/acme-cli-1.0.0"`
   Expect: exit 0. If the folder exists, stop.
2. `npm init -y && npm install --no-audit --no-fund --prefer-online @acme/cli@1.0.0`
   Expect: exit 0 and `added N packages`. ETARGET or E404: stop, don't retry.
3. `./node_modules/.bin/acme --version`
   Expect: exactly `1.0.0`. Quote it.
## Do not
- Use `-g`, `npm link`, or a local path or tarball.
## Report items
`install @acme/cli@1.0.0`
````

For a library with no bin, replace step 3 with a `node -e` smoke test of the fixed function. Run the same snippet against the local source first, so the Expect line holds the exact output:

```
3. `node -e "const {slugify}=require('@acme/slug'); console.log(slugify('Hello   World'))" && npm ls @acme/slug`
   Expect: `hello-world`, then a line with `@acme/slug@2.3.1`.
```

## Example 4: apply a written patch to a repo, test, commit and push

This is the exception to "local commits stay with you": the commit can only happen once the tests pass in each repo. Send one brief per repo, up to 4 at once.

````markdown
# Task: Apply http-timeout.patch to acme/http, test, commit, push main
## Goal
The patch is committed on main of github.com/acme/http with the given message, after the tests passed.
## Inputs
- Shell: Bash
- Working directory: "/c/work/acme/http"
- Patch: "/c/work/acme/patches/http-timeout.patch" (changes src/client.js, test/client.test.js)
- Message file: "/c/work/acme/patches/http-timeout.msg"
- Pushing main starts `ci`. Don't look at it.
## Steps
1. `git status --porcelain && git rev-parse --abbrev-ref HEAD`
   Expect: no status lines, `main`.
2. `git pull --ff-only origin main && git apply --check "/c/work/acme/patches/http-timeout.patch"`
   Expect: exit 0. If the patch doesn't apply, stop. No `--3way` and no hand edits.
3. `git apply "/c/work/acme/patches/http-timeout.patch" && git status --porcelain`
   Expect: exactly ` M src/client.js` and ` M test/client.test.js`.
4. `npm test`
   Expect: exit 0. Quote the pass/fail summary. If any test fails, stop and don't commit.
5. `git add src/client.js test/client.test.js && git commit -F "/c/work/acme/patches/http-timeout.msg" && git push origin main && git rev-parse HEAD`
   Expect: exit 0, `main -> main`, and a SHA for evidence.
## Do not
- Run `git stash`, `git reset`, `git checkout -- <file>`, `git rebase` or `npm install`.
## Report items
`acme/http`
````
