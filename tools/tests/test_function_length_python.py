"""Tests for tools/function_length_python.py."""

from __future__ import annotations

import check_function_length as checker
from function_length_python import measure

LIMIT = checker.load_config().limit


def statements(count: int, indent: str = "    ") -> str:
    return "".join(f"{indent}value_{index} = {index}\n" for index in range(count))


def lengths(source: str) -> dict[str, int]:
    return {function.name: function.length for function in measure(source)}


def test_the_body_counts_every_statement_line() -> None:
    assert lengths(f"def at_limit():\n{statements(LIMIT)}") == {"at_limit": LIMIT}


def test_blank_comment_and_signature_lines_do_not_count() -> None:
    body = statements(LIMIT, indent="    # note\n\n    ")
    source = f"def spread(\n    first,\n    second,\n):\n{body}    # closing note\n"

    assert lengths(source) == {"spread": LIMIT}


def test_docstrings_and_multi_line_strings_count_except_their_blank_lines() -> None:
    source = f'def documented():\n    """Line one.\n\n    Line two.\n    """\n{statements(LIMIT - 2)}'

    assert lengths(source) == {"documented": LIMIT + 1}


def test_methods_nested_and_async_functions_get_qualified_names() -> None:
    long_body = statements(LIMIT + 1, indent="        ")
    source = (
        f"class Shelf:\n    def method(self):\n{long_body}\n"
        f"def outer():\n    async def inner():\n{long_body}    return inner\n"
    )

    assert lengths(source) == {"Shelf.method": LIMIT + 1, "outer": LIMIT + 3, "outer.inner": LIMIT + 1}


def test_a_decorated_first_statement_counts_from_its_decorator() -> None:
    source = f"def outer():\n    @staticmethod\n    def inner():\n{statements(LIMIT - 1, indent='        ')}"

    assert lengths(source)["outer"] == LIMIT + 1


def test_lambdas_are_not_measured() -> None:
    lines = "".join(f"    {index},\n" for index in range(LIMIT + 2))

    assert lengths(f"pick = lambda: (\n{lines})\n") == {}


def test_the_header_line_is_reported() -> None:
    assert [function.line for function in measure("\n\ndef late():\n    return 1\n")] == [3]
