# Task: Publish @quillkit/fmt 1.2.0, push tag v1.2.0, check a clean install
## Goal
@quillkit/fmt 1.2.0 is on npm as public, annotated tag v1.2.0 on commit 2b3e01e55ff7982bffad3799019a2c6d48afe426 is on github.com/quillkit/fmt, and a clean registry install prints 1.2.0 from `quill-fmt --version`.
## Inputs
- Shell: Bash
- Working directory: "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-3/publish-3-packages/with_skill/repos/fmt"
- HEAD commit: 2b3e01e55ff7982bffad3799019a2c6d48afe426
- Tag object (v1.2.0): 811a8ab4449f777b5dffade98a29a27bcd59cbfb
- Install folder: "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0" (step 9 creates it)
- `dist/` is gitignored and already built. Never rebuild it.
- Pushing the tag starts the `release` workflow on GitHub, which is expected to fail. Don't look at it.
## Steps
1. `git status --porcelain && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD`
   Expect: no status lines, `main`, `2b3e01e55ff7982bffad3799019a2c6d48afe426`.
2. `node -p "const p=require('./package.json'); p.name+'@'+p.version"`
   Expect: `@quillkit/fmt@1.2.0`
3. `git cat-file -t v1.2.0 && git rev-parse v1.2.0 "v1.2.0^{commit}"`
   Expect: `tag`, `811a8ab4449f777b5dffade98a29a27bcd59cbfb`, `2b3e01e55ff7982bffad3799019a2c6d48afe426`.
4. `git ls-remote origin refs/heads/main refs/tags/v1.2.0`
   Expect: exactly one line, `2b3e01e55ff7982bffad3799019a2c6d48afe426	refs/heads/main`. A `refs/tags/v1.2.0` line, or a different main SHA: stop, publish nothing.
5. `npm pack --dry-run --json --ignore-scripts`
   Expect: a line containing `"integrity": "sha512-9r5xUhT4VONCA70UzaeFPIveEoTO9Rx/bC+A3HauzTE+bzHub3hdcMweDEziyDtkVt8Jj6uOH2tyE8piHJr1RQ=="` and a line containing `"entryCount": 4`. If either differs, stop.
6. `npm view @quillkit/fmt@1.2.0 version --prefer-online`
   Expect: E404 ("No match found" or "Not Found"), or no output with exit 0. If it prints `1.2.0`, report all three items `skipped` ("already on npm") and stop.
7. `npm publish --access public`
   Expect: exit 0 and a line `+ @quillkit/fmt@1.2.0`.
8. `git push origin refs/tags/v1.2.0`
   Expect: exit 0 and a line with `[new tag]` and `v1.2.0 -> v1.2.0`.
9. `cd /c && test ! -e "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0" && mkdir -p "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0"`
   Expect: exit 0. If the folder exists, stop.
10. `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0" && npm view @quillkit/fmt@1.2.0 version --prefer-online`
    Expect: `1.2.0`. E404 or no output is expected at first: run the same command again, up to 10 runs in total, then stop with `1.2.0 not visible on registry`.
11. `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0" && npm init -y && npm install --no-audit --no-fund --prefer-online @quillkit/fmt@1.2.0`
    Expect: exit 0 and `added N packages`. ETARGET or E404: stop, don't retry.
12. `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-fmt-1.2.0" && ./node_modules/.bin/quill-fmt --version && node -p "require('@quillkit/fmt').name"`
    Expect: exactly `1.2.0`, then `@quillkit/fmt`. Quote both lines in evidence.
## Do not
- Push anything but `refs/tags/v1.2.0`, or create or change tags or commits.
- Run `npm run build`, `npm install` or `npm ci` in the working directory, `npm version`, or `npm pack` without `--dry-run`.
- Add `--provenance`, `--tag` or `--otp` to `npm publish`.
- Look at, rerun or cancel GitHub Actions runs.
- In the install folder: use `-g`, `npm link`, or a local path or tarball.
## Report items
`npm publish @quillkit/fmt@1.2.0` (steps 1–7), `push tag v1.2.0` (step 8), `install @quillkit/fmt@1.2.0` (steps 9–12)
