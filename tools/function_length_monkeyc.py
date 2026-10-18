"""Measures Monkey C function bodies with a small string and comment aware brace scanner.

A body is counted between the line of its opening brace and the line of its closing brace; the
closing line counts too when code precedes the brace on it. Blank and comment only lines never
count. Names are qualified by the enclosing modules, classes and functions (`HomeView.onUpdate`).
"""

from __future__ import annotations

import re
from dataclasses import dataclass
from enum import Enum, auto
from typing import TYPE_CHECKING

from function_length_model import BraceBody, MeasuredFunction

if TYPE_CHECKING:
    from collections.abc import Callable

FUNCTION_HEADER = re.compile(r"\bfunction\s+(?P<name>\w+)")
CONTAINER_HEADER = re.compile(r"\b(?:class|module)\s+(?P<name>\w+)")
STATEMENT_BREAKS = frozenset(";{}")
LINE_COMMENT = "//"
BLOCK_COMMENT_OPEN = "/*"
BLOCK_COMMENT_CLOSE = "*/"
QUOTES = frozenset({'"', "'"})


class FrameKind(Enum):
    FUNCTION = auto()
    CONTAINER = auto()
    BLOCK = auto()


@dataclass(frozen=True)
class Frame:
    kind: FrameKind
    name: str
    header_line: int
    open_line: int


class MonkeyCScanner:
    """Walks a source file once, tracking strings, comments and the stack of open braces."""

    def __init__(self) -> None:
        self.quote: str | None = None
        self.in_block_comment = False
        self.prefix = ""
        self.prefix_line = 1
        self.frames: list[Frame] = []
        self.code_lines: set[int] = set()
        self.measured: list[MeasuredFunction] = []
        self.line_number = 0
        self.has_code_on_line = False

    def scan(self, source: str) -> list[MeasuredFunction]:
        for number, text in enumerate(source.splitlines(), start=1):
            self.line_number = number
            self.has_code_on_line = False
            self.scan_characters(text)
            self.prefix += "\n"
        return self.measured

    def scan_characters(self, text: str) -> None:
        index = 0
        while index < len(text):
            index = self.step_handler()(text, index)

    def step_handler(self) -> Callable[[str, int], int]:
        if self.in_block_comment:
            return self.step_block_comment
        if self.quote is not None:
            return self.step_quoted
        return self.step_plain

    def step_block_comment(self, text: str, index: int) -> int:
        if text.startswith(BLOCK_COMMENT_CLOSE, index):
            self.in_block_comment = False
            return index + len(BLOCK_COMMENT_CLOSE)
        return index + 1

    def step_quoted(self, text: str, index: int) -> int:
        self.mark_code()
        if text[index] == "\\":
            return index + 2
        if text[index] == self.quote:
            self.quote = None
        return index + 1

    def step_plain(self, text: str, index: int) -> int:
        if text.startswith(LINE_COMMENT, index):
            return len(text)
        if text.startswith(BLOCK_COMMENT_OPEN, index):
            self.in_block_comment = True
            return index + len(BLOCK_COMMENT_OPEN)
        character = text[index]
        if character.isspace():
            self.prefix += " "
        else:
            self.read_code_character(character)
        return index + 1

    def read_code_character(self, character: str) -> None:
        if character in QUOTES:
            self.quote = character
        if character in STATEMENT_BREAKS:
            self.end_statement(character)
        else:
            self.extend_prefix(character)
        self.mark_code()

    def extend_prefix(self, character: str) -> None:
        if not self.prefix.strip():
            self.prefix = ""
            self.prefix_line = self.line_number
        self.prefix += character

    def end_statement(self, character: str) -> None:
        if character == "{":
            self.frames.append(self.frame_from_prefix())
        if character == "}" and self.frames:
            self.close_frame(self.frames.pop())
        self.prefix = ""

    def frame_from_prefix(self) -> Frame:
        function = FUNCTION_HEADER.search(self.prefix)
        if function is not None:
            return self.frame(FrameKind.FUNCTION, function)
        container = CONTAINER_HEADER.search(self.prefix)
        if container is not None:
            return self.frame(FrameKind.CONTAINER, container)
        return Frame(FrameKind.BLOCK, "", self.line_number, self.line_number)

    def frame(self, kind: FrameKind, header: re.Match[str]) -> Frame:
        header_line = self.prefix_line + self.prefix[: header.start()].count("\n")
        return Frame(kind, header["name"], header_line, self.line_number)

    def close_frame(self, frame: Frame) -> None:
        if frame.kind is not FrameKind.FUNCTION:
            return
        body = BraceBody(frame.open_line, self.line_number, self.has_code_on_line)
        name = ".".join([*self.scope_names(), frame.name])
        self.measured.append(MeasuredFunction(name, frame.header_line, body.length(self.code_lines)))

    def scope_names(self) -> list[str]:
        return [frame.name for frame in self.frames if frame.kind is not FrameKind.BLOCK]

    def mark_code(self) -> None:
        self.has_code_on_line = True
        self.code_lines.add(self.line_number)


def measure(source: str) -> list[MeasuredFunction]:
    return MonkeyCScanner().scan(source)
