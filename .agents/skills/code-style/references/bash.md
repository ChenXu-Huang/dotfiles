# Bash Style

## Applies to

Executable scripts whose shebang is `#!/usr/bin/env bash` or `#!/bin/bash`,
files named `*.sh` or `*.bash`, and the functions they source. This file does
not cover POSIX `sh` scripts or zsh-only files: a `#!/bin/sh` script may not
use anything here that `sh` lacks, and a zsh script is a different target with
its own rules.

## Source of truth

`shellcheck` (with `.shellcheckrc`), `shfmt` (with its flags and the
`.editorconfig` settings it reads), then this file. `shfmt` owns layout: run
it, do not hand-align what it would move.

The defaults below apply only where the project configures nothing.

## Formatting

- 2 spaces per indent level when nothing is configured; `shfmt`'s own default
  is tabs, so follow whatever the project's `.editorconfig` or flags say and
  keep it uniform across the repository.
- LF line endings, one final newline, no trailing whitespace. The shebang is
  line 1, and the file stays executable (`chmod +x`).
- Keep lines under 100 columns. Break long pipelines after `|` and long
  conditionals after `&&` / `||`, indenting the continuation.
- `; then` and `; do` stay on the opening line; `fi` and `done` sit on their own
  line, aligned with the keyword that opened the block.
- Quote every expansion: `"$var"`, `"${array[@]}"`, `"$(command)"`,
  `"${var:-default}"`. Leave an expansion unquoted only where word splitting is
  genuinely intended, with a comment saying so.
- Use `${var}` braces whenever the name butts against other text
  (`"${prefix}_suffix"`), and `--` before path arguments.
- One blank line between functions; no blank line right after `{` or right
  before `}`.

## Naming

| Element | Style |
| --- | --- |
| script file | `kebab-case.sh` or `snake_case.sh`, matching the repo |
| function | `snake_case` |
| local variable | `snake_case`, declared `local` |
| exported / environment / constant | `UPPER_SNAKE_CASE`, `readonly` where fixed |
| private helper | `_leading_underscore` |

- Never name a variable after a command or a special parameter (`PATH`, `PWD`,
  `IFS`, `$?`, `$!`, `test`, `[`); shadowing one silently breaks the script.
- Globals are `UPPER`; a `readonly` global states it is fixed after startup.
- Function names are verbs or verb phrases (`link_skills`, `usage`), not nouns
  (`skills`).
- Loop counters and throwaway locals get short names (`i`, `f`, `opt`); nothing
  else does.

## Structure and imports

- Layout, in order: shebang, a one-line purpose comment, the header block,
  `set -euo pipefail`, `readonly` constants, functions, then `main "$@"` as the
  last line.
- Keep top-level code to declarations. Everything that does work lives in a
  function, and `main` is the only thing the file calls at the end — this is
  what makes the script safe to source in a test.
- Write the usage line and exit codes into the header comment; keep it in step
  with the parser.
- Arguments: an explicit `usage()` that prints to stderr and exits non-zero,
  plus `getopts` for short options or a `while`-`case` loop for long ones.
  Validate required arguments and their readability before doing any work.
- `${1:?usage: script.sh <file>}` for a required positional argument gives a
  message and a non-zero exit in one line.
- Source a sibling helper by a path resolved once at the top
  (`readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"`),
  never by a bare relative path that breaks after a `cd`.
- Never `cd` inside a function without restoring the directory; prefer running
  the work in a subshell — `( cd -- "$dir" && make )`.
- Scripts are cross-platform unless the project says otherwise: prefer
  `command -v` over `which`, avoid GNU-only flags where a portable form exists,
  and keep macOS's older userland in mind.

## Types and annotations

- There is no type system; enforce with attributes and validation:
  `declare -r` / `readonly` for fixed values, `declare -i` for integers,
  `declare -a` for arrays, `declare -A` for associative arrays (bash 4+),
  `local -r` inside functions.
- `set -u` plus `${var:-default}` or `${var:?message}` is the null contract:
  no variable is assumed to be set, and the failure message names the variable.
- Validate untrusted input at the entry point with a `case` pattern or
  `[[ $x =~ ^[0-9]+$ ]]`, and fail with a message that shows the bad value.
- Document the interface in the header block: usage, arguments, environment
  variables read, files written, and exit codes.
- A function's contract is its comment: what it reads, what it echoes to
  stdout, and whether it exits the process. A function that can `exit` says so.
- Prefer the builtin test operators (`-f`, `-d`, `-r`, `-v`, `-z`, `-n`) over
  parsing `ls` or `test` output.

## Comments and documentation

- Every script starts with a header block: purpose (one line), usage, arguments,
  environment variables, side effects, and exit codes.
- Every non-trivial function gets a one-line comment above it saying what it
  does and what it prints.
- Comments explain why, above the command they explain; a comment restating the
  command below is noise.
- Mark deliberate deviations from these rules with a comment — an unquoted
  expansion, a `set +e` section, a `shellcheck disable=` — so the next reader
  knows it is intentional.
- Task tags `TODO(name):`, `NOTE:`, `FIXME:`; a `TODO` names an owner.
- No commented-out code.

## Error handling

- `set -euo pipefail` at the top of every script: `-e` exits on an unchecked
  failure, `-u` catches unset variables, `pipefail` catches a failure anywhere
  in a pipeline.
- A deliberate exception to `-e` is scoped and commented: `if ! cmd; then` for
  a specific command, or `set +e` / `set -e` around just that section.
- `trap 'cleanup' EXIT` for temporary files, locks, and partial output; also
  trap `INT` and `TERM` when a half-finished run would leave damage. Define
  `cleanup` before installing the trap, and make it idempotent.
- Errors go to stderr (`>&2`) and results go to stdout — a caller must be able
  to capture data without capturing diagnostics.
- Exit codes: `0` success, `1` for a general failure, `2` for a usage error,
  and distinct documented codes where the caller branches on them.
- Provide context in the failure message: which file, which command, what was
  expected — `echo "cannot read config: $path" >&2`.
- Work in `mktemp -d` scratch space removed by the trap; never a fixed name in
  `/tmp` or a temp file inside the source tree.
- Guard destructive commands: `rm -rf -- "${dir:?}"` and a check that the path
  is the expected one before deleting a tree.

## Idioms and anti-patterns

Prefer:

- `[[ ... ]]` for tests and `(( ... ))` for arithmetic, over `[ ... ]` and
  `expr`.
- `$(command)` over backticks, and `$(( ... ))` over `expr`.
- `printf` over `echo` for anything with a variable, an escape, or a leading
  `-`.
- `command -v tool >/dev/null` to test for a program.
- Arrays for lists: `files=("a b" "c"); for f in "${files[@]}"; do ...`.
- `while IFS= read -r line` for reading text, and
  `find ... -print0 | while IFS= read -r -d '' path` for filenames.
- Here-documents (`<<'EOF'`, delimiter quoted) for multi-line literals, so
  nothing in them expands.
- `read -r` always; `-p` for the prompt rather than a separate `echo`.
- Functions that print their result and return 0/1, so callers can use them in
  `if` and in `$(...)`.
- `local` for every function variable, declared at the top of the function.

Avoid:

- parsing `ls`; use globs or `find`.
- `for x in $(command)` — word splitting and globbing corrupt the values.
- `eval`, and commands assembled from untrusted strings.
- `cat file | command` when the command reads files itself.
- unquoted tests (`[ $x = y ]`), which break on empty and spaced values.
- `echo -e` / `echo -n`, which are not portable.
- `sudo` inside a script; the caller decides about privilege escalation.
- functions longer than a screen, and functions that both compute and `exit`.
- silently ignoring a failure with `|| true` where the error matters.
- `cd` without restoring, and relative paths built from `$PWD` assumptions.

## Tests

- `bats` (or `shellspec` when the project uses it), one test file per script,
  test names that state behavior.
- Use `run` and assert on `$status` and `$output` separately, so a failure says
  whether the exit code or the text was wrong.
- Create every fixture in a temporary directory the test removes, and point the
  script at it with environment variables or arguments — never at the real
  `$HOME`.
- A test may not touch the network, depend on the developer's installed tools
  beyond what it checks for, or rely on a fixed `/tmp` path.
- Cover the failure paths: missing argument, unreadable file, command absent,
  non-zero exit from a dependency.
- Every bug fix arrives with a test that fails without the fix.
- A `shellcheck`-clean script is the floor, not the goal.

## Tooling

- Before declaring work done: `shellcheck script.sh` and
  `shfmt -d script.sh` (or `shfmt -w` to write) both clean.
- `shellcheck disable=SC<code>` is narrowed to the line and always carries a
  reason; never disable a whole file to silence one finding.
- `bash -n script.sh` parses without running; `bash -x script.sh` (or
  `set -x` around a section) while debugging.
- Target the bash version the project pins. Bash 3.2 (macOS's `/bin/bash`) has
  no associative arrays (`declare -A`), no `mapfile`, and no `${var,,}` /
  `${var^^}` case conversion — do not use them in a script that must run there.
- When the project ships a CI job, run the same commands it runs, in the same
  order.

## Examples

Follows the rules — header block, strict mode, quoting, a function per job, and
a `main` that is the only top-level call:

```bash
#!/usr/bin/env bash
# Print the resolved skills directory used by the agent CLIs.
#
# Usage: skills-dir.sh [-f]
# Exit codes: 0 success, 2 usage error.

set -euo pipefail

readonly script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

usage() {
  printf 'usage: %s [-f]\n' "${0##*/}" >&2
}

main() {
  local force=0 opt
  while getopts ':f' opt; do
    case "$opt" in
      f) force=1 ;;
      *) usage; exit 2 ;;
    esac
  done
  printf '%s\n' "${script_dir}"
}

main "$@"
```

Breaks the rules — a `sh` shebang over bash habits, backticks, unquoted
expansions, `ls` parsing, a useless `cat`, and a `cd` that is never undone:

```bash
#!/bin/sh
files=`ls *.txt`
for f in $files; do
  cat $f | grep pattern
  cd /tmp
done
```

Why it is wrong: the shebang promises POSIX `sh` while the body relies on
bash-era habits; backticks are deprecated and nest badly; `$files` and `$f` are
unquoted, so a filename with a space becomes two; parsing `ls` breaks on odd
names; `cat` is redundant because `grep` reads files; `cd /tmp` changes the
directory for everything after it; and with no `set -euo pipefail` a failure
passes silently.
