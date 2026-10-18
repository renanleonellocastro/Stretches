"""Tests for tools/function_length_model.py."""

from __future__ import annotations

import pytest

from function_length_model import BraceBody


@pytest.mark.parametrize(
    ("body", "length"),
    [
        (BraceBody(open_line=1, close_line=5, closes_after_code=False), 2),
        (BraceBody(open_line=1, close_line=5, closes_after_code=True), 3),
        (BraceBody(open_line=2, close_line=2, closes_after_code=True), 0),
    ],
)
def test_brace_bodies_count_inner_code_lines_and_a_closing_line_with_code(body: BraceBody, length: int) -> None:
    assert body.length({2, 3, 5}) == length
