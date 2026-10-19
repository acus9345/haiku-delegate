# haiku-delegate

A Claude Code skill that hands the purely mechanical steps of a bigger task to Haiku subagents, runs them in parallel, and verifies their results. Design, debugging, naming, writing and judgment calls stay on the main model.

It only spawns agents after you opt in during a session, for example by saying "use haiku for the mechanical parts", "delegate the busywork" or "run the rest with cheap agents".

## What it delegates

A step goes to Haiku only if every input is known up front, success can be checked from the outside, no choice is needed, and a failure is safe to stop at. Typical examples are `npm publish` for a list of packages, pushing release tags, creating repos, watching CI runs, install checks and lint/test runs.

Each agent gets a fixed brief: a goal, exact inputs, numbered commands, "do not" rules, stop conditions (no retrying rate limits or auth errors) and a report format. The main model checks every report with read-only commands before calling anything done.

## Install

```bash
git clone https://github.com/acus9345/haiku-delegate ~/.claude/skills/haiku-delegate
```

## Files

- `SKILL.md`: when to delegate, how to plan, launch, verify and wrap up, and a worked example (publishing 5 npm packages).
- `references/brief-template.md`: the brief template and four filled-in examples.
- `references/not-for-haiku.md`: what stays on the main model, and why.
- `workspace/`: the dry runs used to develop the skill. It holds the eval prompts, the test fixtures (`scripts/make-fixtures.sh` rebuilds them, including their git history), the generated plans, briefs and feedback for iterations 1 and 2, and a snapshot and diff of each skill version. The repo copies under `workspace/iteration-*/` have had their `.git` folders removed.
