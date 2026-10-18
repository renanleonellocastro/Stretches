"""Tests for tools/function_length_ratchet.py, run against throwaway git repositories."""

from __future__ import annotations

import json
import runpy
import subprocess
import sys
from typing import TYPE_CHECKING

import pytest

import check_function_length as checker
import function_length_ratchet as ratchet

if TYPE_CHECKING:
    from pathlib import Path

LIMIT = checker.load_config().limit
SCRIPT = checker.CONFIG_PATH.with_name("function_length_ratchet.py")


def long_function(name: str, extra_lines: int = 1) -> str:
    body = "".join(f"    value_{index} = {index}\n" for index in range(LIMIT + extra_lines))
    return f"def {name}():\n{body}\n"


def make_repository(root: Path, source: str) -> Path:
    subprocess.run(["git", "init", "-q", str(root)], check=True)
    (root / "tools").mkdir()
    (root / "tools/sample.py").write_text(source, encoding="utf-8")
    return root


def entry(name: str, length: int, path: str = "tools/sample.py") -> ratchet.LongFunction:
    return ratchet.LongFunction(path, name, length)


def test_unchanged_functions_pass() -> None:
    verdict = ratchet.judge([entry("old", 20)], [entry("old", 20)])

    assert verdict.is_passing
    assert verdict.shrinkable == 0


def test_a_new_long_function_fails() -> None:
    verdict = ratchet.judge([entry("old", 20), entry("fresh", 13)], [entry("old", 20)])

    assert not verdict.is_passing
    assert verdict.new == (entry("fresh", 13),)


def test_a_baselined_function_that_grows_fails() -> None:
    verdict = ratchet.judge([entry("old", 21)], [entry("old", 20)])

    assert verdict.grown == (ratchet.Growth(entry("old", 21), 20),)
    assert not verdict.is_passing


def test_shrunk_and_fixed_functions_pass_and_report_the_possible_shrink() -> None:
    verdict = ratchet.judge([entry("shrunk", 15)], [entry("shrunk", 18), entry("fixed", 14)])

    assert verdict.is_passing
    assert (verdict.shrinkable, verdict.total, verdict.baseline_total) == (2, 1, 2)


def test_functions_sharing_a_name_are_paired_longest_first() -> None:
    baseline = [entry("anonymous", 30), entry("anonymous", 14)]

    verdict = ratchet.judge([entry("anonymous", 14), entry("anonymous", 29), entry("anonymous", 13)], baseline)

    assert verdict.new == (entry("anonymous", 13),)
    assert verdict.grown == ()
    assert verdict.shrinkable == 1


def test_a_total_above_the_baseline_fails_even_without_named_problems() -> None:
    verdict = ratchet.Verdict(new=(), grown=(), shrinkable=0, total=3, baseline_total=2)

    assert not verdict.is_passing


def test_the_description_lists_problems_and_the_possible_shrink() -> None:
    verdict = ratchet.Verdict(
        new=(entry("fresh", 13),),
        grown=(ratchet.Growth(entry("old", 21), 20),),
        shrinkable=1,
        total=2,
        baseline_total=2,
    )

    assert ratchet.describe_verdict(verdict, LIMIT).splitlines() == [
        "Function length ratchet: FAILED",
        f"Functions over {LIMIT} lines: 2 (baseline 2)",
        f"  new: tools/sample.py fresh 13 (limit {LIMIT})",
        "  grew: tools/sample.py old 20 to 21",
        "The baseline can shrink by 1: run `make function-length-baseline`.",
    ]


def test_a_missing_baseline_is_empty(tmp_path: Path) -> None:
    assert ratchet.read_baseline(tmp_path / "missing.json") == []


def test_the_baseline_round_trips_in_a_stable_order(tmp_path: Path) -> None:
    baseline_path = tmp_path / "baseline.json"
    functions = [entry("zeta", 14), entry("alpha", 15, path="src/x.py"), entry("alpha", 20)]

    ratchet.write_baseline(baseline_path, functions)

    assert json.loads(baseline_path.read_text(encoding="utf-8"))["total"] == len(functions)
    assert ratchet.read_baseline(baseline_path) == [functions[1], functions[2], functions[0]]


@pytest.mark.parametrize(("baseline_length", "exit_code"), [(LIMIT + 1, 0), (LIMIT, 1)])
def test_check_exits_by_the_verdict(
    tmp_path: Path, capsys: pytest.CaptureFixture[str], baseline_length: int, exit_code: int
) -> None:
    make_repository(tmp_path, long_function("too_long"))
    baseline_path = tmp_path / "baseline.json"
    ratchet.write_baseline(baseline_path, [entry("too_long", baseline_length)])

    assert ratchet.main(["--root", str(tmp_path), "--baseline", str(baseline_path)]) == exit_code
    assert "Function length ratchet" in capsys.readouterr().out


def test_the_baseline_action_refuses_a_growth(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    make_repository(tmp_path, long_function("too_long"))
    baseline_path = tmp_path / "baseline.json"

    assert ratchet.main(["baseline", "--root", str(tmp_path), "--baseline", str(baseline_path)]) == 1
    assert "The baseline only shrinks" in capsys.readouterr().out
    assert not baseline_path.exists()


def test_the_baseline_action_shrinks_the_baseline(tmp_path: Path) -> None:
    make_repository(tmp_path, long_function("kept", extra_lines=2))
    baseline_path = tmp_path / "baseline.json"
    ratchet.write_baseline(baseline_path, [entry("kept", LIMIT + 5), entry("fixed", LIMIT + 9)])

    assert ratchet.main(["baseline", "--root", str(tmp_path), "--baseline", str(baseline_path)]) == 0
    assert ratchet.read_baseline(baseline_path) == [entry("kept", LIMIT + 2)]


def test_the_exceptional_action_records_a_growth(tmp_path: Path) -> None:
    make_repository(tmp_path, long_function("too_long"))
    baseline_path = tmp_path / "baseline.json"

    assert ratchet.main(["grow-baseline", "--root", str(tmp_path), "--baseline", str(baseline_path)]) == 0
    assert ratchet.read_baseline(baseline_path) == [entry("too_long", LIMIT + 1)]


def test_script_entry_point_reads_the_command_line(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    make_repository(tmp_path, long_function("too_long"))
    baseline_path = tmp_path / "baseline.json"
    monkeypatch.setattr(sys, "argv", [str(SCRIPT), "--root", str(tmp_path), "--baseline", str(baseline_path)])

    with pytest.raises(SystemExit) as raised:
        runpy.run_path(str(SCRIPT), run_name="__main__")

    assert raised.value.code == 1
