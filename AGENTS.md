# Agent Instructions

Guidance for AI coding agents working in this repository.

## Project Overview

This is a personal dotfiles repository. Its main contents are:

- `.config/nvim/` — a Neovim configuration on `vim.pack` with a central plugin
  table.
- `scripts/` — cross-platform setup scripts that link `.config/nvim/` into
  Neovim's config location.
- `docs/` — project documentation.
- `README.md` — the user-facing entry point: requirements, installation, key
  mappings and links into `docs/`.

**Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) before making structural
changes.** It documents the repository layout, the Neovim startup flow, the
plugin set, and the setup scripts; when any of those change, it is updated in
the same pass as the changelog (see [Documentation](#documentation)).

## Language

- Always use English in AGENTS.md and in all files under `docs/`.

## Documentation

- Architecture and design decisions live in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- Notable, user-facing changes must be recorded in
  [docs/CHANGELOG.md](docs/CHANGELOG.md) under `## [Unreleased]`, following
  [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

**Both files are written when the commit is prepared, not after a change is
made.** The `commit` skill owns that pass: it splits the working tree into
atomic commits and, immediately before each one, writes the entries that
commit's diff requires, so the documentation lands in the commit it describes.
While doing the work itself, leave these two files alone — do not append a
changelog entry or an architecture note as a postscript to a change, and do not
edit them "for later".

## Code Style

- Follow `.editorconfig`: LF line endings, UTF-8, final newline, 4-space
  indentation.
- Neovim plugins live in the central table at
  `.config/nvim/lua/plugins/config.lua`, which `pack.lua` turns into
  `vim.pack` specs; core editor behavior goes in `.config/nvim/lua/core/`.
- Do not add comments to code: let the code explain itself. Write a comment
  only when the user asks for one.
- `.config/nvim/nvim-pack-lock.json` is tracked; commit it with plugin changes.

## Temporary Files

- All temporary files must be generated in the `.\temp` folder; do not scatter
  them elsewhere in the repository.
- If the `.\temp` folder does not exist, create it before use.
