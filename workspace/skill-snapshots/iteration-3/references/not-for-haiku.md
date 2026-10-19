# Keep these on the main model

Each of these fails at least one of the four checklist tests in SKILL.md. The reason matters more than the list: when a step isn't on it, ask whether the same reason applies.

- **Designing or writing code.** If the brief already contained the code, there'd be nothing left to delegate, so handing it over means letting a cheaper model make design decisions nobody reviews.
- **Debugging failures.** Debugging means forming hypotheses about output nobody predicted, and a worker told to "make it pass" tends to fix the symptom (retry, force, delete, loosen a check) instead of the cause.
- **Reading unfamiliar APIs.** Here the understanding is the deliverable, and a misreading silently corrupts every step built on it.
- **Picking names or fallbacks**, for example switching to a scoped package name when the plain one is taken and then updating every doc that mentions it. The choice spreads across registries, repos and docs, and once something is published under it, it's hard to take back.
- **Writing READMEs or anything user-facing.** The wording speaks for the user, so it needs their context and taste, and "good enough" text tends to get shipped unread.
- **Deciding whether to retry after a rate limit.** Retrying too soon can extend a block or trip abuse detection on the user's account, so that's the user's call; the main model can advise.
- **Anything security-sensitive** (tokens, secrets, permissions, auth or publishing configuration). A mistake can leak credentials or open access, and it may not show up until someone exploits it.
- **Anything that needs the user's judgment or approval.** A background worker can't ask the user anything, and the user approved actions to the main model, not to an unattended agent.

## Gray areas: split them

Most borderline steps have a judgment part and a mechanical part. Do the first, delegate the second.

- **Version bumps and changelog entries.** Choosing patch, minor or major and writing the entry text is judgment, so it's yours, along with the local release commit and tag that record it (they're one command each, and then the briefs can carry exact SHAs). Pushing them, watching CI and checking the install are mechanical. Check the diff after `npm version`, which can reformat a hand-formatted package.json; editing the version line by hand is fine.
- **`npm pack --dry-run` checks.** Haiku collects the file list and sizes. Deciding whether a file belongs in the package, or whether one is missing, is yours.
- **Secret scans.** Haiku runs the scanner and reports file, line and rule, never the value. Deciding whether a hit is real, and what to do about it, is yours.
- **Trusted publishing.** Deciding which repo, workflow file and environment get publish rights is a security decision. Running `npm trust github` with those exact values is mechanical.
- **CI failures.** Haiku can watch the run and report the conclusion and the failing job's name. Reading the log to find out why is debugging, so it comes back to you.
- **Retries.** One retry of a clear network timeout is in every brief. Anything beyond that, including a rate limit or an auth error, comes back to you.

## Signs a step isn't mechanical yet

- The brief needs words like "appropriate", "suitable", "if needed", "fix", "clean up" or "make sure it works".
- You couldn't write the Expect line for a step, because you don't know what success looks like.
- The step only works if something earlier in it turns out a particular way, and you haven't checked which way.
- Getting it wrong would need a force-push, an unpublish or a deleted repo to undo.
