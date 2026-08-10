#!/usr/bin/env python3
"""Repository self-check: the mechanical part of this repo's own standard.

Verifies what a reviewer should never have to re-derive by hand: every link
and anchor resolves, the skill can still reach its taxonomy, the plugin
manifests parse and agree, the version moves whenever the plugin's payload
does, the phase structure is intact, and the one mermaid block is well-formed.

The term denylist (check.sh) is deliberately NOT run here — its term list is
untracked by design, and scanning with placeholder terms would be theater.
That gate is the maintainer's, run locally before every push.
"""

import glob
import json
import os
import re
import subprocess
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
    # github-slugger strips this character class and then replaces each space
    # individually, so a removed em dash leaves two spaces behind and produces
    # two hyphens. Collapsing \s+ instead inverted this check for every heading
    # with punctuation between two spaces — it accepted the fragment GitHub
    # answers with a 404 and rejected the one GitHub actually serves. The house
    # style puts an em dash in headings throughout, so that is most of them.
    # Trailing hyphens are kept for the same reason: GitHub keeps them too.
    s = re.sub(r"[^\w\s-]", "", heading.strip().lower())
    return s.replace(" ", "-")


anchors_of = {}
for f in sorted(md_files):
    txt = open(f).read()
    anchors_of[f] = {github_anchor(h) for h in re.findall(r"^#{1,4} (.+)$", txt, re.M)}

for f in sorted(md_files):
    txt = open(f).read()
    # One pattern for every local target, with or without a #fragment, so an
    # anchored link like [x](HOWTO.md#step-2) is validated on both halves
    # rather than skipped entirely.
    for target in re.findall(r"\]\((?!\w+:)([^)\s]+)\)", txt):
        path, _, frag = target.partition("#")
        if path:
            resolved = os.path.normpath(os.path.join(os.path.dirname(f), path))
            if not os.path.exists(resolved):
                fail(f"{f}: broken link {target}")
                continue
        else:
            resolved = f
        if frag and resolved in anchors_of and frag not in anchors_of[resolved]:
            fail(f"{f}: broken anchor {target}")

# --- the skill can still reach its taxonomy -----------------------------
# The skill names two routes to AUDIT_PROTOCOL.md. Three things about them are
# properties of this repository and are checked below. Two are supplied by the
# harness at run time and CANNOT be checked here: whether Claude Code states a
# base directory at all, and whether ${CLAUDE_PLUGIN_ROOT} is expanded. A pass
# means the repository holds up its end of both routes, not that either one
# resolved for any particular agent.
skill = "skills/audit-protocol/SKILL.md"
skill_txt = open(skill).read()

# 1. It names the taxonomy at all. A rewrite that drops the reference entirely
#    leaves an agent auditing from memory, which is what the skill forbids.
if "AUDIT_PROTOCOL.md" not in skill_txt:
    fail(f"{skill}: never names AUDIT_PROTOCOL.md — nothing routes to the taxonomy")

# 2. The two-directory hop the skill promises still lands on the file. This is
#    the static half of the base-directory route: what the base directory IS
#    comes from the harness, but that it sits two levels under the plugin root
#    is this repository's layout, and moving either file breaks the promise
#    silently.
hop = os.path.normpath(os.path.join(os.path.dirname(skill), "..", "..", "AUDIT_PROTOCOL.md"))
if not os.path.exists(hop):
    fail(f"{skill}: the two-directory hop it promises does not reach AUDIT_PROTOCOL.md")

# 3. Every ${CLAUDE_PLUGIN_ROOT}/… path it names exists, for harnesses that do
#    expand the variable.
for rel in re.findall(r"\$\{CLAUDE_PLUGIN_ROOT\}/([^\s`)]+)", skill_txt):
    if not os.path.exists(rel.rstrip("/")):
        fail(f"{skill}: names a plugin path that does not exist: {rel}")

# --- phase structure intact ---------------------------------------------
protocol = open("AUDIT_PROTOCOL.md").read()
# Phase headings live after the index; the front matter reuses "## 1." through
# "## 5." for its own sections, so anchor the search past the index marker.
idx = protocol.find("## Phase index")
phases = [int(n) for n in re.findall(r"^## (\d+)\. ", protocol[idx:], re.M)]
if phases != list(range(1, 55)):
    missing = sorted(set(range(1, 55)) - set(phases))
    dupes = sorted({n for n in phases if phases.count(n) > 1})
    fail(
        f"AUDIT_PROTOCOL.md: phase headings are not exactly 1-54 "
        f"(found {len(phases)}; missing {missing or 'none'}; duplicated {dupes or 'none'})"
    )

# --- the two manifests must not drift apart ---------------------------------
try:
    plug = json.load(open(".claude-plugin/plugin.json"))
    mkt = json.load(open(".claude-plugin/marketplace.json"))
    entry = next((p for p in mkt.get("plugins", []) if p.get("name") == plug.get("name")), None)
    if entry is None:
        fail(f"marketplace.json: no plugins entry named {plug.get('name')!r}")
    elif entry.get("version") != plug.get("version"):
        fail(
            f"version drift: plugin.json {plug.get('version')!r} vs "
            f"marketplace entry {entry.get('version')!r}"
        )
    # The catalog's own version is kept in lockstep with the plugin's by hand and
    # was guarded by nothing, so it was free to go stale while the checked pair
    # stayed honest.
    if mkt.get("metadata", {}).get("version") != plug.get("version"):
        fail(
            f"version drift: plugin.json {plug.get('version')!r} vs "
            f"marketplace metadata {mkt.get('metadata', {}).get('version')!r}"
        )
except Exception as e:  # noqa: BLE001 - a parse failure is already reported above
    fail(f"manifest cross-check skipped: {e}")

# --- the version moves when the plugin's payload moves ----------------------
# Version 1.0.0 survived nine content commits. The plugin cache is keyed on
# version and `claude plugin update` compares versions, so every one of those
# commits was unreachable to anyone who had already installed — the update ran,
# reported success, and changed nothing. This is the check that would have
# caught it.
#
# PAYLOAD is what the skill directs an agent to read. README, CONTRIBUTING and
# SECURITY are copied into the plugin too, but a typo fix in one of them does
# not change how an audit runs, and forcing a release for it would make this
# check noise — and a noisy gate gets disabled.
#
# Everything here is asked of HEAD, not the working tree: an uncommitted bump is
# not yet a claim about anything, and answering for the working tree would make
# the check fail on the very commit that fixes it.
PAYLOAD = ["skills", "AUDIT_PROTOCOL.md", "OVERLAY_TEMPLATE.md", "overlays", "templates"]


def git(*args):
    r = subprocess.run(("git", *args), capture_output=True, text=True)
    return r.returncode, r.stdout.strip()


rc, head_manifest = git("show", "HEAD:.claude-plugin/plugin.json")
rc_shallow, shallow = git("rev-parse", "--is-shallow-repository")
if rc != 0 or rc_shallow != 0:
    fail("version-payload check DID NOT RUN: no git history here, so nothing was verified")
elif shallow != "false":
    # Measured, not assumed: a depth-1 clone does NOT fail the lookup below. Its
    # single commit looks like the one that introduced the current version, the
    # diff from it to HEAD is therefore empty, and the check reports a pass
    # having verified nothing. Shallowness has to be refused by name.
    fail(
        "version-payload check DID NOT RUN: shallow clone. A truncated history cannot say "
        "when the version was last set, and passes vacuously if asked. CI needs "
        "actions/checkout with fetch-depth: 0"
    )
else:
    version = json.loads(head_manifest)["version"]
    rc, hits = git("log", "--format=%H", "-S", f'"version": "{version}"',
                   "--", ".claude-plugin/plugin.json")
    if rc != 0 or not hits:
        fail(
            f"version-payload check DID NOT RUN: no commit in this history sets version "
            f"{version!r} in .claude-plugin/plugin.json"
        )
    else:
        bumped_at = hits.splitlines()[0]
        rc, changed = git("diff", "--name-only", f"{bumped_at}..HEAD", "--", *PAYLOAD)
        if rc != 0:
            fail("version-payload check DID NOT RUN: git diff failed")
        elif changed:
            files = sorted(changed.splitlines())
            shown = ", ".join(files[:4]) + (f", +{len(files) - 4} more" if len(files) > 4 else "")
            fail(
                f"version {version} was set at {bumped_at[:7]} and the plugin payload has "
                f"changed since ({shown}). Bump the version, or an installed copy cannot "
                f"receive this."
            )

# --- the README's badge numbers are claims, so check them ------------------
# Hand-maintained counts on the one file every visitor reads first are pure
# drift surface. Asserting them costs four lines and turns an advertisement
# into a checked statement.
readme = open("README.md").read()
badges = {
    "phases": (
        r"badge/phases-(\d+)-",
        len(set(phases)),
    ),
    "worked overlays": (
        r"badge/worked%20overlays-(\d+)-",
        len(glob.glob("overlays/*.md")),
    ),
}
for label, (pattern, actual) in badges.items():
    m = re.search(pattern, readme)
    if not m:
        fail(f"README.md: the {label} badge is gone, or its URL changed shape")
    elif int(m.group(1)) != actual:
        fail(f"README.md: {label} badge says {m.group(1)}, repository has {actual}")

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

print(f"verify: OK — {len(md_files)} markdown files, manifests, version, phases, mermaid")
