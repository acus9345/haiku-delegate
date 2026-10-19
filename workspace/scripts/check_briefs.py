"""Structural checks on haiku-delegate dry-run outputs. Usage: python -I check_briefs.py <run_outputs_dir> <eval_name>"""
import pathlib
import re
import sys

SECTIONS = ["## Goal", "## Inputs", "## Steps", "## Do not", "## Stop conditions", "## Report"]
ABBREV = re.compile(r"same as (the )?template|verbatim from the template|<template|\(template", re.I)
VAGUE = re.compile(r"\b(appropriate|suitable|if needed|as needed|clean up|make sure it works)\b", re.I)

out = pathlib.Path(sys.argv[1])
eval_name = sys.argv[2]
briefs = sorted((out / "briefs").glob("*.md"))
print(f"{len(briefs)} briefs in {out / 'briefs'}")
problems = 0
for b in briefs:
    text = b.read_text(encoding="utf-8")
    missing = [s for s in SECTIONS if s not in text]
    issues = []
    if missing:
        issues.append(f"missing sections: {missing}")
    if ABBREV.search(text):
        issues.append("abbreviated template section")
    for m in VAGUE.finditer(text):
        line = text[: m.start()].count("\n") + 1
        issues.append(f"vague word '{m.group(0)}' at line {line}")
    if "NEEDS_USER" not in text:
        issues.append("no NEEDS_USER stop condition")
    if eval_name == "fix-bug-and-release" and re.search(r"^\s*\d+\.\s.*npm publish", text, re.M):
        issues.append("runs npm publish by hand")
    if eval_name == "fix-bug-and-release" and re.search(r"slugify\s*\(|replace\(/", text) and "src/index.js" in text and "edit" in text.lower():
        issues.append("brief may contain code-editing work")
    problems += bool(issues)
    print(f"- {b.name}: {'OK' if not issues else '; '.join(issues)}")

plan = out / "plan.md"
print(f"plan.md: {'present' if plan.exists() else 'MISSING'}; skill-feedback.md: {'present' if (out / 'skill-feedback.md').exists() else 'MISSING'}")
if plan.exists():
    p = plan.read_text(encoding="utf-8")
    print("  mentions model haiku:", '"haiku"' in p or "model: haiku" in p or "`haiku`" in p)
    print("  mentions run_in_background:", "run_in_background" in p)
print(f"briefs with issues: {problems}")
