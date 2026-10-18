"""Shared types for the function length checker and its language measurers."""

from __future__ import annotations

from dataclasses import dataclass
from typing import TYPE_CHECKING, Protocol

if TYPE_CHECKING:
    from collections.abc import Set


@dataclass(frozen=True)
class MeasuredFunction:
    name: str
    line: int
    length: int


class Measurer(Protocol):
    def __call__(self, source: str) -> list[MeasuredFunction]: ...


@dataclass(frozen=True)
class BraceBody:
    """A function body delimited by braces, as Bash and Monkey C write it."""

    open_line: int
    close_line: int
    closes_after_code: bool

    def length(self, code_lines: Set[int]) -> int:
        inner = sum(1 for number in range(self.open_line + 1, self.close_line) if number in code_lines)
        has_code_on_closing_line = self.closes_after_code and self.close_line > self.open_line
        return inner + int(has_code_on_closing_line)
