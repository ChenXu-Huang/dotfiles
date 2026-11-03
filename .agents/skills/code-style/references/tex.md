# TeX Style

## Applies to

`.tex`, `.sty`, and `.cls` sources. `.bib` databases are BibTeX, not TeX, and are not covered.

## Source of truth

`.editorconfig`, then any TeX formatter or linter the project configures (`tex-fmt`, `latexindent`, `chktex`), then `AGENTS.md`, then this file.

## Formatting

- Write each prose paragraph as one source line, with a blank line between paragraphs. Do not insert line breaks to stay under a column width; the editor soft-wraps for display.
- Do not use the one-sentence-per-line convention: a paragraph is one line, not one sentence per line.
- Never use `$...$` or `$$...$$` as math delimiters. Write inline math as `\(...\)`, display math as `\[...\]`, and use `\begin{equation}...\end{equation}` or another environment (`align`, `gather`, `multline`) when the math is numbered, aligned, or labeled; write a literal dollar sign as `\$` in text, or leave it inside verbatim-like content.
- Write the differential `d` as `\mathrm{d}`, separated from a preceding expression by `\,`: `\int x \, \mathrm{d}x` and `\frac{\mathrm{d}y}{\mathrm{d}x}`, never `\int x dx` or `\frac{dy}{dx}`.
- `verbatim`, `lstlisting`, `minted`, `tabular`/`tabularx`/`longtable` rows, and display-math environments keep their own line structure; never reflow them.
- `.editorconfig`'s `max_line_length` governs code-like lines, not prose; a paragraph may exceed it.
- UTF-8, LF line endings, one final newline, no trailing whitespace.

## Naming

No additional rules; follow the project configuration and the surrounding code.

## Structure and imports

- Do not put numbers inside `\chapter{}`, `\section{}`, `\subsection{}`, or similar title arguments: `\section{1.1 Background}` is wrong; write `\section{Background}` and let LaTeX counters number it. Use `\setcounter{...}` to control where numbering starts and the starred forms (`\section*{...}`) for unnumbered headings.

## Types and annotations

No additional rules; follow the project configuration and the surrounding code.

## Comments and documentation

No additional rules; follow the project configuration and the surrounding code.

## Error handling

No additional rules; follow the project configuration and the surrounding code.

## Idioms and anti-patterns

Prefer:

- Blank lines between paragraphs.
- One paragraph per source line, with the editor doing the visual wrapping.
- `\(...\)` for inline math, `\[...\]` for display math, and a numbered environment when the math needs a number or label.

Avoid:

- `\\` as a paragraph break; a blank line is the paragraph break.
- Hard-wrapping prose at a column; the next edit has to reflow it.
- One sentence per line when the project wants paragraphs unwrapped.
- `$...$` and `$$...$$` as math delimiters, including for a single symbol.

## Tests

No additional rules; follow the project configuration and the surrounding code.

## Tooling

- If `tex-fmt` or `latexindent` is configured, run it for indentation and spacing only; confirm it does not reflow paragraphs, and skip it for prose when it does.
- `chktex` is a linter, not a formatter; fix its findings instead of disabling them.

## Examples

Follows the rules — one source line for the paragraph, a blank line before the next:

```tex
This paragraph is written as one source line even though it is long enough that the editor displays it across several visual rows.

The next paragraph starts after a blank line.
```

Breaks the rules — manual line breaks inside a paragraph:

```tex
This paragraph is
hard-wrapped at a fixed
column.
```

TeX treats those line breaks as spaces, so the paragraph renders the same; the cost is that every edit has to rewrap the source.
