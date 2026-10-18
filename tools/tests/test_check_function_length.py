"""Tests for tools/check_function_length.py, run against throwaway git repositories."""

from __future__ import annotations

import json
import re
import runpy
import subprocess
import sys
from typing import TYPE_CHECKING

import pytest

import check_function_length as checker

if TYPE_CHECKING:
    from pathlib import Path

LIMIT = checker.load_config().limit
SCRIPT = checker.CONFIG_PATH.with_name("check_function_length.py")
SAMPLE_CONFIG = checker.Config(
    limit=LIMIT,
    roots=("src/", "tools/"),
    languages={".py": "function_length_python", ".mc": "function_length_monkeyc"},
    excluded_directories=frozenset({"tests", "vendor"}),
    excluded_files=(re.compile(r"(^|/)test_[^/]*\.py$"),),
    area_prefixes=("src/app/",),
)


def statements(count: int) -> str:
    return "".join(f"    value_{index} = {index}\n" for index in range(count))


def too_long_python() -> str:
    return f"def too_long():\n{statements(LIMIT + 1)}"


def make_repository(root: Path, files: dict[str, str]) -> Path:
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    for relative_path, content in files.items():
        target = root / relative_path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content, encoding="utf-8")
    return root


def use_sample_config(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setattr(checker, "load_config", lambda _path=None: SAMPLE_CONFIG)


def test_each_suffix_uses_its_language_measurer(tmp_path: Path) -> None:
    monkey_c = "function slow() {\n" + "".join(f"    go({index});\n" for index in range(LIMIT + 2)) + "}\n"
    make_repository(tmp_path, {"tools/a.py": too_long_python(), "tools/b.mc": monkey_c, "tools/c.txt": monkey_c})

    found = checker.find_violations(tmp_path, SAMPLE_CONFIG)

    assert sorted((item.path, item.name, item.length) for item in found) == [
        ("tools/a.py", "too_long", LIMIT + 1),
        ("tools/b.mc", "slow", LIMIT + 2),
    ]


@pytest.mark.parametrize(
    ("path", "is_measured"),
    [
        ("src/app/core.py", True),
        ("src/app/View.mc", True),
        ("tools/notes.txt", False),
        ("src/app/tests/helpers.py", False),
        ("src/vendor/lib.py", False),
        ("tools/test_core.py", False),
        ("docs/example.py", False),
        ("toolsmith/script.py", False),
    ],
)
def test_only_production_files_in_known_languages_are_measured(path: str, *, is_measured: bool) -> None:
    assert checker.is_production_file(path, SAMPLE_CONFIG) is is_measured


@pytest.mark.parametrize(
    ("path", "area"),
    [("src/app/billing/core.py", "src/app/billing"), ("src/app/main.py", "src/app"), ("tools/x.py", "tools")],
)
def test_area_groups_by_component(path: str, area: str) -> None:
    assert checker.area_of(path, SAMPLE_CONFIG) == area


def test_report_sorts_by_length_and_summarizes_per_area() -> None:
    violations = [
        checker.Violation("tools/a.py", 9, "short", 13),
        checker.Violation("src/app/cli.py", 4, "longest", 30),
        checker.Violation("tools/a.py", 2, "tied", 13),
    ]

    assert checker.format_report(violations, SAMPLE_CONFIG).splitlines() == [
        f"Functions with a body over {LIMIT} lines: 3",
        "src/app/cli.py:4 longest 30",
        "tools/a.py:2 tied 13",
        "tools/a.py:9 short 13",
        "",
        "Summary by area:",
        "  src/app: 1",
        "  tools: 2",
        "Total: 3",
    ]


def test_tracked_files_deleted_from_the_working_tree_are_skipped(tmp_path: Path) -> None:
    make_repository(tmp_path, {"tools/gone.py": too_long_python()})
    subprocess.run(["git", "add", "."], cwd=tmp_path, check=True)
    (tmp_path / "tools/gone.py").unlink()

    assert checker.list_repository_files(tmp_path) == []


@pytest.mark.parametrize(("flags", "exit_code"), [([], 0), (["--strict"], 1)])
def test_strict_mode_fails_only_when_there_are_violations(
    tmp_path: Path,
    capsys: pytest.CaptureFixture[str],
    monkeypatch: pytest.MonkeyPatch,
    flags: list[str],
    exit_code: int,
) -> None:
    use_sample_config(monkeypatch)
    make_repository(tmp_path, {"tools/sample.py": too_long_python()})

    assert checker.main([*flags, "--root", str(tmp_path)]) == exit_code
    assert f"tools/sample.py:1 too_long {LIMIT + 1}" in capsys.readouterr().out


def test_strict_mode_passes_a_clean_repository(
    tmp_path: Path, capsys: pytest.CaptureFixture[str], monkeypatch: pytest.MonkeyPatch
) -> None:
    use_sample_config(monkeypatch)
    make_repository(tmp_path, {"tools/sample.py": "def short():\n    return 1\n"})

    assert checker.main(["--strict", "--root", str(tmp_path)]) == 0
    assert capsys.readouterr().out.endswith("Total: 0\n")


def test_json_format_lists_every_violation(
    tmp_path: Path, capsys: pytest.CaptureFixture[str], monkeypatch: pytest.MonkeyPatch
) -> None:
    use_sample_config(monkeypatch)
    make_repository(tmp_path, {"tools/sample.py": too_long_python()})

    assert checker.main(["--format", "json", "--root", str(tmp_path)]) == 0
    assert json.loads(capsys.readouterr().out) == [
        {"path": "tools/sample.py", "line": 1, "name": "too_long", "length": LIMIT + 1}
    ]


def test_script_entry_point_reads_the_command_line(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    make_repository(tmp_path, {"tools/sample.py": too_long_python()})
    monkeypatch.setattr(sys, "argv", [str(SCRIPT), "--strict", "--root", str(tmp_path)])

    with pytest.raises(SystemExit) as raised:
        runpy.run_path(str(SCRIPT), run_name="__main__")

    assert raised.value.code == 1
