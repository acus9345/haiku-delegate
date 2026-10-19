# Releasing

1. Bump `version` in package.json (patch for fixes, minor for features).
2. Add a section for the new version at the top of CHANGELOG.md.
3. Commit as `chore(release): vX.Y.Z`.
4. Create an annotated tag `vX.Y.Z` with message `vX.Y.Z`.
5. Push `main`, then push the tag.
6. The `release` workflow publishes to npm with trusted publishing when a
   `v*` tag is pushed. Do not run `npm publish` by hand.
7. Check that the new version is on npm and installs cleanly.
