#!/usr/bin/env python3
"""Repository self-check: the mechanical part of this repo's own standard.

Verifies what a reviewer should never have to re-derive by hand: every link
and anchor resolves, the plugin manifests parse, the phase structure is
intact, and the one mermaid block is well-formed.

The term denylist (check.sh) is deliberately NOT run here — its term list is
untracked by design, and scanning with placeholder terms would be theater.
That gate is the maintainer's, run locally before every push.
"""

import glob
import json
import os
import re
import sys

failures = []


def fail(msg):
    failures.append(msg)


# --- plugin manifests parse ---------------------------------------------
for p in (".claude-plugin/plugin.json", ".claude-plugin/marketplace.json"):
    try:
        json.load(open(p))
    except Exception as e:  # noqa: BLE001 - report every parse problem the same way
        fail(f"{p}: does not parse ({e})")

# --- links and anchors resolve ------------------------------------------
md_files = [f for pat in ("*.md", "*/*.md", "*/*/*.md") for f in glob.glob(pat)]


def github_anchor(heading):
    s = re.sub(r"[^\w\s-]", "", heading.strip().lower())
    return re.sub(r"\s+", "-", s).strip("-")


for f in sorted(md_files):
    txt = open(f).read()
    anchors = {github_anchor(h) for h in re.findall(r"^#{1,4} (.+)$", txt, re.M)}
    for a in re.findall(r"\]\(#([^)]+)\)", txt):
        if a not in anchors:
            fail(f"{f}: broken anchor #{a}")
    for link in re.findall(r"\]\((?!http)([^)#]+)\)", txt):
        target = os.path.normpath(os.path.join(os.path.dirname(f), link))
        if not os.path.exists(target):
            fail(f"{f}: broken link {link}")

# --- phase structure intact ---------------------------------------------
protocol = open("AUDIT_PROTOCOL.md").read()
if len(re.findall(r"^## 54\. ", protocol, re.M)) != 1:
    fail("AUDIT_PROTOCOL.md: phase 54 missing or duplicated")
if re.search(r"^## 55\. ", protocol, re.M):
    fail("AUDIT_PROTOCOL.md: a phase beyond 54 exists but the docs say 54")

# --- mermaid well-formed -------------------------------------------------
for f in sorted(md_files):
    for block in re.findall(r"```mermaid\n(.*?)```", open(f).read(), re.S):
        first = block.strip().split("\n")[0]
        if not first.startswith(("flowchart", "graph")):
            fail(f"{f}: mermaid block with unknown type: {first!r}")
        if block.count('"') % 2:
            fail(f"{f}: mermaid block has unbalanced quotes")

# -------------------------------------------------------------------------
if failures:
    print(f"verify: {len(failures)} problem(s)")
    for m in failures:
        print(f"  {m}")
    sys.exit(1)

print(f"verify: OK — {len(md_files)} markdown files, manifests, phases, mermaid")
