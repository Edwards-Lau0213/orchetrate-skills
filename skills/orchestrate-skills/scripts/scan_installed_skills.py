#!/usr/bin/env python3
"""Scan installed Codex skills using only SKILL.md frontmatter."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from dataclasses import asdict, dataclass, field
from pathlib import Path


@dataclass
class SkillEntry:
    name: str
    description: str
    path: str
    source: str
    score: int = 0
    reason: list[str] = field(default_factory=list)


GENERIC_DESCRIPTION_TOKENS = {
    "skill",
    "skills",
    "task",
    "tasks",
    "use",
    "when",
    "user",
    "users",
    "codex",
    "agent",
    "agents",
}


def read_frontmatter(path: Path) -> str:
    lines: list[str] = []
    try:
        with path.open("r", encoding="utf-8") as handle:
            first = handle.readline()
            if first.strip() != "---":
                return ""
            for line in handle:
                if line.strip() == "---":
                    break
                lines.append(line)
    except UnicodeDecodeError:
        with path.open("r", encoding="utf-8-sig", errors="replace") as handle:
            text = handle.read()
        match = re.match(r"\A---\s*(.*?)\s*---", text, re.S)
        return match.group(1) if match else ""
    return "".join(lines)


def frontmatter_value(frontmatter: str, key: str) -> str:
    pattern = rf"(?ms)^{re.escape(key)}\s*:\s*(.*?)(?=^\w[\w-]*\s*:|\Z)"
    match = re.search(pattern, frontmatter)
    if not match:
        return ""
    value = match.group(1).strip()
    value = re.sub(r"^\|[-+]?\s*", "", value)
    value = re.sub(r"^>[-+]?\s*", "", value)
    value = re.sub(r"\s+", " ", value)
    return value.strip(" \t\r\n\"'")


def tokenize(text: str) -> list[str]:
    return [token for token in re.split(r"[^a-zA-Z0-9_\-\u4e00-\u9fff]+", text.lower()) if len(token) >= 2]


def default_alias_path() -> Path:
    return Path(__file__).resolve().parents[1] / "references" / "routing-aliases.json"


def load_aliases(path: Path) -> dict[str, dict[str, int]]:
    if not path.exists():
        return {}
    with path.open("r", encoding="utf-8") as handle:
        raw = json.load(handle)
    aliases: dict[str, dict[str, int]] = {}
    for alias, boosts in raw.items():
        if not isinstance(alias, str) or not isinstance(boosts, dict):
            continue
        aliases[alias.lower()] = {
            str(skill_name): int(weight)
            for skill_name, weight in boosts.items()
            if isinstance(weight, int | float)
        }
    return aliases


def score_entry(entry: SkillEntry, query: str, aliases: dict[str, dict[str, int]]) -> tuple[int, list[str]]:
    if not query.strip():
        return 0, []
    name = entry.name.lower()
    description = entry.description.lower()
    score = 0
    reasons: list[str] = []
    for token in tokenize(query):
        if token in name:
            score += 4
            reasons.append(f"name:{token}")
        if token in description:
            if token in GENERIC_DESCRIPTION_TOKENS:
                score += 1
                reasons.append(f"description-generic:{token}")
            else:
                score += 2
                reasons.append(f"description:{token}")
        if token.replace("-", "") in name.replace("-", ""):
            score += 1
            reasons.append(f"name-normalized:{token}")
    query_lower = query.lower()
    for alias, boosts in aliases.items():
        if alias in query_lower:
            boost = boosts.get(entry.name, 0)
            if boost:
                score += boost
                reasons.append(f"alias:{alias}+{boost}")
    return score, reasons


def filter_entries(entries: list[SkillEntry], include_zero: bool, minimum_score: int) -> list[SkillEntry]:
    if include_zero:
        return entries
    return [entry for entry in entries if entry.score >= minimum_score]


def scan(root: Path, include_system: bool, query: str, aliases: dict[str, dict[str, int]] | None = None) -> list[SkillEntry]:
    aliases = aliases or {}
    entries: list[SkillEntry] = []
    for current, _dirs, files in os.walk(root, topdown=True, onerror=lambda _error: None, followlinks=False):
        if "SKILL.md" not in files:
            continue
        skill_md = Path(current) / "SKILL.md"
        rel = skill_md.relative_to(root)
        is_system = rel.parts and rel.parts[0] == ".system"
        if is_system and not include_system:
            continue
        frontmatter = read_frontmatter(skill_md)
        name = frontmatter_value(frontmatter, "name") or skill_md.parent.name
        description = frontmatter_value(frontmatter, "description")
        entry = SkillEntry(
            name=name,
            description=description,
            path=str(rel),
            source="Codex system" if is_system else "Codex installed",
        )
        entry.score, entry.reason = score_entry(entry, query, aliases)
        entries.append(entry)
    entries.sort(key=lambda item: (-item.score, item.name, item.path))
    return entries


def write_cache(entries: list[SkillEntry], path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps([asdict(entry) for entry in entries], ensure_ascii=False, indent=2), encoding="utf-8")


def print_markdown(entries: list[SkillEntry]) -> None:
    print("| score | name | source | path | reason | description |")
    print("|---:|---|---|---|---|---|")
    for entry in entries:
        description = re.sub(r"\s+", " ", entry.description)
        if len(description) > 180:
            description = description[:177] + "..."
        description = description.replace("|", "\\|")
        reason = ", ".join(entry.reason[:5]).replace("|", "\\|")
        print(f"| {entry.score} | `{entry.name}` | {entry.source} | `{entry.path}` | {reason} | {description} |")


def main() -> int:
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8")
    parser = argparse.ArgumentParser(description="Scan installed Codex skills from frontmatter only.")
    parser.add_argument("--root", default=str(Path.home() / ".codex" / "skills"))
    parser.add_argument("--query", default="")
    parser.add_argument("--top", type=int, default=25)
    parser.add_argument("--include-system", action="store_true")
    parser.add_argument("--format", choices=["json", "markdown"], default="markdown")
    parser.add_argument("--write-cache", default="")
    parser.add_argument("--aliases", default=str(default_alias_path()))
    parser.add_argument("--include-zero", action="store_true")
    parser.add_argument("--min-score", type=int, default=1)
    args = parser.parse_args()

    aliases = load_aliases(Path(args.aliases).expanduser())
    entries = scan(Path(args.root).expanduser(), args.include_system, args.query, aliases)
    if args.write_cache:
        write_cache(entries, Path(args.write_cache).expanduser())

    filtered = filter_entries(entries, include_zero=args.include_zero, minimum_score=args.min_score)
    shown = filtered[: args.top] if args.top > 0 else filtered
    if args.format == "json":
        print(json.dumps([asdict(entry) for entry in shown], ensure_ascii=False, indent=2))
    else:
        print_markdown(shown)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
