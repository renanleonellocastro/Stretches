# Quality bar

These rules apply to all production code: the app in `source/` and the Python scripts and tools in `scripts/` and `tools/`. Tests (`source/tests`, `tools/tests`) and generated code (`source/generated`) are out of scope.

## Rules

1. **Short functions.** Every function and method body has at most 12 lines. Blank lines and comment only lines do not count, and neither does a signature split over several lines.
   * Monkey C: the count runs between the line of the opening brace and the line of the closing brace; the closing line counts only when code precedes the brace on it.
   * Python: the count runs from the first statement of the body to the last line of the function.
   * To fit, extract well named helpers. Never chain statements with semicolons, never write an unreadable one liner or a giant ternary to cheat the count.
2. **Single responsibility** for every function, class and module. A function does one thing at one level of abstraction, and its name says exactly what it does.
3. **All of SOLID**, not only the S:
   * **S**: single responsibility at module level too (the engine, persistence, scheduling, recording and each view stay apart).
   * **O**: new behavior arrives through new strategies, delegates, dispatch tables or composition, never by growing an `if`/`else if` chain.
   * **L**: every subclass, delegate and fake honors the full contract of what it replaces (same errors, same invariants).
   * **I**: small focused interfaces; a view or delegate receives only what it uses; no god modules and no catch all `utils`.
   * **D**: logic depends on abstractions; time, storage, the UI stack and randomness are passed in at the edge, which is what keeps `WorkoutEngine` and `Scheduler` unit testable. No hidden globals.
4. **Meaningful names.** No abbreviations beyond the universal ones (`id`, `url`, `api`, `ui`, `fit`); no single letter names outside tiny loops, lambdas and comprehensions; booleans read as predicates (`is`, `has`, `can`, `should`); functions are verbs, classes are nouns.
5. **No dead code, no commented out code, no duplicated logic** (extract the shared part), no magic numbers or strings (use named constants; user visible text always comes from string resources), no broad `except`.
6. **Comments explain why**, never what. Docstrings only where the contract is not obvious.
7. **Refactoring never changes behavior.** The only exception is a real bug fix: first a test that shows the bug, then the fix, and the commit says what changed. Generated assets (illustrations, store art, `Strings.mc`) must stay byte for byte identical after a refactor of their generator.

Also: DRY, KISS and YAGNI; high cohesion and low coupling; the Law of Demeter (no long call chains through other objects); tell, don't ask; command query separation; guard clauses and fail fast; immutability by default (frozen dataclasses, `const`); pure functions for logic; composition over inheritance; explicit errors; no boolean flag parameters that switch behavior (split the function); consistent module structure and file naming.

Tests keep covering everything testable (see [TESTING.md](TESTING.md)); the tools keep 100% line and branch coverage. A test may pass 12 lines only for a parametrization table or a fixture; test helpers follow the same naming and single responsibility rules.

## How `make check` enforces it

`make check` runs the device API audit, a type checked build (`make build`), `ruff` and `mypy --strict` on the tools, the tool tests at 100% coverage (`make test-tools`) and the strict function length gate. The simulator suite needs a running simulator, so it stays a separate step: `make sim`, then `make test`. CI runs the same gate in its static checks job.

* `make function-length-gate` fails when any production function passes 12 lines. There is no baseline and no exception list.
* `make function-length` prints the full report, longest first, without failing.
* Rule 1 arrived after the code was written, so the gate started as a ratchet over a baseline of the legacy long functions. Once the last of them was refactored, the ratchet and its baseline were removed and the gate became strict.

The checker lives in `tools/check_function_length.py`, with one measurer per language (`tools/function_length_python.py` through the `ast` module and `tools/function_length_monkeyc.py`, a string and comment aware brace scanner that qualifies names by module and class). The settings (limit, measured folders, languages and exclusions) live in `tools/function_length.json`. The tools run through `uv`, which installs Python 3.12 and the development dependencies from `pyproject.toml` on first use.
