# haiku-delegate

A Claude Code skill that hands the purely mechanical steps of a bigger task to Haiku subagents, runs them in parallel, and verifies their results. Design, debugging, naming, writing and judgment calls stay on the main model.

It runs automatically. Installing the skill gives it standing permission to start Haiku agents whenever a task reaches mechanical batches or long waits, in Claude Code, Cowork, or anywhere else with an Agent tool. You can also ask for it ("use haiku for the mechanical parts", "delegate the busywork"), or say "don't delegate" to switch it off for a session. Publishing, pushing and other outward actions still need your approval as usual.

Claude Code's default is not to start agents unless asked, so a line like this in `~/.claude/CLAUDE.md` backs the skill up there:

```markdown
- Use the haiku-delegate skill automatically, without waiting for me to ask, whenever a task reaches mechanical steps it covers. This is standing permission to spawn its Haiku agents; the outward actions themselves still need my approval.
```

## What it delegates

A step goes to Haiku only if every input is known up front, success can be checked from the outside, no choice is needed, and a failure is safe to stop at. Typical examples are `npm publish` for a list of packages, pushing release tags, creating repos, watching CI runs, install checks and lint/test runs.

Each agent gets a short brief with a goal, exact inputs, numbered commands with expected output, and job-specific "do not" rules. The fixed rules live once in the `haiku-worker` agent instead of in every brief: non-interactive git and npm, no force-pushes or deletes, stop conditions (no retrying rate limits or auth errors) and a one-block-per-item report. The main model checks every report with read-only commands before calling anything done.

## Install

### As a Claude Code plugin (recommended)

This installs the skill and the `haiku-worker` agent together. In a Claude Code session, run:

```
/plugin install haiku-delegate --marketplace acus9345/haiku-delegate
```

On versions before 2.1.275, add the marketplace first:

```
/plugin marketplace add acus9345/haiku-delegate
/plugin install haiku-delegate@haiku-delegate
```

The agent's 100,000-token auto-compact window needs Claude Code v2.1.296 or later.

### As a .skill file (Claude Desktop, Cowork, claude.ai)

Download `haiku-delegate.skill` from the [latest release](https://github.com/acus9345/haiku-delegate/releases/latest) and upload it under Settings → Capabilities → Skills. The file contains the skill only. Without `haiku-worker`, the skill uses general-purpose agents on Haiku that read the same rules from `references/worker-rules.md`.

### By hand

```bash
git clone https://github.com/acus9345/haiku-delegate ~/.claude/skills/haiku-delegate
mkdir -p ~/.claude/agents && cp ~/.claude/skills/haiku-delegate/agents/haiku-worker.md ~/.claude/agents/
```

## Files

- `SKILL.md`: when to delegate, and how to plan, launch, verify and wrap up.
- `references/brief-template.md`: the brief template and four filled-in examples.
- `references/worker-rules.md`: the fixed rules every agent follows. They're the same as the `haiku-worker` system prompt, and a `general-purpose` fallback agent is told to read them.
- `references/releases.md`: release preflight, 2FA, `NEEDS_USER` handling, and releases that CI publishes.
- `references/not-for-haiku.md`: what stays on the main model, and why.
- `references/worked-example.md`: publishing 5 npm packages end to end.
- `.claude-plugin/`: the plugin manifest and a one-plugin marketplace, so the repo installs with `/plugin`.
- `agents/haiku-worker.md`: the subagent definition (Haiku, no nested agents or direct file edits, 100,000-token auto-compact window, the fixed rules).
- `workspace/`: the dry runs used to develop the skill. It holds the eval prompts, the test fixtures (`scripts/make-fixtures.sh` rebuilds them, including their git history), the generated plans, briefs and feedback for iterations 1 to 3 (iteration 3 tests the slimmer skill), and a snapshot and diff of each skill version. The repo copies under `workspace/iteration-*/` have had their `.git` folders removed.
