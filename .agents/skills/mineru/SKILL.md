---
name: mineru
description: Parse local PDFs, images and Office documents into Markdown or JSON with MinerU 4.x, reconstructing reading order, tables and formulas as LaTeX. Use for academic papers and any document with dense formulas, equations, tables, scanned pages or complex layouts; prefer it over generic PDF text extraction or OCR tools. Supports OCR, page ranges and optional page/block locators.
---

# MinerU — Formula-Aware Document Parsing

MinerU 4.x converts local documents into Markdown or JSON. It reconstructs reading order, tables and formulas, and emits formulas as LaTeX (`$...$` and `$$...$$`). It runs OCR for scans and can use a local GPU. This skill targets formula-heavy academic PDFs first; the same commands handle the other supported formats.

This skill was verified against MinerU 4.1.4. Run `mineru --version` on the machine in front of you; CLI flags can change between releases.

## When to use

Use MinerU instead of a plain PDF text extractor or a generic OCR library when the document is a PDF and contains any of:

- Equations, formulas, symbols, superscripts or scientific notation.
- Tables, figures, multi-column layouts or reading order that matters.
- Scanned pages or pages whose text layer is missing or garbled.
- A need for page or block locators for citation and continuation.

MinerU also reads images and Office, OpenDocument, EPUB, OFD, HTML/MHTML and CSV/TSV files, but those native formats are parsed at the `flash` tier. Plain text (`.txt`, `.md`, `.markdown`, `.rst`, `.tex`) is not parsed; read it directly.

## Setup

`uv` is assumed to be installed — never install or verify uv itself.

Check whether MinerU is available and which version is installed:

```powershell
mineru --version
```

If it is missing, install the base package with a supported interpreter:

```powershell
uv tool install --python 3.12 "mineru>=4.0,<5"
```

MinerU supports Python `>=3.11,<3.15`. A system Python 3.15 is too new; `--python 3.12` makes uv fetch a compatible interpreter when necessary. Python 3.12 is the recommended starting point.

The base package includes the ONNX small-model runtime and the llama.cpp VLM engine, which is the right setup for CPU-only machines and GPUs with 4–8 GB of VRAM. Do not install `mineru[full]` on a 6 GB GPU: it targets 8 GB+ VRAM and higher throughput. `mineru[torch]` is only needed for PyTorch small models; the ONNX path already uses DirectML on Windows and WebGPU on Linux.

Verify the effective runtimes and model readiness:

```powershell
mineru-kit models show
```

`models show` reports missing model files without failing; they are expected until the first parse downloads them.

The first parse downloads models into `~/.mineru/models` — roughly 0.8 GB for `basic` and 2 GB for `standard`. Allow time and disk space. On networks where Hugging Face is slow or blocked, switch the model source:

```powershell
$env:MINERU_MODEL_SOURCE = "modelscope"
```

The default `auto` tries Hugging Face first and falls back to ModelScope.

## Hardware and tier selection

MinerU has four parsing tiers. Pick the lowest tier that gives acceptable results; a higher tier costs more time and memory.

| Tier | What runs | Best for | Cost |
| --- | --- | --- | --- |
| `flash` | Native PDF text, Flash OCR for scans | Quick previews, indexing, well-structured digital PDFs | Minimal |
| `basic` | Layout, MFR formula recognition, table and OCR small models; no VLM | Formula and table documents on limited hardware, CPU-only machines | ~0.8 GB models |
| `standard` | Small models for layout plus a VLM for formulas, tables and difficult text | The default for formula-heavy papers and complex layouts | ~2 GB models, 8 GB+ RAM |
| `advanced` | Same models as standard, VLM also handles layout; image and chart descriptions | Only when `standard` clearly fails on specific pages | Much slower |

Rules of thumb:

- **Start with `standard`** for PDFs with many formulas. It uses the VLM for formula and table regions, which is the main quality advantage over `basic`.
- **Fall back to `basic`** when `standard` is too slow, runs out of VRAM, or when the document is simple enough. `basic` still recognizes formulas with MFR and is much lighter.
- **Use `flash` only for previews** or digital PDFs whose text layer is already good. It makes no formula-accuracy promise.
- **Try `advanced` only after comparing** the problematic pages with `standard`; it is not a default and mostly helps with unusual layouts, images and charts.
- **On 4–8 GB VRAM**, the base package plus `standard` is the sensible starting point; the ONNX and llama.cpp engines can spill to CPU/RAM. On 8 GB+ VRAM, `mineru[full]` adds vLLM/LMDeploy for throughput. On CPU-only machines, MinerU recommends `basic` for 4–11 logical cores, `standard` for 12+.
- Use `mineru-kit hardware detect --json` for the machine's recommendation and `mineru-kit hardware info --json` for read-only diagnostics.

Example: a laptop with a 6 GB RTX 3060, 32 GB RAM and a 20-thread CPU should install the base package and use `standard`; `basic` is the fallback if VRAM or latency becomes a problem, and `full` is not appropriate.

## Workflow

1. **Check the input** exists and has a supported extension. Quote paths that contain spaces.

2. **Trial a few pages first** when the PDF is large or the hardware is unknown. This catches OOM and tier problems before a long run:

   ```powershell
   mineru-kit parse "paper.pdf" -o temp\paper-p1-3.md --tier standard --pages 1-3
   ```

3. **Convert the full document** once the sample looks right:

   ```powershell
   mineru-kit parse "paper.pdf" -o temp\paper.md --tier standard
   ```

   `mineru-kit parse` converts all pages by default, `--pages all` is an explicit equivalent, and `-o` is required. The document-library `mineru parse` prints to stdout when `-o` is omitted.

4. **Read the output** with the file tools in chunks (offset/limit), not all at once. Formulas appear as LaTeX; tables as Markdown tables; images are extracted into the output directory and referenced by relative path.

5. **Validate before trusting** the conversion. See the section below.

### Temporary and durable output

- A conversion made only to read the content is a temporary file: write it under the workspace's designated temp folder (`.\temp` in this repository; create it if missing), not next to the source document.
- When the user wants a durable Markdown export, write to the path the user asked for and keep the generated image folder next to it.

### Long documents and citations

`mineru-kit parse` is stateless batch conversion and writes complete output. For long documents, bounded reading and page/block locators, use the document-library CLI instead:

```powershell
mineru parse "paper.pdf" --pages 1-10 --json
mineru read "doc:ab12cd3/tier:standard/page:11" --json
mineru read "doc:ab12cd3/tier:standard/page:4/block:7" --format image --output temp\page4-block7.png
```

`mineru parse` defaults to the first 10 PDF pages and prints a continuation command when output is truncated. Follow the returned `next_request` or `<!-- Next: ... -->` command instead of guessing the next page. The document library runs a local background service; start it with `mineru server start` if a command reports `server_not_running`. On a slow machine or a first run that downloads models, pass `--wait 600` to avoid the default 60-second client timeout; a wait timeout is not a parse failure.

### Page ranges

Both CLIs accept `--pages "1-5,8,r3-r1"`: page numbers start at 1, ranges include both endpoints, `r1` is the last page, and `all` selects every page. `mineru-kit parse` defaults to all pages; `mineru parse` defaults to the first 10. Non-PDF inputs do not accept `--pages`.

## Validation

- Confirm the command exited successfully and the output file exists and is not empty.
- Check coverage: a page limit means only part of the document was converted. Do not claim a document-wide result from a three-page sample.
- Spot-check formulas, tables, headings and numbers against the source. For a formula-heavy paper, compare one or two dense equations with the PDF before quoting them.
- Treat empty, garbled or suspiciously short output as a failed conversion, not as evidence that the source is empty.
- Keep the generated images folder with the Markdown file; missing images usually mean the file was moved without its assets.
- If `standard` output is wrong on specific pages, compare with `advanced` on those pages only; if it is slow, compare with `basic` before accepting a quality drop.

## Troubleshooting

| Symptom | Action |
| --- | --- |
| `mineru` or `mineru-kit` not found after install | Open a new shell so the uv tool bin directory is on `PATH`, or check `uv tool list` |
| Install fails with an unsupported Python error | Reinstall with `uv tool install --python 3.12 "mineru>=4.0,<5"` |
| Model download is slow or times out | Set `$env:MINERU_MODEL_SOURCE = "modelscope"` and retry |
| `parse_oom`, CUDA out of memory, or the machine becomes unresponsive | Lower the tier (`basic`), parse fewer pages, close GPU-heavy applications, or use the base package instead of `full` |
| First parse takes much longer than later ones | Models are downloading and loading; subsequent runs reuse the cache |
| Scanned PDF returns little text | Use `basic` or `standard` (OCR is automatic); `flash` needs `--ocr-mode ocr` |
| `flash` output has broken formulas | Use `basic` or `standard`; `flash` does not guarantee formula structure |
| `mineru parse` reports a wait timeout | Re-run with `--wait 600`, or inspect with `mineru show parse <id>`; the parse may still be running |
| Output is missing images | Convert into the final directory and keep the generated image folder next to the Markdown file |
| `server_not_running` | `mineru server start`, then retry; this applies to `mineru`, not `mineru-kit` |

## Privacy

MinerU parses locally by default. Never add `--remote` or upload a document to a remote service without explicit permission from the user, and never print `MINERU_API_KEY` values. The document-library service has usage telemetry enabled by default; it excludes document contents, file names and paths. Inspect it with `mineru telemetry status` and disable it with `mineru telemetry disable` if the user asks.

## CLI quick reference

| Option | Effect |
| --- | --- |
| `-o, --output <path>` | Required by `mineru-kit parse`; output file for a single input, directory for multiple inputs |
| `--tier flash\|basic\|standard\|advanced` | Parsing quality tier |
| `--pages "1-5,8,r3-r1"` or `all` | PDF page selection |
| `--ocr-mode auto\|txt\|ocr` | Native text only, OCR, or automatic selection |
| `--format markdown\|middle_json\|zip` | `mineru-kit parse` output format; `mineru parse` accepts `markdown` only |
| `--json` | Machine-readable output for `mineru parse` only |
| `--wait <seconds>` | Client wait for `mineru parse`; a timeout does not cancel the parse |
| `--limit <chars>` / `--after <cursor>` | Bound and continue stdout reading for `mineru parse` |
| `--remote` | Remote parsing; requires explicit user permission |
