# Task: Publish @quillkit/cli 0.9.1, push tag v0.9.1, check a clean install
## Goal
@quillkit/cli 0.9.1 is on npm as public, annotated tag v0.9.1 on commit a0be7c1311866d1f1ca2372a950fad462e50852f is on github.com/quillkit/cli, and a clean registry install prints 0.9.1 from `quill --version` with @quillkit/fmt 1.2.0 and @quillkit/lint 1.2.0 installed under it.
## Inputs
- Shell: Bash
- Working directory: "/c/Users/User/github repo/skills/haiku-delegate-workspace/iteration-3/publish-3-packages/with_skill/repos/cli"
- HEAD commit: a0be7c1311866d1f1ca2372a950fad462e50852f
- Tag object (v0.9.1): d55b0414578ac959d0e5943409df014306a9b866
- Install folder: "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-cli-0.9.1" (step 9 creates it)
- Its dependencies @quillkit/fmt 1.2.0 and @quillkit/lint 1.2.0 are already on npm.
- `dist/` is gitignored and already built. Never rebuild it.
- Pushing the tag starts the `release` workflow on GitHub, which is expected to fail. Don't look at it.
## Steps
1. `git status --porcelain && git rev-parse --abbrev-ref HEAD && git rev-parse HEAD`
   Expect: no status lines, `main`, `a0be7c1311866d1f1ca2372a950fad462e50852f`.
2. `node -p "const p=require('./package.json'); p.name+'@'+p.version"`
   Expect: `@quillkit/cli@0.9.1`
3. `git cat-file -t v0.9.1 && git rev-parse v0.9.1 "v0.9.1^{commit}"`
   Expect: `tag`, `d55b0414578ac959d0e5943409df014306a9b866`, `a0be7c1311866d1f1ca2372a950fad462e50852f`.
4. `git ls-remote origin refs/heads/main refs/tags/v0.9.1`
   Expect: exactly one line, `a0be7c1311866d1f1ca2372a950fad462e50852f	refs/heads/main`. A `refs/tags/v0.9.1` line, or a different main SHA: stop, publish nothing.
5. `npm pack --dry-run --json --ignore-scripts`
   Expect: a line containing `"integrity": "sha512-pMvMeedBrUrd81HYh0AfIoE65w5mlZhxR/zMHeqZQbJ/oIjjWNyX2wPf10QgsWSPCRtdY0VHpxO0SMAbpLx4zA=="` and a line containing `"entryCount": 4`. If either differs, stop.
6. `npm view @quillkit/cli@0.9.1 version --prefer-online`
   Expect: E404 ("No match found" or "Not Found"), or no output with exit 0. If it prints `0.9.1`, report all three items `skipped` ("already on npm") and stop.
7. `npm publish --access public`
   Expect: exit 0 and a line `+ @quillkit/cli@0.9.1`.
8. `git push origin refs/tags/v0.9.1`
   Expect: exit 0 and a line with `[new tag]` and `v0.9.1 -> v0.9.1`.
9. `cd /c && test ! -e "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-cli-0.9.1" && mkdir -p "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-cli-0.9.1"`
   Expect: exit 0. If the folder exists, stop.
10. `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-cli-0.9.1" && npm view @quillkit/cli@0.9.1 version --prefer-online`
    Expect: `0.9.1`. E404 or no output is expected at first: run the same command again, up to 10 runs in total, then stop with `0.9.1 not visible on registry`.
11. `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-cli-0.9.1" && npm init -y && npm install --no-audit --no-fund --prefer-online @quillkit/cli@0.9.1`
    Expect: exit 0 and `added N packages`. ETARGET or E404: stop, don't retry.
12. `cd "/c/Users/User/AppData/Local/Temp/haiku-verify/quillkit-cli-0.9.1" && ./node_modules/.bin/quill --version && npm ls @quillkit/fmt @quillkit/lint`
    Expect: exactly `0.9.1`, then a tree with a line containing `@quillkit/fmt@1.2.0` and a line containing `@quillkit/lint@1.2.0`. Quote the version line and both tree lines in evidence.
## Do not
- Push anything but `refs/tags/v0.9.1`, or create or change tags or commits.
- Run `npm run build`, `npm install` or `npm ci` in the working directory, `npm version`, or `npm pack` without `--dry-run`.
- Add `--provenance`, `--tag` or `--otp` to `npm publish`.
- Look at, rerun or cancel GitHub Actions runs.
- In the install folder: use `-g`, `npm link`, or a local path or tarball.
## Report items
`npm publish @quillkit/cli@0.9.1` (steps 1–7), `push tag v0.9.1` (step 8), `install @quillkit/cli@0.9.1` (steps 9–12)
