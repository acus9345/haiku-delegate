# Skill feedback (haiku-delegate, publish-3-packages dry run)

## The big one: tag-triggered publish workflow + a "publish these built packages" request
All three repos have `release.yml` on `push: tags: v*` that runs `npm publish --provenance`. The user asked to publish the already-built packages *and* tag them. releases.md covers "CI publishes" (no `npm publish` in briefs) and one line: "If you also plan to publish locally, decide which one publishes before any tag is pushed, and ask the user if it isn't clear." That's the whole guidance for the hard case, and it's thin:
- It doesn't say what makes it "clear". I decided local publish without asking because (a) the user said "publish these already-built packages", (b) the workflow can't work: no package-lock.json so `npm ci` fails, and `scripts/build.js` doesn't produce `dist/cli.js` (a CI build would ship a package with a broken bin even if `npm ci` passed). A model that only follows releases.md would likely take the CI path (no `npm publish` in briefs), push tags, and leave three public tags with nothing on npm. The skill should say: "Read the workflow and check it can actually run (lockfile, build script output vs the `files`/`bin` entries) before choosing it."
- It doesn't say how to make the local path safe from the race: publish *before* the tag push in the same brief, so CI later hits "version exists" (E403) instead of racing. I did that; worth one sentence.
- SKILL.md step 2 says "Mention harmless visible ones (a failing run) in one line." A failing *publish* workflow is only harmless if it can't publish; the skill doesn't connect these. I added a verification that the npm `dist.integrity` still equals my local pack value after the runs, to prove CI didn't publish. The verify table has no row for "the expected-to-fail run didn't publish".
- The CI preflight (`npm trust list`, workflow `active`, last run succeeded) only applies when CI is the publisher. There's no "is CI viable?" check for deciding which path to use. I used `gh run list --workflow release.yml` as an informational preflight.

## Install check: same agent or separate?
SKILL.md: "For a single item, put its quick steps in the same agent as its long wait" and "Consecutive steps for one item can share an agent. Put a gate between them when you want to verify an irreversible step first." Example 3 (install check) is framed as a separate agent launched after "you saw @acme/cli live with npm view". These pull in different directions. I folded the install into each publish agent (3 agents instead of 6): the install is read-only, needs no gate, and saves three cold starts. The skill should say which is preferred for publish→install.

## Registry propagation is not handled
Example 3 says "ETARGET or E404: stop, don't retry." Right after a publish, that's the most likely flake. Since I combined install with publish, I added a bounded `npm view <pkg>@<v> version --prefer-online` repeat (up to 10 runs) before `npm install`. The template should include this whenever an install follows a publish closely.

## Briefs with two directories
Worker rule: "Start every command with `cd "<Working directory>"` unless the step already starts with `cd`." The template has one Working directory. An install folder needs every install step to start with its own `cd "..."`. That works, but neither the template nor Example 3 shows a brief that uses two directories. Add a line about it.

## Pack Expect lines: commas
Example 1's Expect line is `"integrity": "sha512-…"` with no trailing comma, but real `npm pack --json` output has `"integrity": "…",` with a comma. "Match the lines, not the JSON shape" is ambiguous here: a literal Haiku could stop on the comma. I wrote "a line containing `…`". The example should do the same.

## Fixed rules: repeat or not
brief-template.md says not to repeat worker rules in briefs. Example 1/2 follow that (no `GIT_TERMINAL_PROMPT`, no `</dev/null`). My first draft repeated them out of caution; I removed them to follow the skill. That's fine, but it means correctness depends on `haiku-worker` being the agent type. The fallback (`general-purpose` + read worker-rules.md) is spelled out, so OK.

## Preflight gaps
- releases.md's 2FA check is only account-level (`npm profile get --json`). A package-level "require 2FA / disallow tokens" setting, or trusted-publishing-only packages, also breaks a local publish (E403, or a web-auth prompt -> NEEDS_USER). Not covered. Also no ownership check: I added `npm whoami` + `npm owner ls`.
- "Tag style" preflight is useful. Existing tags were annotated with message `vX.Y.Z`, so I matched it (`git tag -a v1.2.0 -m v1.2.0`).

## Dependency gating wording
"A package can't be installed or published before the packages it depends on." npm will publish cli with unpublished deps; only the install fails. As policy it's right (don't ship cli 0.9.1 if fmt 1.2.0 failed), so I gated the cli publish on fmt + lint verified. The sentence should say "shouldn't be published" rather than "can't".

## Things I didn't need
- not-for-haiku.md: no borderline steps, so I didn't read it. worked-example.md: SKILL.md never tells you to read it. That was fine here, but it's unclear when it's meant to be used.

## Things I did differently
- Main model made the local tags (as the skill says) before the briefs, so the briefs pin real tag-object SHAs.
- One heads-up line to the user about the failing workflow runs, with no question, because the publish and tags are already approved and the run failure can't publish anything. Wrap-up "Needs you" offers to fix the broken workflow; nothing was approved for that.
