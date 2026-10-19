---
name: haiku-delegate
description: Hand the purely mechanical steps of a bigger task to Haiku subagents (Agent tool with model "haiku"), run them in parallel, and verify their results, while design, debugging, naming, writing and judgment calls stay on the main model. Use this whenever the user says things like "use haiku for the mechanical parts", "delegate the busywork", "run the rest with cheap agents", "hand the boring steps to haiku", "farm this out to cheaper models", or names haiku-delegate. Also use it when you are about to run a long batch of repetitive, fully specified steps (publish N npm packages, push N release tags, create N repos, verify N installs, watch CI runs, run lint/test across repos, apply an already-written patch to several repos) and the user has opted in to delegation earlier in this session. Without that opt-in, do not spawn agents.
---

# Haiku delegate

Some steps of a big task are pure execution: the command is known, the inputs are known, and any competent model would get the same result. Running them on the main model spends expensive tokens and fills the main context with install logs and CI output. This skill hands those steps to Haiku subagents, keeps everything that needs judgment on the main model, and treats every Haiku report as a claim to check before it reaches the user.

## Opt-in comes first

Spawn Haiku agents only after the user has opted in during this session: "use haiku for the mechanical parts", "delegate the busywork", "run the rest with cheap agents", naming this skill, or similar. The opt-in holds for the rest of the session unless they take it back.

If you notice a long mechanical batch and the user hasn't opted in, do the work yourself. You may offer once, in one line ("These 15 steps are mechanical; want me to hand them to Haiku agents?"), and drop it if they don't take it up.

Opting in to delegation is not approval of the actions themselves; see step 2 below.

If the Agent tool rejects `model: "haiku"`, tell the user and run the steps yourself rather than delegating to a bigger model.

## What goes to Haiku

A step goes to Haiku only if all four are true:

1. **Every input is known up front**: paths, names, versions, exact commands, and the exact text of any edit or commit message.
2. **Success is checkable from the outside**: an exit code, registry state, GitHub state, or a file's contents.
3. **No choice is needed**: no naming, no wording that matters, no deciding between approaches, no debugging.
4. **A failure is safe to stop at**: nothing is destroyed or left half-applied in a way that's hard to undo.

When a step fails one of these, split it. Do the judgment part on the main model, turn the result into exact inputs, then delegate the rest. "Fix this bug and release it" becomes: you fix the bug, pick the version number and write the changelog entry; Haiku pushes, tags, watches CI and checks the install.

Passing the checklist makes a step eligible, not required. Each brief costs some writing plus a cold-start agent, so one or two quick commands are cheaper to run yourself. Delegation pays off for batches (the same steps across N items), long waits (CI runs, publishes, installs), and noisy output you don't need in your context.

Typical Haiku work:

- creating GitHub repos and pushing
- `npm publish` for a list of packages
- pushing release tags
- setting up npm trusted publishing with values you've already decided
- installing a published package in a temp folder and running its `--version`
- watching CI runs and reporting pass/fail
- applying an exact, already-written patch to several repos, then running their tests, committing and pushing
- running lint, typecheck and test commands and reporting results
- secret scans (Haiku collects the findings; you triage them)
- `npm pack --dry-run` file checks (Haiku collects the file list; you decide whether it's right)

Keep on the main model: designing or writing code, debugging failures, reading unfamiliar APIs, picking names or fallbacks, writing READMEs or anything user-facing, deciding whether to retry after a rate limit, anything security-sensitive, and anything that needs the user's judgment or approval. `references/not-for-haiku.md` gives the reason for each and covers the gray areas (version bumps, changelogs, scan triage). Read it when a step is borderline.

## Running a delegation

### 1. Plan on the task list

Before launching anything, put every delegated step on the session's task list, marked `[haiku]`, next to the main-model steps it depends on, in dependency order. Group the delegated steps into waves: everything in a wave can run at once, and a wave starts only after the previous wave's results are verified.

A typical release chain is repo creation → publish → tag → trusted publishing → install check. Also look for dependencies between items: a package that depends on another package in the same batch can't pass an install check until that dependency is published.

### 2. Check approvals

Outward-facing actions (publishing, pushing, creating repos, pushing tags, changing registry or repo settings) are delegated only when the user has already approved that action in this session. Approval is specific: "publish these 5 packages" approves publishing those 5 at those versions, not creating repos or pushing to main. If the plan has outward actions the user hasn't approved, ask once with the complete list, then delegate.

Haiku agents never enter passwords, tokens, OTPs or 2FA codes, and never run login commands. When a step needs the user's browser approval, the agent stops and reports `NEEDS_USER` with the URL or prompt it saw, and you pass that to the user.

### 3. Write one brief per agent

Build every brief from the fixed template in `references/brief-template.md`. Read that file before writing the first brief of the session; it has three filled-in examples. The template has six parts: goal, exact inputs, numbered steps with exact commands, "do not" rules, stop conditions, and the report format. Keep all six every time, even when they feel redundant. A Haiku agent starts with none of this conversation's context, and the brief is the only thing standing between it and an improvised `--force`.

A brief is ready when someone with no context could run it without asking a question. If you catch yourself writing "pick a suitable…", "fix any…" or "adjust if needed", that step isn't mechanical yet: decide it yourself and write down the answer.

### 4. Launch

```
Agent({
  description: "Publish @acme/core 1.0.0",
  subagent_type: "general-purpose",
  model: "haiku",
  run_in_background: true,
  prompt: "<the complete filled-in brief>"
})
```

- At most 4 Haiku agents run at once. Launch independent ones together in one message. When one finishes, verify its result, then launch the next queued one.
- Run them in the background by default and keep working on main-model steps meanwhile. You're notified when each agent finishes, so don't poll.
- Dependent steps for a single item can share one agent as consecutive steps (publish a package, then tag it), because stop-at-first-error keeps the chain safe. Dependencies across items wait for the next wave.
- When a service throttles bursts (GitHub repo creation especially), give the whole batch to one agent to run in sequence instead of fanning out.

### 5. Verify before reporting

Each agent's report is a claim. Before telling the user something is done, check it yourself with a cheap read-only command. Run these directly rather than delegating them:

| Claim | Check |
|---|---|
| npm package published | `npm view <pkg>@<version> version --prefer-online`; for a local publish, `npm view <pkg>@<version> dist.integrity` matches your `npm pack --dry-run --json`; for a CI publish, `npm view <pkg>@<version> gitHead` is the tagged commit |
| repo created | `gh api repos/<owner>/<repo> --jq .html_url` |
| branch pushed | `gh api repos/<owner>/<repo>/commits/<branch> --jq .sha` matches the reported SHA |
| tag pushed | `gh api repos/<owner>/<repo>/commits/<tag> --jq .sha` is the commit you pinned in the brief (a ref with the right name can still point at the wrong commit) |
| release created | `gh api repos/<owner>/<repo>/releases/tags/<tag> --jq .html_url` |
| CI result | `gh run list --repo <owner>/<repo> --commit <sha> --json databaseId,workflowName,status,conclusion` |
| trusted publishing | `npm trust list <pkg>` |
| install check | `npm view` shows the version is live; accept the agent's `--version` output if it's quoted exactly, otherwise rerun one check yourself |
| tests / lint | the agent's quoted summary line and exit code; for a pushed commit, the CI run on that SHA |

If a check disagrees with the report, the check wins and the item counts as failed.

### 6. Failures come back to you

Any item reported `failed` or `skipped`, or whose verification disagreed, comes back to the main model. Never let a Haiku agent improvise a fix, and don't relaunch an unchanged brief hoping for a different result.

1. Read the exact error text and diagnose it yourself.
2. If the fix is mechanical and you understand the cause (wrong path, missing `--access public`, the branch is `master` not `main`), write a corrected brief for only the failed items, starting at the failed step.
3. If it's a rate limit, an auth error, a missing approval, or a judgment call (the name is taken, the tests fail), ask the user.
4. If it's `skipped` because the thing already exists ("already published", "tag already exists"), verify it. If the existing state is what you wanted, count it as done.

### 7. Rate limits

If any agent reports a rate limit (E429, "too many requests", GitHub's "secondary rate limit" or "created too many repositories"):

- stop launching new agents that hit the same service (npm registry, GitHub API, …); agents already running stop themselves under their brief's stop conditions;
- tell the user which service, the exact error text, what's done, and what's still pending;
- retry only when the user says so.

### 8. Wrap-up

Give the user one table, built from what you verified rather than what the agents claimed:

| Item | Result | Evidence |
|---|---|---|
| @acme/core 1.0.0 | published, tagged | [npm](https://www.npmjs.com/package/@acme/core/v/1.0.0) · [v1.0.0](https://github.com/acme/core/tree/v1.0.0) |

Then two short lines: **Left:** steps not done yet. **Needs you:** approvals, browser clicks and decisions, with links. If something couldn't be verified, say so in its row.

## Worked example: publishing 5 npm packages end to end

Earlier in the session the user said "use haiku for the mechanical parts". Now: "create repos for the five @acme packages in `packages/`, publish them to npm as public packages, tag them, set up trusted publishing for `release.yml`, and check the installs."

The packages are `@acme/core`, `@acme/utils`, `@acme/http`, `@acme/test-kit` and `@acme/cli`, all at 1.0.0 and already built. `@acme/cli` depends on `@acme/core` and `@acme/utils`.

**Main model first.** Read each `package.json` (name, version, `files`, `bin`, `repository`), confirm `dist/` exists, and confirm each name is free (`npm view <pkg>` should return E404). The request names every outward action (repos, publish, tags, trusted publishing), so it counts as approval for those five packages. If it hadn't, you'd ask once with the full list.

**Task list:**

```
[main]  Preflight: package.json fields, dist/, names free
[haiku] Wave 1: npm pack --dry-run + secret scan, all 5 (1 agent; local and fast)
[main]  Review file lists and scan findings
[haiku] Wave 2: create 5 GitHub repos + push main (1 agent, sequential; GitHub throttles repo creation)
[haiku] Wave 3: publish + tag core, utils, http, test-kit (4 agents in parallel)
[haiku] Wave 3b: publish + tag cli (after core and utils are verified on npm)
[haiku] Wave 4: trusted publishing, all 5 (1 agent, sequential)
[haiku] Wave 5: install check, all 5 (4 agents, then 1)
[main]  Verify everything + wrap-up table
```

**Wave 3.** Four briefs like Example 1 in `references/brief-template.md`, one per package, launched in one message with `run_in_background: true`. While they run, you write the wave 4 and wave 5 briefs. As each report arrives, verify it:

```
npm view @acme/core@1.0.0 version                        → 1.0.0
gh api repos/acme/core/git/ref/tags/v1.0.0 --jq .ref     → refs/tags/v1.0.0
```

Once core and utils check out, launch the cli brief.

**A failure.** The `@acme/http` agent reports:

```
{
  "item": "@acme/http",
  "status": "failed",
  "step": "4",
  "evidence": "exit code 1",
  "error": "npm error code E402\nnpm error 402 Payment Required - PUT https://registry.npmjs.org/@acme%2fhttp - You must sign up for private packages"
}
```

It stopped without retrying, as its brief told it to. You diagnose it: `packages/http/package.json` has no `publishConfig.access`, and that brief was missing `--access public`, so npm tried to publish a scoped package as private. The user asked for public packages, so the fix is mechanical: a corrected brief that starts at the publish step with `--access public`. Had it been an E403 or an E429 instead, you'd stop and ask the user.

What if the wave 2 agent had reported "created too many repositories" after the third repo? Then you'd launch nothing else that talks to GitHub (wave 3 pushes tags, so it waits too), tell the user that 3 of 5 repos exist and 2 are pending, and wait for them to say when to continue.

**Wave 4.** One agent runs `npm trust github <pkg> --file release.yml --repo acme/<name> --allow-publish --yes` for each package in turn. If npm asks for browser approval, the agent stops with `NEEDS_USER` and the URL it was shown; pass that to the user, and once they've approved, verify with `npm trust list <pkg>`.

**Wrap-up:**

| Item | Result | Evidence |
|---|---|---|
| @acme/core 1.0.0 | repo, published, tagged, trusted publishing, install ok | [npm](https://www.npmjs.com/package/@acme/core/v/1.0.0) · [repo](https://github.com/acme/core) · [v1.0.0](https://github.com/acme/core/tree/v1.0.0) |
| @acme/http 1.0.0 | published on the second attempt (added `--access public`), tagged, trusted publishing, install ok | [npm](https://www.npmjs.com/package/@acme/http/v/1.0.0) · [repo](https://github.com/acme/http) · [v1.0.0](https://github.com/acme/http/tree/v1.0.0) |
| … | … | … |

**Left:** nothing. **Needs you:** nothing.
