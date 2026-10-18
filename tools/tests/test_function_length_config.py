"""Tests for the paths tools/function_length.json measures in this repository."""

from __future__ import annotations

import pytest

import check_function_length as checker

CONFIG = checker.load_config()


@pytest.mark.parametrize(
    ("path", "is_measured"),
    [
        ("source/ui/HomeView.mc", True),
        ("source/StretchesApp.mc", True),
        ("scripts/generate_strings.py", True),
        ("tools/check_function_length.py", True),
        ("source/tests/CatalogTest.mc", False),
        ("source/generated/Strings.mc", False),
        ("tools/tests/test_check_function_length.py", False),
        ("scripts/resource_paths.jungle", False),
        ("resources/strings/strings.xml", False),
    ],
)
def test_app_scripts_and_tools_are_the_production_code(path: str, *, is_measured: bool) -> None:
    assert checker.is_production_file(path, CONFIG) is is_measured
