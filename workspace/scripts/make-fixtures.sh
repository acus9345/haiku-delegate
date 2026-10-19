#!/usr/bin/env bash
# Builds the dry-run fixtures for haiku-delegate. Local only: no network, no global git config.
set -euo pipefail

WS="$(cd "$(dirname "$0")/.." && pwd)"
FX="$WS/fixtures"
G() { git -c user.name="Fixture Bot" -c user.email="fixture@example.invalid" -c init.defaultBranch=main "$@"; }

rm -rf "$FX"
mkdir -p "$FX/eval1-quillkit" "$FX/eval2-slug"

# ---------- eval 1: three built packages ----------
make_pkg() {
  local short="$1" version="$2" bin="$3" deps="$4" prev="$5"
  local dir="$FX/eval1-quillkit/$short"
  mkdir -p "$dir/dist" "$dir/src" "$dir/.github/workflows"
  cat > "$dir/package.json" <<EOF
{
  "name": "@quillkit/$short",
  "version": "$version",
  "description": "quillkit $short",
  "license": "MIT",
  "main": "dist/index.js",
  "bin": { "$bin": "dist/cli.js" },
  "files": ["dist"],
  "repository": { "type": "git", "url": "git+https://github.com/quillkit/$short.git" },
  "publishConfig": { "access": "public" },
  "scripts": { "build": "node scripts/build.js", "test": "node --test" }$deps
}
EOF
  cat > "$dir/src/index.js" <<EOF
module.exports = { name: '@quillkit/$short' };
EOF
  cp "$dir/src/index.js" "$dir/dist/index.js"
  cat > "$dir/dist/cli.js" <<EOF
#!/usr/bin/env node
if (process.argv.includes('--version')) { console.log(require('../package.json').version); process.exit(0); }
console.log('$bin: nothing to do');
EOF
  printf 'node_modules/\ndist/\n' > "$dir/.gitignore"
  printf '# @quillkit/%s\n\nPart of quillkit.\n' "$short" > "$dir/README.md"
  cat > "$dir/.github/workflows/release.yml" <<'EOF'
name: release
on:
  push:
    tags: ['v*']
permissions:
  contents: read
  id-token: write
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 24, registry-url: 'https://registry.npmjs.org' }
      - run: npm ci && npm run build && npm publish --provenance
EOF
  mkdir -p "$dir/scripts"
  cat > "$dir/scripts/build.js" <<'EOF'
const fs = require('fs');
fs.mkdirSync('dist', { recursive: true });
fs.copyFileSync('src/index.js', 'dist/index.js');
EOF
  cd "$dir"
  G init -q
  G remote add origin "https://github.com/quillkit/$short.git"
  # history: previous release (tagged), then the bump to the current version
  sed -i "s/\"version\": \"$version\"/\"version\": \"$prev\"/" package.json
  G add -A && G commit -qm "release: v$prev" && G tag -a "v$prev" -m "v$prev"
  sed -i "s/\"version\": \"$prev\"/\"version\": \"$version\"/" package.json
  G add -A && G commit -qm "chore: bump to $version"
  cd - >/dev/null
}

make_pkg fmt  1.2.0 quill-fmt  "" 1.1.0
make_pkg lint 1.2.0 quill-lint "" 1.1.0
make_pkg cli  0.9.1 quill ',
  "dependencies": { "@quillkit/fmt": "^1.2.0", "@quillkit/lint": "^1.2.0" }' 0.9.0

# ---------- eval 2: a package with a bug ----------
S="$FX/eval2-slug/slug"
mkdir -p "$S/src" "$S/test" "$S/.github/workflows"
cat > "$S/package.json" <<'EOF'
{
  "name": "@quillkit/slug",
  "version": "2.3.0",
  "description": "Turn any string into a URL slug",
  "license": "MIT",
  "main": "src/index.js",
  "files": ["src"],
  "repository": { "type": "git", "url": "git+https://github.com/quillkit/slug.git" },
  "publishConfig": { "access": "public" },
  "scripts": { "test": "node --test" }
}
EOF
cat > "$S/src/index.js" <<'EOF'
'use strict';

/**
 * Turn a string into a lowercase, dash-separated URL slug.
 * @param {string} input
 * @returns {string}
 */
function slugify(input) {
  return String(input)
    .normalize('NFKD')
    .replace(/[̀-ͯ]/g, '')
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '')
    .replace(/\s/g, '-');
}

module.exports = { slugify };
EOF
cat > "$S/test/slugify.test.js" <<'EOF'
'use strict';
const test = require('node:test');
const assert = require('node:assert');
const { slugify } = require('../src/index.js');

test('lowercases and dashes words', () => {
  assert.strictEqual(slugify('Hello World'), 'hello-world');
});

test('strips punctuation', () => {
  assert.strictEqual(slugify('Hello, World!'), 'hello-world');
});

test('removes accents', () => {
  assert.strictEqual(slugify('Crème Brûlée'), 'creme-brulee');
});
EOF
cat > "$S/BUG.md" <<'EOF'
# Issue #41: repeated spaces turn into repeated dashes

Reported by a user:

    slugify('Hello   World')     // 'hello---world', expected 'hello-world'
    slugify('Rock - Paper')      // 'rock---paper',  expected 'rock-paper'

Anything that produces more than one separator in a row should collapse to a
single dash.
EOF
cat > "$S/CHANGELOG.md" <<'EOF'
# Changelog

## 2.3.0

- Strip accents before slugifying (`Crème` → `creme`).

## 2.2.0

- Accept non-string input by converting it with `String()`.
EOF
cat > "$S/RELEASING.md" <<'EOF'
# Releasing

1. Bump `version` in package.json (patch for fixes, minor for features).
2. Add a section for the new version at the top of CHANGELOG.md.
3. Commit as `chore(release): vX.Y.Z`.
4. Create an annotated tag `vX.Y.Z` with message `vX.Y.Z`.
5. Push `main`, then push the tag.
6. The `release` workflow publishes to npm with trusted publishing when a
   `v*` tag is pushed. Do not run `npm publish` by hand.
7. Check that the new version is on npm and installs cleanly.
EOF
cat > "$S/.github/workflows/release.yml" <<'EOF'
name: release
on:
  push:
    tags: ['v*']
permissions:
  contents: read
  id-token: write
jobs:
  publish:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: 24, registry-url: 'https://registry.npmjs.org' }
      - run: npm test
      - run: npm publish --provenance
EOF
printf 'node_modules/\n' > "$S/.gitignore"
cd "$S"
G init -q
G remote add origin "https://github.com/quillkit/slug.git"
G add -A && G commit -qm "chore(release): v2.3.0" && G tag -a v2.3.0 -m "v2.3.0"
cd - >/dev/null

echo "fixtures ready:"
find "$FX" -path '*/.git' -prune -o -type f -print | sed "s|$FX/||" | sort
