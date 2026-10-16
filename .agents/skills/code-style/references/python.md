# Python Style

## Applies to

`.py` files and `.pyi` stubs. Notebooks (`.ipynb`), `setup.py` build shims, and
generated code are out of scope unless the project says otherwise; generated
files are never reformatted by hand.

## Source of truth

The project's configuration wins over everything below, in this order:
`pyproject.toml` (`[tool.ruff]`, `[tool.ruff.lint]`, `[tool.ruff.format]`),
`ruff.toml` or `.ruff.toml`, `setup.cfg` / `.flake8`, `.editorconfig`, then
this file.

Never argue with a configured rule. When a rule genuinely does not fit, disable
it for the single line with `# noqa: <code>` and a short reason — never a
blanket `# noqa`, never a project-wide ignore added for one awkward site.

The defaults below assume ruff with these families: E, F, W, I, UP, B, SIM, C4,
and RUF, plus T20 (stray `print`), PT (pytest style), COM (trailing commas when
the formatter does not add them), and LOG (logging). They apply only where the
project configures nothing.

## Formatting

- 4 spaces per indent level, never tabs. LF line endings, one final newline, no
  trailing whitespace.
- 88 columns, ruff's default; keep inside it unless the project widens it.
- Double quotes for strings; let the formatter normalize them. Implicit string
  concatenation only inside brackets.
- One statement per line, no semicolons. Two blank lines between top-level
  definitions, one between methods.
- Trailing commas in multi-line collections and argument lists — they keep the
  formatter from collapsing the block later.
- Let the formatter own layout (`ruff format`, or `black` if the project uses
  it). Write the code, run the formatter, never hand-align or fight it.

## Naming

| Element | Style |
| --- | --- |
| module, package | `snake_case`, short |
| function, method, variable | `snake_case` |
| class, exception, `TypedDict`, enum | `PascalCase` |
| module constant, `Final` value | `UPPER_SNAKE_CASE` |
| type alias, `TypeVar` | `PascalCase` |
| private / internal | single leading underscore |
| dunder | only the ones the language defines |

- Names state what the value is, not its type: `elapsed_seconds`, not `secs2`
  or `float_list`.
- A `TypeVar` keeps the short conventional name (`T`, `KT`, `VT`, `T_co`) that
  PEP 8 itself uses; do not expand one into a prose name.
- Class-level tuning knobs are class-bound constants read as `cls._NAME`, not
  module globals and not repeated literals.
- Boolean names read as predicates (`is_frozen`, `has_children`); avoid
  negatives (`is_not_ready`).
- A trailing underscore is for a real shadowing conflict (`id_`, `type_`), not
  for taste.
- Exceptions end in `Error` and say what went wrong (`UnsupportedSolverError`).

## Structure and imports

- One import per line; `import x` for packages, `from x import y` for members.
- Absolute imports. Relative imports only inside a package that already uses
  them.
- Never `from x import *`.
- Group and order: standard library, third-party, first-party — blank line
  between groups, alphabetical inside each. The linter's `I` rules own this.
- Keep import time cheap: import heavy or optional dependencies inside the
  function that needs them, and never let a module-level import pull in an
  optional dependency.
- Re-export deliberately, through an explicit `__all__`.
- A module has one job; when its name needs "and" to describe it, it is two
  modules.

## Types and annotations

- Annotate every public function, method, and class attribute — parameters and
  return. A function that returns nothing says `-> None`.
- Builtin generics: `list[int]`, `dict[str, int]`, `tuple[int, ...]`. Optional
  is `X | None`, never `Optional[X]` — on a pin below 3.10, put
  `from __future__ import annotations` at the top of the module.
- Annotate a local only when inference fails or the annotation is the
  documentation.
- Prefer `Protocol` and `Callable[[int], str]` over `Any`. Every surviving
  `Any` is a deliberate hole; note why where a reader would trip over it.
- A repeated shape becomes a `dataclass`, `TypedDict`, or `NamedTuple` —
  frozen when the value is a value — not a bare dict or a positional tuple.
- `Final` for module constants, `ClassVar` for class-level state that is not a
  field; a class-bound constant is `ClassVar` plus the naming rule's
  `cls._NAME`, never a bare class attribute.
- `NewType`/`TypeAlias` when a plain `str` or `int` carries a meaning the type
  cannot enforce.

## Comments and documentation

- Every public module, class, function, and method carries a docstring. Google
  style with `Args:`, `Returns:`, and `Raises:` sections, omitting any section
  that does not apply.
- The summary line is imperative and ends with a period: "Build the
  relaxation.", not "Builds" or "Building".
- Document behavior and constraints, not the signature: what a value means,
  valid ranges, side effects, and what is raised and when.
- `Raises:` lists the exceptions a caller can act on, not the `TypeError` that
  a wrong signature already produces.
- Modules document what the module is for; classes document invariants and the
  meaning of their fields.
- Plain comments explain why, above the code they explain, and never restate
  the line below.
- Task tags: `TODO(username):`, `NOTE:`, `FIXME:`. A `TODO` always names an
  owner so it can be found and assigned.
- No commented-out code — version control is what it is for.

## Error handling

- Raise the most specific exception that fits: a builtin (`ValueError`,
  `TypeError`, `LookupError`) or a project type.
- Keep the cause: `raise RuntimeError("...") from exc` when translating a
  lower-level failure, and never translate an exception just to change its
  type.
- `except` names the exception it handles. A bare `except:` or
  `except Exception:` belongs only at a process boundary (a CLI entry point, a
  worker loop), and says why in a comment.
- Never swallow silently: a caught exception is logged, re-raised, or
  documented as intentionally ignored.
- Validate arguments where the check is cheap and the message can be specific;
  do not re-validate what the type system and the caller already guarantee.
- Exceptions over sentinel return values. Returning `None` for "not found" is
  fine when the caller's first act is an existence check.
- No mutable default arguments (`def f(items=[])`): use `None` plus a local, or
  `dataclasses.field(default_factory=...)`.
- Clean up with `with`, `contextlib`, or `try/finally`; never rely on garbage
  collection for a file, socket, lock, or subprocess.

## Idioms and anti-patterns

Prefer:

- comprehensions and generator expressions for one simple transform; a loop as
  soon as the body branches, mutates, or does more than one thing.
- `dataclasses` and `enum` over ad-hoc dicts and string constants.
- `pathlib.Path` over `os.path` string surgery.
- f-strings for formatting, and `logging` — a module-level
  `logger = logging.getLogger(__name__)` — instead of `print` in library code.
- `enumerate`, `zip`, and `itertools` over index arithmetic.
- keyword-only arguments (`*`) and defaults for options that would otherwise
  be positional booleans.
- `collections.abc` types in annotations (`Iterable`, `Mapping`, `Sequence`)
  for parameters that only read.

Avoid:

- mutable module-level state, and caches with no documented invalidation rule.
- mutating a container argument in place unless the name and the docstring say
  so.
- returning a `bool` to signal failure, or a growing positional tuple once
  callers start indexing it.
- catching an exception only to re-raise the same type unchanged.
- `random` in production paths, and tests that depend on RNG state.
- isinstance chains where a `Protocol`, a method, or a registry does the job.
- `print` debugging left behind as the only diagnostics.

## Tests

- pytest under `tests/`, one module per unit under test, functions named
  `test_<behavior>`.
- Assert behavior, not implementation. One logical assertion per test, worded
  so a failure says what was expected.
- Parametrize near-identical tests instead of copying them; keep shared setup
  in fixtures and cross-module fixtures in `conftest.py`.
- Compare floats with the project's tolerance (`pytest.approx` or an explicit
  `abs(a - b) < tol`), never `==` on a computed float.
- A test may not depend on the order of a `set` or `dict` it did not build, on
  wall-clock time, on RNG state, on the network, or on the developer's
  environment; inject or freeze what it needs.
- Every bug fix arrives with a test that fails without the fix.
- Keep the suite deterministic and independent of execution order.

## Tooling

- Prefer `uv` for every environment and dependency operation, unless the
  project already commits to another manager (Poetry, PDM, a plain
  `requirements.txt`) — then use that one and leave `uv` out of it.
- `uv run <command>` executes inside the project environment without
  activating anything by hand: the suite through `uv run pytest` (`-q` while
  iterating), the linter and formatter through `uv run ruff check .` and
  `uv run ruff format .`, or whatever the project configures, before declaring
  work done.
- `uvx <tool>` runs a tool the project does not depend on; never install a
  one-off tool into the project environment.
- Dependency changes are the user's call: `uv add`, `uv remove`, `uv lock`,
  `uv sync`, and `uv python install` run when the user asks for them, or after
  the user grants the escalation — never on your own initiative. Never
  hand-edit `pyproject.toml` or `uv.lock`, and never run `pip install` into an
  environment `uv` manages.
- `python -W error -c "import <package>"` when a lazy-import invariant must be
  proven, rather than trusting the code by eye.
- Write for the version the project pins; do not use newer syntax than the pin
  allows, and do not carry compatibility shims the pin makes unnecessary.
- uv's storage belongs in its global location: it is shared across projects and
  already warm, so never relocate `UV_CACHE_DIR`, `UV_PYTHON_INSTALL_DIR`, or
  `UV_TOOL_DIR` in `pyproject.toml`, a `.env`, or a shell profile to make
  sandboxed work easier.
- A run that changes no dependency can still need that cache: a build step or
  an environment refresh makes `uv run pytest` or `uv run main.py` fail under a
  sandbox with nothing to add or remove. Try the flag that skips the write
  first (`uv run --no-sync`, `uv run --frozen`); when that is not enough, set
  `UV_CACHE_DIR` to `./temp/uv-cache` — created first — for that single
  command, and say you did. That override is temporary and per-process: not
  exported to the commands that follow, never persisted, and never a route to a
  dependency change, which the user runs or escalates.
- Assume the network is gated. A `uv run` whose environment is not built yet
  downloads like any sync does: announce it and let the user run it or grant
  the escalation, never start a download unannounced, and never retry a denied
  command in a loop.

## Examples

Follows the rules — annotated, documented, immutable, and explicit about its
error:

```python
from dataclasses import dataclass, replace


@dataclass(frozen=True)
class SolverSettings:
    """Tuning knobs for a single solve.

    Attributes:
        tolerance: Relative gap below which a solve counts as converged.
        max_iterations: Iteration cap, or None for no cap.
    """

    tolerance: float = 1e-5
    max_iterations: int | None = None

    def with_tolerance(self, tolerance: float) -> "SolverSettings":
        """Return a copy of these settings with a different tolerance.

        Args:
            tolerance: New relative gap, which must be greater than zero.

        Returns:
            A settings object with the new tolerance; this one is unchanged.

        Raises:
            ValueError: If tolerance is not positive.
        """
        if tolerance <= 0:
            raise ValueError(f"tolerance must be positive, got {tolerance}")
        return replace(self, tolerance=tolerance)
```

Breaks the rules — mutable default, untyped, undocumented, and a bare `except`
that turns every failure into a silent `None`:

```python
def solve(p, opts={}):
    try:
        r = do_solve(p, opts)
        print("done", r)
        return r
    except:
        return None
```

Why it is wrong: `opts={}` is a mutable default shared across calls; nothing is
annotated; there is no docstring, so the failure modes are invisible; `print`
replaces a logger; and the bare `except` makes a real bug look like "no
result".
