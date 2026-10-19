# haiku-delegate: feedback from the "fix this bug and release it" dry run

## Contradictions and tension

1. **"One or two quick commands are cheaper to run yourself" vs. the skill's own example for this exact request.** SKILL.md says "Fix this bug and release it" becomes "Haiku pushes, tags, watches CI and checks the install". For a single package, push + tag is two commands, and the install check of a zero-dependency package takes seconds. Taken literally, the cost rule says do it all on main except the CI watch. I followed the example, but bundled push + tag + watch into one agent (the watch is the long wait that justifies the cold start) and kept the install check as a separate agent. The skill should say how to weigh these when there's only one item: "bundle the quick outward steps into the agent that does the long wait" would have settled it.

2. **Who creates the local commit and tag is unclear.** The example sentence says Haiku "tags"; brief Example 1 has the agent run `git tag -a`. But the commit message is wording (judgment) and the commit is local, so I did the commits and the annotated tag on main. Then the brief can carry exact SHAs (tag object `07b5367…`, commit `9d8f352…`) in its Expect lines, and I could check the tree before anything left the machine. I'd suggest a rule: local, reversible git operations that wrap main-model decisions (commit, tag) stay on main; Haiku gets the remote operations. If the skill means otherwise, it should say so and say why.

3. **Wave 2 could be in the same agent as wave 1.** Step 4 says dependent steps for one item can share an agent, which would allow push → watch → install check as one chain. Step 1 says a wave starts only after the previous wave is verified. I kept them separate, because the publish is the irreversible step and I wanted `npm view` from main between them, and because a fresh install right after publish can hit registry lag (ETARGET), which is easier to read after main has confirmed the version is live. The skill doesn't say which rule wins for one item.

## Missing

4. **No guidance for "publish happens in CI on tag push".** Every example has the agent run `npm publish`. Here RELEASING.md forbids hand publishing, and publishing is a side effect of the tag push. Things the skill should mention for this flow:
   - Brief: forbid `npm publish` explicitly. Otherwise, when the run fails, a worker's obvious "fix" is the exact thing the project forbids. I added it to the Do-not list.
   - Preflight: check the trusted publisher (`npm trust list`) and that the workflow is active *before* pushing the tag, because after the tag push a failure leaves a public tag with nothing on npm. The worked example's preflight only checks names are free.
   - Verification table: there's no row for "published by CI". I used `npm view <pkg>@<v> version`, `dist-tags.latest`, and `npm view <pkg>@<v> gitHead` == release commit SHA, which proves the tarball came from the commit that was tagged.

5. **Waiting for something to appear.** After a tag push, the run ID isn't known until GitHub registers the run a few seconds later, and in this environment the Bash tool blocks foreground `sleep`. The skill says nothing about how a Haiku brief should wait. I used "rerun the same `gh run list --commit <sha>` up to 10 times; `[]` is expected at first", with no sleep. That's a guess at a safe pattern (10 quick GETs; no rate-limit risk worth worrying about). A blessed pattern in brief-template.md would help.

6. **Values produced at runtime.** Checklist item 1 says every input is known up front, and "Filling it in" says shell variables don't survive between tool calls. But the run ID can only come from step 8's output. I wrote "replace RUN_ID with the databaseId from step 8, and nothing else". The skill should say explicitly that copying a value printed by an earlier step of the same brief is allowed, and show how to phrase it, or else give a single-command pattern.

7. **Bash tool timeout vs. long waits.** `gh run watch` can run longer than the Bash tool's 10-minute maximum. The skill sends "watching CI runs" to Haiku but doesn't mention the tool timeout. I told the agent to set the timeout to 600000 and allowed exactly one rerun of the watch on a tool timeout. This should be in the template's stop conditions or in "Filling it in".

8. **Implicit outward side effects aren't covered under approvals.** A commit message with "Fixes #41" auto-closes the issue when main is pushed. That's an outward action the user didn't approve ("nothing else is approved"), triggered by an approved action. I used `(#41)` with no closing keyword and offered to close it at wrap-up. The approvals section should name this class of thing: issue-closing keywords, tag-triggered workflows, deploy hooks on push.

9. **Paths with spaces.** The working directory here is under `github repo`. None of the template's examples quote paths, and Haiku will copy that style. I quoted every `cd` and called the space out in Inputs. "Filling it in" should say to quote every path.

10. **"One block per item" when there's one item but several outward actions.** With a single package, "item" could mean the package (one block, so a partial failure like "main pushed, tag not" gets squeezed into one evidence string) or each action. I used three blocks (`push main`, `push tag v2.3.1`, `release workflow run`) so partial progress is unambiguous. The template should say which.

11. **The tag-pushed check is weak.** The verification table checks `gh api …/git/ref/tags/<tag> --jq .ref`, which only proves a ref with that name exists, not that it points at the right object. I check `.object.type` and `.object.sha` against the local `git rev-parse <tag>`. Same idea for "branch pushed", which the table already does with the SHA.

## Gray-area guidance that would have misled

12. **`npm version X --no-git-tag-version` is listed as the mechanical half of a version bump.** In this repo it would re-serialize the hand-formatted package.json (`"files": ["src"]` and the inline objects become multi-line), turning a one-line diff into a reformat. I edited the `version` line by hand. not-for-haiku.md might note: check the diff after `npm version`, or edit the line directly when the file is hand-formatted.

13. **The skill doesn't say whether a separate fix commit is fine when RELEASING.md only describes the release commit.** I made two commits (`fix: … (#41)` and `chore(release): v2.3.1`) rather than hiding the fix in a chore commit. This is mostly a repo-convention question, but the skill's "fix this bug and release it" example could show the commit shape.

## Things I did differently from the text

- Main created the annotated tag locally instead of the agent (see 2).
- The install check is delegated though it's borderline on cost (see 1). I'd accept "do it yourself" as the better call for a single zero-dependency package.
- `npm test` runs on main, not Haiku. It's in the "typical Haiku work" list, but here it's one 60 ms command whose result I needed to judge the fix.
- Preflight includes a security-config read (`npm trust list`) on main. The skill lists trusted-publishing *setup* as Haiku work with decided values; reading and judging the current config is mine.

## Test-harness note (not the skill)

- The skill says to put the plan on the session's task list. As a subagent in this dry run, `update_plan` was blocked by a hook, so the task list exists only in plan.md.
