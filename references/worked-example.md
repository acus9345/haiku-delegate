# Worked example: publishing 5 npm packages

The user opted in earlier ("use haiku for the mechanical parts"). Now they ask: "create repos for the five @acme packages in `packages/`, publish them as public, tag them, set up trusted publishing for `release.yml`, and check the installs."

The packages are core, utils, http, test-kit and cli, all at 1.0.0 and built. cli depends on core and utils.

**Main model first.** Read each `package.json`, confirm `dist/` exists, and confirm each name is free (E404). The request names every outward action, so it approves them for these five packages. `release.yml` runs on `v*` tags. When the tags are pushed, 1.0.0 is already on npm and trusted publishing isn't set up yet, so each tag push leaves one failed run. That's harmless: mention it once at launch, and the briefs say to leave the runs alone.

**Task list:**

```
[main]  Preflight: fields, dist/, names free, what tag pushes trigger
[haiku] npm pack --dry-run + secret scan, all 5 (1 agent)          gate: preflight
[main]  Review file lists and scan findings
[haiku] Create 5 repos + push main (1 agent, sequential)           gate: review
[main]  Tag v1.0.0 locally in each repo on the pushed SHA          gate: repos verified
[haiku] Publish + tag + install check: core, utils, http, test-kit (4 agents)  gate: tags made
[haiku] Publish + tag + install check: cli                       gate: core + utils verified
[haiku] Trusted publishing, all 5 (1 agent, sequential)            gate: all 5 verified
[main]  Verify + wrap-up table
```

Repo creation goes to one agent because GitHub throttles bursts of new repos. With only 2 or 3 small packages, run the pack check yourself.

**Publishing.** Four briefs like Example 1 launch in one message and fill all four slots. As each report arrives, verify it with `npm view … version --prefer-online`, `dist.integrity`, the tag ref and the tag's commit, and read the quoted install output. Once core and utils check out, cli takes a free slot.

**A failure.** The http agent reports:

```
ITEM: npm publish @acme/http@1.0.0
STATUS: failed
STEP: 7
EVIDENCE: exit code 1
ERROR: npm error code E402
npm error 402 Payment Required - PUT https://registry.npmjs.org/@acme%2fhttp - You must sign up for private packages
```

Its tag and install items come back `skipped`. You diagnose it: there's no `publishConfig.access` and no `--access public`, and the user asked for public packages. So you send a corrected brief that starts at the publish step. An E403 or E429 would instead go to the user.

If the repo agent had hit "created too many repositories" after 3 repos, you'd launch nothing else that talks to GitHub (the publish briefs push tags), tell the user 3 of 5 exist, and wait for their go-ahead.

**Trusted publishing.** One agent runs `npm trust github <pkg> --file release.yml --repo acme/<name> --allow-publish --yes` for each package in turn. On `NEEDS_USER`, give the user the remaining commands and verify with `npm trust list`.

**Wrap-up:**

| Item | Result | Evidence |
|---|---|---|
| @acme/core 1.0.0 | repo, published, tagged, install ok, trusted publishing | [npm](https://www.npmjs.com/package/@acme/core/v/1.0.0) · [v1.0.0](https://github.com/acme/core/tree/v1.0.0) |
| @acme/http 1.0.0 | published on the 2nd try (`--access public`), tagged, install ok, trusted publishing | [npm](https://www.npmjs.com/package/@acme/http/v/1.0.0) · [v1.0.0](https://github.com/acme/http/tree/v1.0.0) |

**Left:** nothing. **Needs you:** nothing. Each repo shows one failed `release` run, as flagged at launch.
