<!--
Template for one language's style rules. Copy this file to
`references/<language>.md` using the lowercase language name, replace every
placeholder, and delete every HTML comment — both this header block and the
per-section placeholders.

Rules for the file you are about to write:

- It covers exactly one language and is readable on its own: never mention,
  link to, or compare with another language's reference file.
- Keep the section names and their order exactly as below.
- Never leave a section empty — write "No additional rules; follow the project
  configuration and the surrounding code." when the language has nothing to say
  there.
- Every rule is concrete enough to check: a number, a name pattern, an example,
  or a named tool. "Write clean code" is not a rule.
- Code samples are welcome here and must be written in this language.
- Stay under roughly 300 lines. When the rules outgrow one readable file, use
  the split mechanism `SKILL.md` describes — a `references/<language>/`
  directory of numbered files — instead of letting this file grow.
- Add the language to the index table in `SKILL.md` when the file is done.
-->

# <Language> Style

## Applies to

<!-- Which files this covers (extensions, shebang, manifests) and which nearby
files it deliberately does not cover. -->

## Source of truth

<!-- The configuration files that win over this one, in order, and the formatter
and linter that own layout and diagnostics. State what this file defaults to
when the project configures nothing, and state that the project's agent
instructions (`AGENTS.md`, `CLAUDE.md`, and the like) sit above this file too. -->

## Formatting

<!-- Indentation, line length, quoting, blank lines, line endings, file ending,
trailing commas, and who owns the layout. -->

## Naming

<!-- A table of element -> style (files, functions, variables, constants, types,
private markers), plus the naming rules that are easy to get wrong. -->

## Structure and imports

<!-- File layout, import/require/sourcing order, module boundaries, what is
exported, what stays private. -->

## Types and annotations

<!-- The language's type system or its substitute: annotations, guards,
validation at boundaries, optional/null handling. -->

## Comments and documentation

<!-- What is documented (public surface vs internals), the doc comment form and
its sections, when a comment is warranted, task tags, commented-out code. -->

## Error handling

<!-- Raising vs returning, error types and messages, context and chaining,
what must never be swallowed silently, exit codes, cleanup. -->

## Idioms and anti-patterns

<!-- Two lists: what to prefer, and what to avoid, each with the reason. -->

## Tests

<!-- The runner, file and test naming, what to assert, what a test may never
depend on, and what every bug fix must bring with it. -->

## Tooling

<!-- The exact commands to run before declaring work done, the version or
platform the code targets, and the syntax that version rules out. -->

## Examples

<!-- One short example that follows the rules and one that breaks them, with the
reasons spelled out. -->
