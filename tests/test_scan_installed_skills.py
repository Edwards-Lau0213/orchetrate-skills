import importlib.util
import json
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[1]
SCRIPT_PATH = REPO_ROOT / "skills" / "orchestrate-skills" / "scripts" / "scan_installed_skills.py"


def load_scanner():
    spec = importlib.util.spec_from_file_location("scan_installed_skills", SCRIPT_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


def write_skill(root: Path, relative_dir: str, name: str, description: str = "") -> None:
    skill_dir = root / relative_dir
    skill_dir.mkdir(parents=True, exist_ok=True)
    skill_dir.joinpath("SKILL.md").write_text(
        f"---\nname: {name}\ndescription: {description}\n---\n\n# {name}\n",
        encoding="utf-8",
    )


class ScanInstalledSkillsTest(unittest.TestCase):
    def test_scan_excludes_system_by_default(self):
        scanner = load_scanner()
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_skill(root, "paper-writing", "paper-writing", "Write a paper.")
            write_skill(root, ".system/skill-creator", "skill-creator", "Create skills.")

            default_entries = scanner.scan(root, include_system=False, query="", aliases={})
            included_entries = scanner.scan(root, include_system=True, query="", aliases={})

        self.assertEqual([entry.name for entry in default_entries], ["paper-writing"])
        self.assertEqual({entry.name for entry in included_entries}, {"paper-writing", "skill-creator"})

    def test_alias_boosts_score_and_records_reason(self):
        scanner = load_scanner()
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            write_skill(root, "paper-writing", "paper-writing", "Full paper workflow.")
            write_skill(root, "pdf", "pdf", "Work with PDFs.")
            aliases = {"写论文": {"paper-writing": 10}}

            entries = scanner.scan(root, include_system=False, query="帮我写论文", aliases=aliases)

        self.assertEqual(entries[0].name, "paper-writing")
        self.assertIn("alias:写论文+10", entries[0].reason)

    def test_cli_json_output_contains_reason(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp) / "skills"
            aliases_path = Path(tmp) / "aliases.json"
            write_skill(root, "patent-pipeline", "patent-pipeline", "Draft patent applications.")
            aliases_path.write_text(json.dumps({"专利": {"patent-pipeline": 8}}, ensure_ascii=False), encoding="utf-8")

            result = subprocess.run(
                [
                    sys.executable,
                    str(SCRIPT_PATH),
                    "--root",
                    str(root),
                    "--query",
                    "帮我写专利",
                    "--aliases",
                    str(aliases_path),
                    "--format",
                    "json",
                    "--top",
                    "1",
                ],
                check=True,
                capture_output=True,
                text=True,
                encoding="utf-8",
            )

        data = json.loads(result.stdout)
        self.assertEqual(data[0]["name"], "patent-pipeline")
        self.assertEqual(data[0]["score"], 8)
        self.assertEqual(data[0]["reason"], ["alias:专利+8"])

    def test_filter_entries_removes_zero_score_by_default(self):
        scanner = load_scanner()
        entries = [
            scanner.SkillEntry(name="matched", description="", path="matched/SKILL.md", source="Codex installed", score=1),
            scanner.SkillEntry(name="unmatched", description="", path="unmatched/SKILL.md", source="Codex installed", score=0),
        ]

        filtered = scanner.filter_entries(entries, include_zero=False, minimum_score=1)
        unfiltered = scanner.filter_entries(entries, include_zero=True, minimum_score=1)

        self.assertEqual([entry.name for entry in filtered], ["matched"])
        self.assertEqual([entry.name for entry in unfiltered], ["matched", "unmatched"])

    def test_generic_description_tokens_are_downweighted(self):
        scanner = load_scanner()
        entry = scanner.SkillEntry(
            name="meta-optimize",
            description="Analyze skills and workflow defaults.",
            path="meta-optimize/SKILL.md",
            source="Codex installed",
        )

        score, reasons = scanner.score_entry(entry, query="skills", aliases={})

        self.assertEqual(score, 1)
        self.assertEqual(reasons, ["description-generic:skills"])


if __name__ == "__main__":
    unittest.main()
