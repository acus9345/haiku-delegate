# Changelog

## 2.3.1

- Collapse runs of spaces and dashes into a single dash (`Hello   World` and `Rock - Paper` no longer give `---`) (#41).

## 2.3.0

- Strip accents before slugifying (`Crème` → `creme`).

## 2.2.0

- Accept non-string input by converting it with `String()`.
