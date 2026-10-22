# Live tests (2026-10-22)

Real headless Claude Code sessions (`claude -p`, allowlist `Bash(git *)`, `Bash(cd *)`, `Bash(npm test*)`, Read, Glob, Grep, Skill, Agent) on six local repos with 25-second test suites and local bare remotes. Nothing touched the network.

| Run | Prompt | What happened | Fix |
|---|---|---|---|
| 1 | tag + push 6 repos, no mention of Haiku | Skill triggered on its own and launched `haiku-worker`; the brief's `; echo "EXIT=$?"` was refused by the permission checker | Worker rules: plain commands only; `git -C` instead of `cd … && git` |
| 2 | same | Skill triggered; main judged the work quick and did it itself | none (judgment call) |
| 3 | same | Same as run 2 | none |
| 4 | same, plus "use haiku for the mechanical parts" | Test agent ran 6 suites cleanly; push agent's `GIT_TERMINAL_PROMPT=0 GCM_INTERACTIVE=never git …` was refused; main re-briefed the rest and verified on origin | Worker rules: `git -c credential.interactive=false`, no env-var prefixes |

A separate failure test gave a general-purpose Haiku agent (fallback path) a brief whose remote already had the tag: it stopped at the mismatch, pushed nothing, and reported in the compact format.
