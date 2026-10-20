---
name: haiku-delegate
description: Hand the purely mechanical steps of a bigger task (publishing N packages, pushing tags, creating repos, watching CI, install checks, lint/test runs, applying a written patch to several repos) to Haiku subagents, run them in parallel and verify the results, while judgment stays on the main model. Use when the user says "use haiku for the mechanical parts", "delegate the busywork", "run the rest with cheap agents", "farm this out to cheaper models", or names haiku-delegate, or for a long fully specified batch once they opted in this session. Never spawn agents without that opt-in.
---

# Haiku delegate

Run pure-execution steps on Haiku, keep judgment on the main model, and treat every Haiku report as a claim to check.

## Opt-in

Spawn agents only after the user opts in this session ("use haiku for…", "delegate the busywork", naming this skill). The opt-in lasts for the session. Without it, do the work yourself; you may offer once in one line. Opting in doesn't approve the actions themselves (see step 2). If `model: "haiku"` is rejected, tell the user and do the work yourself.

## What goes to Haiku

A step qualifies only if all four hold:

1. **Every input is known**: paths, names, versions, exact commands, and the exact text of any edit or message.
2. **Success is checkable from outside**: an exit code, registry or GitHub state, or file contents.
3. **No choice is needed**: no naming, wording, choosing between approaches, or debugging.
4. **A failure is safe to stop at**: nothing is destroyed or left half-applied.

Split a step that fails a test: do the judgment part, then delegate the rest with exact inputs. For "fix this bug and release it", you fix it, pick the version, write the changelog, and commit and tag locally. Haiku pushes, watches CI and checks the install.

**Local commits and tags stay with you.** They take one command each, the briefs can then pin exact SHAs, and you see the tree before anything leaves the machine. The exception is a commit that can only follow a delegated step, such as a written patch applied to N repos once their tests pass. There the agent commits, using your message file.

**Delegate only when it pays.** Each brief costs main-model output plus a cold-start agent. Delegate batches, long waits (CI, publishes, installs) and noisy output, and run one or two quick commands yourself. For a single item, put its quick steps in the same agent as its long wait.

Keep on the main model: writing code, debugging, reading unfamiliar APIs, picking names, user-facing text, retry decisions, anything security-sensitive, and anything needing the user. For borderline steps, read `references/not-for-haiku.md`.

## Running a delegation

### 1. Plan
Put every delegated step on the task list, marked `[haiku]`, with a **gate**: the verified results it needs, such as "core + utils verified on npm". Launch a brief as soon as its gate is met and a slot is free. Watch for dependencies inside a batch: a package shouldn't be published or install-checked until the packages it depends on are verified.

### 2. Approvals and side effects
Delegate an outward action (publish, push, create a repo, tag, change settings) only if the user approved that specific action this session. If they haven't, ask once with the full list. Before launch, check what the actions set off:

- `.github/workflows/*` that run on `push: tags` or branches. These may publish or deploy.
- `Fixes #N` in commit messages. Write `(#N)` instead unless closing the issue is approved.
- Anything else that would publish the same version.

Avoid or ask about effects that need approval. Mention harmless visible ones (a failing run) in one line. **For any publish or tag push, read `references/releases.md` first** (preflight, 2FA, `NEEDS_USER`, CI-published releases).

### 3. Brief
Write one brief per agent from `references/brief-template.md`. Read it before the first brief of the session. Briefs carry only job-specific parts (goal, inputs, steps with Expect lines, extra Do-not rules, report items). The fixed rules are in the `haiku-worker` agent. A brief is ready when someone with no context could run it without asking a question. "Pick a suitable…", "fix any…" or "if needed" means the step isn't decided yet.

### 4. Launch

```
Agent({ description: "Publish @acme/core 1.0.0", subagent_type: "haiku-worker",
        model: "haiku", run_in_background: true, prompt: "<brief>" })
```

`haiku-worker` (`~/.claude/agents/haiku-worker.md`) runs on Haiku. It holds the fixed rules, can't spawn agents or edit files, and compacts at 100k tokens. If it isn't available, use `general-purpose` with `model: "haiku"`, and add the worker-rules line from brief-template.md.

- At most 4 agents at once. Launch every ready brief in one message. When one finishes, verify it, then launch whatever it unblocks.
- Run them in the background and keep working. You'll be notified when they finish, so don't poll.
- Consecutive steps for one item can share an agent. Put a gate between them when you want to verify an irreversible step first.
- A read-only install check goes in the same agent as the publish or release it checks, after a bounded `npm view` wait for the registry (Examples 1 and 2). Give it its own agent only when nothing in this session published the package.
- For a service that throttles bursts (GitHub repo creation), give the whole batch to one agent to run in sequence.

### 5. Verify
Check every claim yourself with a read-only command before reporting it. If a check disagrees with a report, the check wins.

| Claim | Check |
|---|---|
| published | `npm view <pkg>@<v> version --prefer-online`. For a local publish, `dist.integrity` matches your pack value. For a CI publish, `gitHead` is the tagged commit. |
| repo | `gh api repos/<o>/<r> --jq .html_url` |
| branch | `gh api repos/<o>/<r>/commits/<branch> --jq .sha` equals the expected SHA |
| tag | `gh api repos/<o>/<r>/git/ref/tags/<t> --jq '.object.type+" "+.object.sha'` gives `tag <tag object SHA>`, and `commits/<t>` gives the pinned commit |
| release | `gh api repos/<o>/<r>/releases/tags/<t> --jq .html_url` |
| CI | `gh run list --repo <o>/<r> --commit <sha> --json workflowName,conclusion` |
| trusted publishing | `npm trust list <pkg>` |
| a tag-triggered publish run after your local publish | The run failed, and `dist.integrity` still matches your pack value. |
| install / tests | Accept the agent's quoted exact output. Otherwise rerun one check yourself. |

### 6. Failures
Every `failed` or `skipped` item, and every item that failed verification, comes back to you. Read the exact error and diagnose it. If the fix is mechanical (a wrong path, a missing `--access public`, `master` instead of `main`), send a corrected brief for only the failed items, starting at the failed step. Take rate limits, auth errors, missing approvals and judgment calls to the user. If an item is `skipped` because the thing already exists, verify it; if it's what you wanted, count it as done. Never relaunch a brief unchanged.

### 7. Rate limits
On E429, "secondary rate limit" or "created too many repositories", stop launching anything that hits that service. Tell the user the service, the exact error, what's done and what's pending, and retry only when they say so.

### 8. Wrap-up
Give one table, built from what you verified:

| Item | Result | Evidence |
|---|---|---|
| @acme/core 1.0.0 | published, tagged | [npm](https://www.npmjs.com/package/@acme/core/v/1.0.0) · [v1.0.0](https://github.com/acme/core/tree/v1.0.0) |

Then add **Left:** (steps not done) and **Needs you:** (approvals, clicks, decisions, issues left open, with links). Mark anything you couldn't verify.

## References

- `references/brief-template.md`: the template and four examples (publish + tag + install, CI release + watch, a standalone install check, patch across repos).
- `references/worker-rules.md`: the fixed rules every agent follows.
- `references/releases.md`: release preflight, 2FA, `NEEDS_USER`, releases that CI publishes.
- `references/not-for-haiku.md`: what stays on the main model, and the gray areas.
- `references/worked-example.md`: five npm packages end to end, with gates, a failure and the wrap-up. Read it the first time you plan a multi-package batch.
