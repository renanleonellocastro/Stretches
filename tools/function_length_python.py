"""Measures Python function bodies through the ast module.

The body runs from its first statement (or that statement's first decorator) to the last line
of the function; blank and comment only lines never count.
"""

from __future__ import annotations

import ast
import io
import tokenize
from typing import TYPE_CHECKING

from function_length_model import MeasuredFunction

if TYPE_CHECKING:
    from collections.abc import Iterable, Iterator

TRIVIA_TOKENS = frozenset(
    {tokenize.COMMENT, tokenize.NL, tokenize.NEWLINE, tokenize.INDENT, tokenize.DEDENT, tokenize.ENDMARKER}
)
type FunctionNode = ast.FunctionDef | ast.AsyncFunctionDef


def code_lines(source: str) -> frozenset[int]:
    source_lines = source.splitlines()
    covered: set[int] = set()
    for token in tokenize.generate_tokens(io.StringIO(source).readline):
        if token.type not in TRIVIA_TOKENS:
            covered.update(range(token.start[0], token.end[0] + 1))
    return frozenset(number for number in covered if source_lines[number - 1].strip())


def iter_functions(node: ast.AST, scope: tuple[str, ...] = ()) -> Iterator[tuple[str, FunctionNode]]:
    for child in ast.iter_child_nodes(node):
        child_scope = scope
        if isinstance(child, ast.FunctionDef | ast.AsyncFunctionDef | ast.ClassDef):
            child_scope = (*scope, child.name)
        if isinstance(child, ast.FunctionDef | ast.AsyncFunctionDef):
            yield ".".join(child_scope), child
        yield from iter_functions(child, child_scope)


def statement_start(statement: ast.stmt) -> int:
    decorators: Iterable[ast.expr] = getattr(statement, "decorator_list", ())
    return min([statement.lineno, *(decorator.lineno for decorator in decorators)])


def body_length(function: FunctionNode, lines: frozenset[int]) -> int:
    first_line = statement_start(function.body[0])
    last_line = function.end_lineno or first_line
    return sum(1 for number in range(first_line, last_line + 1) if number in lines)


def measure(source: str) -> list[MeasuredFunction]:
    lines = code_lines(source)
    return [
        MeasuredFunction(name, function.lineno, body_length(function, lines))
        for name, function in iter_functions(ast.parse(source))
    ]
