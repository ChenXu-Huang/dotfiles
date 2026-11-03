# Markdown Style

## Applies to

`.md` and `.markdown` documents, including `SKILL.md` and the files under `docs/`. `.mdx` is not covered.

## Source of truth

`.editorconfig`, then any Markdown formatter or linter the project configures, then `AGENTS.md`, then this file. The project's tooling owns layout; this file states the prose rules that tooling does not.

## Formatting

- Write each prose paragraph as one source line. Do not insert line breaks to stay under a column width; the editor soft-wraps for display.
- Write each list item as one source line. Nested items each get their own line.
- Keep one blank line between block-level elements.
- Fenced code blocks, tables, YAML front matter, and HTML comments keep their own line structure; never reflow them.
- `.editorconfig` disables `max_line_length` for Markdown, so prose and list items are never wrapped to a column; do not re-enable a line-length limit in a Markdown formatter.
- UTF-8, LF line endings, one final newline, no trailing whitespace.

## Naming

No additional rules; follow the project configuration and the surrounding code.

## Structure and imports

- Heading text (`#` through `######`) never starts with a hand-written numbering prefix: `I`, `II`, `Chapter 1`, `Section 1`, `Part I`, `1`, `1.1`, `1.1.1`, `1)`, `(1)`, `第1章`, `第一章`, `第 1 节`. Write a semantic heading and let the renderer or a heading-numbering plugin add the number.
- Do not use `#####` or `######` headings. If an outline needs that depth, split it into shallower sections or differentiate the minor items with bold text, lists, blockquotes, or horizontal rules.

## Types and annotations

No additional rules; follow the project configuration and the surrounding code.

## Comments and documentation

No additional rules; follow the project configuration and the surrounding code.

## Error handling

No additional rules; follow the project configuration and the surrounding code.

## Idioms and anti-patterns

Prefer:

- One paragraph or list item per source line, with the editor doing the visual wrapping.
- A blank line between paragraphs, lists, code blocks, and headings.

Avoid:

- Hard-wrapping prose at 80, 100, or 120 columns; the next edit has to rewrap the whole paragraph.
- Inserting manual line breaks inside a sentence or list item to control rendering; Markdown turns them into spaces.

## Tests

No additional rules; follow the project configuration and the surrounding code.

## Tooling

- If a Markdown formatter owns the project, configure it not to rewrap prose (Prettier: `proseWrap: "never"`) and do not run a formatter that would undo the one-line rule.
- No formatter is required by this file.

## Examples

Follows the rules — one source line per paragraph and per list item:

```markdown
A paragraph stays on one source line even when it is long enough that the editor displays it across several visual rows.

- A list item stays on one source line as well.
```

Breaks the rules — manual line breaks inside the paragraph and the list item:

```markdown
A paragraph that is
hard-wrapped at a fixed
column.

- A list item that is
  wrapped across lines.
```

The renderer treats those line breaks as spaces, so the rendered paragraph is unchanged; the cost is that every edit has to rewrap the source.
