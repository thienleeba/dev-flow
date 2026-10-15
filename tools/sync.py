#!/usr/bin/env python3
"""Regenerate every per-tool file from the single sources in skills/.
Run after editing a skill:  python3 tools/sync.py
"""
import json, pathlib, re

ROOT = pathlib.Path(__file__).resolve().parent.parent
VERSION = json.loads((ROOT / ".claude-plugin/plugin.json").read_text())["version"]
NAME, DESC = "dev", "DevFlow — your dev routine in a few commands: morning check, plan and run the day with your project's own workflows, daily report"
AUTHOR = {"name": "thienleeba"}
LICENSE = "MIT"


def front(text):
    m = re.match(r"---\n(.*?)\n---\n(.*)", text, re.S)
    meta = {}
    for line in m.group(1).splitlines():
        k, _, v = line.partition(":")
        meta[k.strip()] = v.strip().strip('"')
    return meta, m.group(2).strip() + "\n"


def write(rel, content):
    p = ROOT / rel
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content)
    print("  wrote", rel)


skills = sorted(d.name for d in (ROOT / "skills").iterdir() if (d / "SKILL.md").exists())

# Manifests (Claude's .claude-plugin/ files are the hand-edited originals)
manifest = {"name": NAME, "version": VERSION, "description": DESC, "author": AUTHOR, "license": LICENSE,
            "keywords": ["workflow", "github", "daily-routine", "planning", "standup"]}
write("plugin.json", json.dumps(manifest, indent=2) + "\n")                      # Codex + GitHub Copilot
write(".cursor-plugin/plugin.json", json.dumps(manifest, indent=2) + "\n")       # Cursor
write(".cursor-plugin/marketplace.json", (ROOT / ".claude-plugin/marketplace.json").read_text())
write("gemini-extension.json", json.dumps({"name": NAME, "version": VERSION, "description": DESC}, indent=2) + "\n")

# Gemini: skills are auto-activated only, so explicit /dev:<name> needs a command file
for old in (ROOT / "commands/dev").glob("*.toml"):
    if old.stem not in skills:
        old.unlink(); print("  removed", old.relative_to(ROOT))
for s in skills:
    meta, _ = front((ROOT / f"skills/{s}/SKILL.md").read_text())
    write(f"commands/dev/{s}.toml",
          f'description = "{meta["description"]}"\n'
          f'prompt = """\nActivate the `{s}` skill of the DevFlow extension and follow it exactly, step by step.\n\nArguments: {{{{args}}}}\n"""\n')
