"""Tests for tools/function_length_monkeyc.py."""

from __future__ import annotations

import check_function_length as checker
from function_length_model import MeasuredFunction
from function_length_monkeyc import measure

LIMIT = checker.load_config().limit


def statements(count: int, indent: str = "        ") -> str:
    return "".join(f"{indent}var value{index} = {index};\n" for index in range(count))


def lengths(source: str) -> dict[str, int]:
    return {function.name: function.length for function in measure(source)}


def test_methods_are_qualified_by_their_module_and_class() -> None:
    source = (
        "module Kit {\n    class View extends Ui.View {\n"
        f"        function onUpdate(dc as Dc) as Void {{\n{statements(LIMIT + 1, '            ')}        }}\n"
        "    }\n}\n"
        f"function helper() {{\n{statements(2)}}}\n"
    )

    assert lengths(source) == {"Kit.View.onUpdate": LIMIT + 1, "helper": 2}


def test_inner_blocks_and_dictionaries_belong_to_their_function() -> None:
    body = '    if (ready) {\n        go();\n    } else {\n        stop();\n    }\n    var map = { "a" => 1 };\n'

    assert lengths(f"function decide() {{\n{body}}}\n") == {"decide": 6}


def test_blank_and_comment_lines_do_not_count() -> None:
    body = "\n    // why\n    /* first\n       second */\n    go(); // trailing\n    /* a */ stop();\n"

    assert lengths(f"function quiet() {{\n{body}}}\n") == {"quiet": 2}


def test_braces_inside_strings_and_characters_are_ignored() -> None:
    body = '    var text = "}{ \\" }";\n    var brace = \'}\';\n'

    assert lengths(f"function strings() {{\n{body}}}\n") == {"strings": 2}


def test_annotations_and_multi_line_signatures_report_the_function_keyword_line() -> None:
    source = "(:test)\nfunction checks(\n    logger as Logger\n) as Boolean {\n    return true;\n}\n"

    assert measure(source) == [MeasuredFunction("checks", 2, 1)]


def test_the_closing_line_counts_when_code_precedes_the_brace() -> None:
    assert lengths("function tight() {\n    go();\n    stop(); }\n") == {"tight": 2}


def test_one_liners_have_an_empty_body() -> None:
    assert lengths("function noop() { return; }\n") == {"noop": 0}


def test_a_stray_closing_brace_is_harmless() -> None:
    assert lengths("}\nfunction late() {\n    go();\n}\n") == {"late": 1}
