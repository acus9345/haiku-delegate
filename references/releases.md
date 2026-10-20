# Releases

Read this before you delegate any publish, tag push or push to a release branch.

## Preflight (main model, read-only)

Run these before you write release briefs. Their results become the briefs' exact inputs.

- **Remote state:** `git ls-remote origin refs/heads/main refs/tags/<tag>`. Main should be at the SHA your work builds on, and the tag shouldn't exist yet. Don't trust `origin/main`, which may be missing or stale.
- **npm state:** for a new package, `npm view <pkg>` gives E404. For an existing one, `npm view <pkg> versions --json --prefer-online` doesn't list the new version.
- **Who can publish:** `npm whoami`, plus `npm owner ls <pkg>` for an existing package (or the scope's org for a new one). Run this for local publishes only.
- **What will ship:** if the build output is gitignored, record the `integrity` and `entryCount` from `npm pack --dry-run --json --ignore-scripts` while you review the file list. Run this for local publishes only, because CI packs from the tag.
- **2FA, for local publishes only:** if `npm profile get --json` shows `auth-and-writes`, every publish needs a code nobody here can enter. Don't delegate the publishes; plan for the user to run them. A package can also require 2FA, or refuse tokens, on its own. That shows up as E403 or a sign-in link, which the worker reports as `NEEDS_USER`.
- **Tag style:** `git for-each-ref refs/tags --format='%(refname:short) %(objecttype) %(contents:subject)'` shows the repo's existing tag names and messages.
- **Version bump:** if you used `npm version`, check its diff, because it can reformat package.json.

## NEEDS_USER

When an agent reports `NEEDS_USER`, its command has already exited, so the URL or code prompt it saw is usually dead. Give the user the exact command to run themselves, verify the result, and continue with a brief that starts after that step.

## When CI publishes

If a workflow publishes on a `v*` tag (check RELEASING.md and `.github/workflows/`), the tag push is the publish.

- **No `npm publish` in any brief,** and list it under Do not, so a hand publish isn't the agent's "fix" when the run fails.
- **Check the pipeline before the tag goes out,** because a failure afterwards leaves a public tag with nothing on npm:
  - `npm trust list <pkg>` names this repo and workflow file;
  - `gh api repos/<o>/<r>/actions/workflows --jq '.workflows[] | [.path,.state] | @tsv'` shows the workflow `active`;
  - `gh run list --repo <o>/<r> --workflow <file> --limit 1 --json conclusion` shows the last release run succeeded.
- **One agent does the remote half:** push main, push the tag, find the run by commit SHA, and watch it (Example 2 in `brief-template.md`).
- **Verify the publish came from the tag:** the run concluded `success`, and `npm view <pkg>@<v> gitHead` is the tagged commit.
- **If the run fails,** reading the log is debugging, so it's yours. Whether to fix forward with a new patch version or move the tag is the user's call.
## Local publish when a workflow also publishes on tags

Decide which one publishes before any tag is pushed. Otherwise the two race.

- **Check whether the workflow can actually run** before you choose it: a lockfile exists if it runs `npm ci`; its build produces everything in `files` and `bin`; trusted publishing or a token is set up; and its last run succeeded. If it can't run, or the user asked to publish what's already built, publish locally. If neither is clearly right, ask.
- **Publish locally before the tag push, in the same brief.** The run the tag starts then fails on "cannot publish over" instead of racing. Mention the failing runs to the user in one line at launch.
- **Verify afterwards** that the run failed, and that `npm view <pkg>@<v> dist.integrity` still matches your pack value.
