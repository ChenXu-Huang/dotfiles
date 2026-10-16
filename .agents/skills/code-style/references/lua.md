# Lua Style

## Applies to

`.lua` files, and `.luau` when the project uses Luau. Files that configure
another program in Lua are still Lua files: the conventions of the configured
tool sit on top of these rules, they do not replace them.

## Source of truth

`stylua.toml` or `.stylua.toml`, `.luacheckrc`, `.editorconfig`, then this
file. StyLua owns layout: write the code, run the formatter, and never
hand-align anything it would move.

The defaults below apply only where the project configures nothing.

## Formatting

- 2 spaces per indent level, never tabs. LF line endings, one final newline, no
  trailing whitespace.
- 120 columns, StyLua's default; the project's `column_width` wins.
- Double quotes for strings. Long strings (`[[...]]`) for multi-line text;
  a leading newline in a long string is usually a bug, so open the bracket on
  the same line as the text it starts or trim it deliberately.
- No semicolons, except when two statements must share a line — which should
  not happen.
- A space after `--` in comments (`-- like this`), and a blank line between
  function definitions. No blank line right after `function` or right before
  `end`.
- Keep parentheses around call arguments, but a single string or table literal
  may drop them, as the language intends: `require "mod"`, `setup { opt = 1 }`.
- Tables with more than one field are laid out one field per line, with a
  trailing comma-free last entry; short literal tables stay on one line.

## Naming

| Element | Style |
| --- | --- |
| file, module | `snake_case` |
| variable, function, field | `snake_case` |
| class / constructor table | `PascalCase` |
| constant | `UPPER_SNAKE_CASE` |
| private field or helper | `_leading_underscore` |
| unused value | `_` |

- Short names are fine for a local that lives three lines (`i`, `ok`), but every
  module-level or exported name is spelled out.
- Boolean names read as predicates: `is_ready`, `has_value`, never
  `not_ready`.
- A function that mutates its argument says so in its name or doc comment
  (`sort_in_place`, `apply!` where the codebase uses the bang convention —
  pick one convention per project and keep it).
- Never shadow a standard library name (`table`, `string`, `os`, `type`,
  `next`, `select`); a lost stdlib function is hard to notice.

## Structure and imports

- Everything is `local`. A global is a deliberate, documented exception.
- Declare locals at the top of their scope, one per line, before first use —
  inside a long function, declare each where it is first needed rather than
  scattering assignments that silently create globals.
- `require` at the top of the file as `local name = require("module")`; never
  inside a loop or a hot path.
- A module returns exactly one value as its last statement: `return M` for a
  table module built up through the file, or a single table constructor when
  the module is pure data. No side effects on require beyond building that
  value.
- Keep dependencies pointing one way. When two modules need each other, pass
  the collaborator in as a parameter instead of requiring it in both.
- Never monkey-patch the standard library or another module's table.
- Deep nesting is a design smell: extract a helper rather than indenting past
  three levels.

## Types and annotations

- Lua has no runtime type system. When the project runs a language server,
  annotate with LuaLS/EmmyLua comments: `---@class`, `---@field`,
  `---@param name type`, `---@return type`, `---@type`.
- Annotate the public surface — module tables, classes and their fields,
  function parameters and returns — and any value that may be `nil`.
- Mark optional values `type?`. A function that can return nothing says so
  (`---@return string|nil value`) instead of leaving callers to guess.
- Enforce what matters at runtime: `assert(value, "message")` for programmer
  errors at a boundary, `type(x) == "string"` for input you do not control.
- Keep a `---@class` definition next to the constructor that builds instances,
  so the fields and their types are stated in one place.

## Comments and documentation

- `---` (three dashes) directly above a declaration documents that symbol for
  the language server; `--` is a plain comment. Do not mix them up.
- The summary is a short imperative phrase in the voice of the surrounding
  code; it says what the function does, not how.
- Plain comments explain why, above the code they explain, and never restate
  the statement below.
- Document the units, the expected range, and the side effects of a function
  that mutates state or writes to disk.
- Task tags `TODO(name):`, `NOTE:`, `FIXME:` where the project uses them; a
  `TODO` names an owner.
- No commented-out code.

## Error handling

- `error(message)` for programmer errors and violated invariants; add a level
  (`error(message, 2)`) in a helper so the report points at the caller, not at
  the helper.
- `pcall`/`xpcall` only where failure is expected and recoverable — loading
  user configuration, calling into an optional dependency. A `pcall` that
  nobody inspects is a silent failure; check the status before touching the
  results.
- Library code returns `nil, err` for expected failures and reserves `error`
  for bugs. Never use both for the same class of failure in one module.
- Error messages name the value and the expectation:
  `("expected a table for opts, got " .. type(opts))`.
- `assert` for preconditions at module boundaries; it is a `error` with a
  message, so do not write a manual `if not x then error(...) end` for the same
  purpose.
- Clean up in the reverse order of acquisition, and release resources even on
  the failure path — a `pcall` around the body plus cleanup after it, or an
  explicit `xpcall` handler.
- Never `os.exit` deep inside library code; return the failure and let the
  entry point decide.

## Idioms and anti-patterns

Prefer:

- `local` for every binding, `==` and `~=`, `#t` for a sequence length,
  `ipairs` for arrays, `pairs` for maps.
- Appending with `t[#t + 1] = v`, and `table.remove(t)` for the tail; `table.insert`
  when its clarity is worth the extra call.
- Early returns over nested `if` blocks.
- `table.concat(parts)` for building a string from many pieces.
- Named fields for anything with more than two fields, so call sites read.
- A single `return` of a table for a public module, with private helpers as
  file-local functions above it.
- `vim.tbl_deep_extend`, `vim.tbl_contains`, and friends where the runtime
  provides them, instead of hand-rolled recursion.

Avoid:

- accidental globals: a typo'd assignment creates one silently, so run a linter
  or a strict-mode check that reports them.
- mutating a table while iterating it with `pairs`; collect the keys first.
- string concatenation inside a loop.
- `and`/`or` chains as a substitute for a real conditional once more than two
  values are involved (`a and b or c` breaks on `false`).
- `nil` vs `false` confusion: a missing key and a `false` value are different,
  and `if x then` cannot tell them apart — compare against `nil` explicitly
  when the distinction matters.
- catching a failure and returning a default that hides it.
- deep copies of large tables on every call; pass them, or cache the copy.
- `os.execute` and other shell-outs where a library API exists.

## Tests

- Use the project's runner — `busted`, a `plenary.nvim`-style harness, or
  `mini.test` — with one file per module under test.
- One `describe` per unit, `it` names that state behavior and expected result.
- Test pure functions with plain assertions; anything touching the filesystem,
  the editor, or a socket gets an injected fake or a temporary directory it
  created and removes.
- A test may not depend on `pairs` iteration order (it is unspecified), on
  global state another test left behind, on wall-clock time, or on the user's
  real configuration directory.
- Every bug fix arrives with a test that fails without the fix.
- Keep an assertion helper (`assert.are.same`, `assert.equals`) rather than
  hand-rolled comparisons that print nothing useful on failure.

## Tooling

- `stylua .` to format and `luacheck .` (or the project's linter) to lint —
  both clean before declaring work done.
- Fix a lint finding instead of disabling it; when a disable is genuinely
  needed, narrow it to the line and say why.
- Target the Lua version the project runs: 5.1 / LuaJIT accepts no integer
  division (`//`), no bitwise operators (outside LuaJIT's `bit` library), and
  no `goto`; 5.2+ adds `goto`, 5.3+ adds integers and bitwise operators.
- When the project ships a `.luarc.json`, keep it in step with any new global
  or runtime API the code starts using.

## Examples

Follows the rules — module table, annotation, assertion at the boundary, and an
explicit `nil` for a missing value:

```lua
local M = {}

--- Resolve the install directory of a plugin by name.
---@param name string Plugin name as written in its spec.
---@return string|nil path Absolute path, or nil when the plugin is absent.
function M.path_of(name)
  assert(type(name) == "string", "name must be a string")
  local root = vim.fn.stdpath("data") .. "/lazy"
  local path = root .. "/" .. name
  if vim.fn.isdirectory(path) == 0 then
    return nil
  end
  return path
end

return M
```

Breaks the rules — globals by accident, camelCase, a `pcall` nobody checks, and
a return value that may be the error object:

```lua
function getPath(n)
  path = "/tmp/" .. n
  local ok, res = pcall(function() return read(path) end)
  return res
end
```

Why it is wrong: `getPath` and `path` are globals created by omission;
`camelCase` breaks the file's naming; `ok` is never inspected, so a failure
returns whatever `pcall` produced as if it were data; and the missing
annotation leaves callers to discover `nil` on their own.
