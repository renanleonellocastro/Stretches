"""Ratchet gate for rule 1 of the quality bar (function bodies of at most 12 lines).

The baseline lists the long functions that existed when the rule arrived. The gate fails when a
function outside the baseline passes the limit, when a baselined function grows, or when the total
rises. The baseline only shrinks: recording a growth needs the exceptional grow-baseline action.
"""

from __future__ import annotations

import argparse
import json
import sys
from collections import defaultdict
from dataclasses import dataclass
from pathlib import Path
from typing import TYPE_CHECKING

import check_function_length as checker

if TYPE_CHECKING:
    from collections.abc import Callable, Iterable, Sequence

BASELINE_PATH = Path(__file__).with_name("function_length_baseline.json")
DESCRIPTION = "Ratchet gate for functions longer than the quality bar allows."
type FunctionKey = tuple[str, str]


@dataclass(frozen=True)
class LongFunction:
    path: str
    name: str
    length: int

    @property
    def key(self) -> FunctionKey:
        return (self.path, self.name)


@dataclass(frozen=True)
class Growth:
    function: LongFunction
    baseline_length: int


@dataclass(frozen=True)
class Verdict:
    new: tuple[LongFunction, ...]
    grown: tuple[Growth, ...]
    shrinkable: int
    total: int
    baseline_total: int

    @property
    def is_passing(self) -> bool:
        return not self.new and not self.grown and self.total <= self.baseline_total


def collect_long_functions(root: Path, config_path: Path = checker.CONFIG_PATH) -> list[LongFunction]:
    return [
        LongFunction(violation.path, violation.name, violation.length)
        for violation in checker.find_violations(root, checker.load_config(config_path))
    ]


def read_baseline(path: Path) -> list[LongFunction]:
    if not path.exists():
        return []
    raw = json.loads(path.read_text(encoding="utf-8"))
    return [LongFunction(item["path"], item["name"], item["length"]) for item in raw["functions"]]


def write_baseline(path: Path, functions: Iterable[LongFunction]) -> None:
    ordered = sorted(functions, key=lambda function: (function.path, function.name, -function.length))
    entries = [{"path": item.path, "name": item.name, "length": item.length} for item in ordered]
    document = {"total": len(entries), "functions": entries}
    path.write_text(json.dumps(document, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def lengths_by_key(functions: Iterable[LongFunction]) -> dict[FunctionKey, list[LongFunction]]:
    grouped: dict[FunctionKey, list[LongFunction]] = defaultdict(list)
    for function in functions:
        grouped[function.key].append(function)
    return {key: sorted(group, key=lambda item: -item.length) for key, group in grouped.items()}


def compare_group(current: list[LongFunction], baseline: list[LongFunction]) -> Verdict:
    paired = list(zip(current, baseline, strict=False))
    grown = tuple(Growth(now, before.length) for now, before in paired if now.length > before.length)
    shrunk = sum(1 for now, before in paired if now.length < before.length)
    return Verdict(
        new=tuple(current[len(baseline) :]),
        grown=grown,
        shrinkable=shrunk + max(len(baseline) - len(current), 0),
        total=len(current),
        baseline_total=len(baseline),
    )


def combine(verdicts: Iterable[Verdict]) -> Verdict:
    parts = list(verdicts)
    return Verdict(
        new=tuple(function for part in parts for function in part.new),
        grown=tuple(growth for part in parts for growth in part.grown),
        shrinkable=sum(part.shrinkable for part in parts),
        total=sum(part.total for part in parts),
        baseline_total=sum(part.baseline_total for part in parts),
    )


def judge(current: Iterable[LongFunction], baseline: Iterable[LongFunction]) -> Verdict:
    current_groups = lengths_by_key(current)
    baseline_groups = lengths_by_key(baseline)
    keys = sorted(current_groups.keys() | baseline_groups.keys())
    return combine(compare_group(current_groups.get(key, []), baseline_groups.get(key, [])) for key in keys)


def describe_problems(verdict: Verdict, limit: int) -> list[str]:
    new = [f"  new: {item.path} {item.name} {item.length} (limit {limit})" for item in verdict.new]
    grown = [
        f"  grew: {growth.function.path} {growth.function.name} {growth.baseline_length} to {growth.function.length}"
        for growth in verdict.grown
    ]
    return new + grown


def describe_verdict(verdict: Verdict, limit: int) -> str:
    status = "ok" if verdict.is_passing else "FAILED"
    lines = [
        f"Function length ratchet: {status}",
        f"Functions over {limit} lines: {verdict.total} (baseline {verdict.baseline_total})",
        *describe_problems(verdict, limit),
    ]
    if verdict.shrinkable:
        lines.append(f"The baseline can shrink by {verdict.shrinkable}: run `make function-length-baseline`.")
    return "\n".join(lines)


def check(root: Path, baseline_path: Path) -> int:
    verdict = judge(collect_long_functions(root), read_baseline(baseline_path))
    sys.stdout.write(describe_verdict(verdict, checker.load_config().limit) + "\n")
    return 0 if verdict.is_passing else 1


def record_baseline(baseline_path: Path, current: Sequence[LongFunction], previous_total: int) -> int:
    write_baseline(baseline_path, current)
    sys.stdout.write(f"Baseline written with {len(current)} functions (was {previous_total}).\n")
    return 0


def shrink_baseline(root: Path, baseline_path: Path) -> int:
    current = collect_long_functions(root)
    verdict = judge(current, read_baseline(baseline_path))
    if not verdict.is_passing:
        problems = "\n".join(describe_problems(verdict, checker.load_config().limit))
        sys.stdout.write(f"The baseline only shrinks. Fix these first:\n{problems}\n")
        return 1
    return record_baseline(baseline_path, current, verdict.baseline_total)


def grow_baseline(root: Path, baseline_path: Path) -> int:
    current = collect_long_functions(root)
    return record_baseline(baseline_path, current, len(read_baseline(baseline_path)))


ACTIONS: dict[str, Callable[[Path, Path], int]] = {
    "check": check,
    "baseline": shrink_baseline,
    "grow-baseline": grow_baseline,
}


def parse_arguments(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument(
        "action",
        nargs="?",
        choices=sorted(ACTIONS),
        default="check",
        help="check the gate, shrink the baseline, or (exceptional) record a growth",
    )
    parser.add_argument("--root", type=Path, default=checker.REPO_ROOT, help="repository root to scan")
    parser.add_argument("--baseline", type=Path, default=BASELINE_PATH, help="baseline file")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_arguments(sys.argv[1:] if argv is None else argv)
    return ACTIONS[arguments.action](arguments.root, arguments.baseline)


if __name__ == "__main__":
    sys.exit(main())
