"""Report functions whose body is longer than rule 1 of the quality bar allows.

Each file suffix maps, in function_length.json, to a measurer module that exposes
`measure(source) -> list[MeasuredFunction]`. The JSON format feeds function_length_ratchet.py.
"""

from __future__ import annotations

import argparse
import importlib
import json
import re
import subprocess
import sys
from collections import Counter
from dataclasses import asdict, dataclass
from pathlib import Path, PurePosixPath
from typing import TYPE_CHECKING, cast

if TYPE_CHECKING:
    from collections.abc import Callable, Mapping, Sequence

    from function_length_model import Measurer

CONFIG_PATH = Path(__file__).with_name("function_length.json")
REPO_ROOT = Path(__file__).resolve().parent.parent
DESCRIPTION = "Report functions longer than the quality bar allows."
GIT_LIST_FILES = ("git", "ls-files", "-z", "--cached", "--others", "--exclude-standard")


@dataclass(frozen=True)
class Config:
    limit: int
    roots: tuple[str, ...]
    languages: Mapping[str, str]
    excluded_directories: frozenset[str]
    excluded_files: tuple[re.Pattern[str], ...]
    area_prefixes: tuple[str, ...]


@dataclass(frozen=True)
class Violation:
    path: str
    line: int
    name: str
    length: int


def load_config(path: Path = CONFIG_PATH) -> Config:
    raw = json.loads(path.read_text(encoding="utf-8"))
    return Config(
        limit=raw["limit"],
        roots=tuple(raw["roots"]),
        languages=dict(raw["languages"]),
        excluded_directories=frozenset(raw["excludedDirectories"]),
        excluded_files=tuple(re.compile(pattern) for pattern in raw["excludedFilePatterns"]),
        area_prefixes=tuple(raw["areaPrefixes"]),
    )


def load_measurer(module_name: str) -> Measurer:
    return cast("Measurer", importlib.import_module(module_name).measure)


def list_repository_files(root: Path) -> list[str]:
    listing = subprocess.run(GIT_LIST_FILES, cwd=root, capture_output=True, text=True, check=True)
    return [path for path in listing.stdout.split("\0") if path and (root / path).is_file()]


def is_production_file(path: str, config: Config) -> bool:
    if PurePosixPath(path).suffix not in config.languages or not path.startswith(config.roots):
        return False
    if config.excluded_directories.intersection(path.split("/")[:-1]):
        return False
    return not any(pattern.search(path) for pattern in config.excluded_files)


def check_file(root: Path, path: str, config: Config) -> list[Violation]:
    measure = load_measurer(config.languages[PurePosixPath(path).suffix])
    measured = measure((root / path).read_text(encoding="utf-8"))
    return [
        Violation(path, function.line, function.name, function.length)
        for function in measured
        if function.length > config.limit
    ]


def area_of(path: str, config: Config) -> str:
    for prefix in config.area_prefixes:
        if path.startswith(prefix):
            rest = path.removeprefix(prefix).split("/")
            return prefix + rest[0] if len(rest) > 1 else prefix.rstrip("/")
    return path.split("/", maxsplit=1)[0]


def format_violation(violation: Violation) -> str:
    return f"{violation.path}:{violation.line} {violation.name} {violation.length}"


def format_report(violations: Sequence[Violation], config: Config) -> str:
    ordered = sorted(violations, key=lambda item: (-item.length, item.path, item.line))
    areas = Counter(area_of(violation.path, config) for violation in violations)
    return "\n".join(
        [
            f"Functions with a body over {config.limit} lines: {len(violations)}",
            *(format_violation(violation) for violation in ordered),
            "",
            "Summary by area:",
            *(f"  {area}: {count}" for area, count in sorted(areas.items())),
            f"Total: {len(violations)}",
        ]
    )


def format_json(violations: Sequence[Violation], _config: Config) -> str:
    return json.dumps([asdict(violation) for violation in violations], ensure_ascii=False)


FORMATTERS: dict[str, Callable[[Sequence[Violation], Config], str]] = {
    "report": format_report,
    "json": format_json,
}


def find_violations(root: Path, config: Config) -> list[Violation]:
    files = [path for path in list_repository_files(root) if is_production_file(path, config)]
    return [violation for path in files for violation in check_file(root, path, config)]


def parse_arguments(argv: Sequence[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=DESCRIPTION)
    parser.add_argument("--strict", action="store_true", help="exit 1 when any function is too long")
    parser.add_argument("--root", type=Path, default=REPO_ROOT, help="repository root to scan")
    parser.add_argument("--format", choices=sorted(FORMATTERS), default="report", help="output format")
    return parser.parse_args(argv)


def main(argv: Sequence[str] | None = None) -> int:
    arguments = parse_arguments(sys.argv[1:] if argv is None else argv)
    config = load_config()
    violations = find_violations(arguments.root, config)
    sys.stdout.write(FORMATTERS[arguments.format](violations, config) + "\n")
    return 1 if arguments.strict and violations else 0


if __name__ == "__main__":
    sys.exit(main())
