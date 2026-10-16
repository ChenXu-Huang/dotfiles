---
name: code-style
description: Per-language code style rules for Python, Lua, PowerShell, and Bash. Use when writing, reviewing, refactoring, or reformatting source files in one of those languages; when asked about naming, docstrings, comments, imports, formatting, or lint conventions; or when adding style rules for another language. Dispatches to one self-contained file per language so the rules never mix.
---

# Code Style

Binding style rules for the languages this skill covers, one self-contained
file per language. A language's rules live in exactly one file, and that file
is readable on its own: this router deliberately states no style rule for any
language and contains no code sample.

## Workflow

### Step 1: Determine the languages in play

Go by the files actually being written, edited, or reviewed in this task, from
their extension or shebang — not by what the repository happens to contain. A
task that touches only Python files is a Python task even when the repository
also holds Lua and shell scripts.

When a task spans several languages (a Python module plus the shell script that
runs it), treat each one separately in the steps below.

### Step 2: Load one file per language

Read one file per language in play and nothing more:

- Never list or glob the `references/` directory, never read a reference file
  for a language the task does not touch, and never read a second language file
  "for comparison".
- Never read a file under `references/` that the index does not list — with one
  exception: when the index points at a split language's entry file, the files
  that entry file names belong to that language too, and may be read.
- Reuse what is already in context: when a language's rules were loaded earlier
  in the session, work from them instead of reading the file again.
- When the task brings in another language, load that language's file — again
  only that one.

### Step 3: Apply the precedence order

Highest wins, and nothing higher up is ever overridden by this skill:

1. The project's own tool configuration — formatter, linter, and editor config
   files, whatever the language uses.
2. The project's agent instructions (`AGENTS.md`, `CLAUDE.md`) and its
   language-specific documentation.
3. The language's reference file under `references/`.
4. Fallback: when none of the above covers a case, follow the prevailing
   convention of the surrounding code.

This skill never overrides a repository's formatter or linter configuration,
and never asks for a reformat that the project's own tooling would undo.

### Step 4: Honor the isolation contract

These rules keep the per-language files independent, and they are hard:

- Every file under `references/` covers exactly one language and is complete on
  its own. Nothing in it depends on, defers to, or links to another reference
  file.
- Never carry a rule from one language into another because the two look
  similar — indent width, line length, quote style, and naming conventions are
  per-language facts, not shared defaults.
- A language with no reference file has no rules here. Say so plainly, follow
  the project's configuration and that language's own prevailing convention,
  and do not substitute another language's rules. Offer to add a file for it.
- New rules go into the reference file of the language they belong to, never
  into this router.

## Reference index

| Language | Reference file | Applies to |
| --- | --- | --- |
| Python | `references/python.md` | `.py`, `.pyi` |
| Lua | `references/lua.md` | `.lua`, `.luau` |
| PowerShell | `references/powershell.md` | `.ps1`, `.psm1`, `.psd1` |
| Bash | `references/bash.md` | `.sh`, `.bash`, bash shebang scripts |

Every file under `references/` appears in this table, and every file this table
names exists.

## Adding a language

Copy `assets/language-template.md` to `references/<language>.md`, using the
lowercase language name, fill in every section, and add the row to the index.
The template's section names and their order are what the files here follow, so
a reader always finds the same topics in the same order. Keep the new file
self-contained: it may not reference another language's file, and it may not
assume this router states a rule that it does not.

When one language's rules outgrow a single readable file, split them into a
`references/<language>/` directory of numbered files — that directory is that
language's namespace, its entry file keeps the language's name, the index row
then points at the entry file, and that entry file is the one Step 2 loads for
the language. Files belonging to different languages never share a directory.

## Do NOT

- Put a style rule, a formatting default, or a code sample for any language in
  this file
- Load a reference file that a language in play does not own
- Link reference files to each other, or phrase a rule in terms of another
  language
- Apply one language's rule to another because the two are similar
- Override the project's formatter, linter, or editor configuration
- Invent rules for a language that has no reference file
