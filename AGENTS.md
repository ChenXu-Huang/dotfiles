# Agent Instructions

Guidance for AI coding agents working in this repository.

## Project Overview

This is a personal dotfiles repository. Its main contents are:

- `nvim/` — a Neovim configuration (lazy.nvim-based, one plugin spec per file).
- `scripts/` — cross-platform setup scripts that link `nvim/` into Neovim's
  config location.
- `docs/` — project documentation.

**Read [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) before making structural
changes.** It documents the repository layout, the Neovim startup flow, the
plugin set, and the setup scripts. Keep it up to date when you change any of
those things.

## Language

- Always use English in AGENTS.md and in all files under `docs/`.

## Documentation

- Architecture and design decisions live in [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).
- Notable, user-facing changes must be recorded in
  [docs/CHANGELOG.md](docs/CHANGELOG.md) under `## [Unreleased]`, following
  [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Code Style

- Follow `.editorconfig`: LF line endings, UTF-8, final newline, 4-space
  indentation.
- Neovim plugin specs go in `nvim/lua/plugins/` (one file per plugin, returned
  as a lazy.nvim spec); core editor behavior goes in `nvim/lua/core/`. Both
  directories are auto-loaded — do not add central registries for them.
- `nvim/lazy-lock.json` is intentionally git-ignored; never commit it.

## Temporary Files

- All temporary files must be generated in the `.\temp` folder; do not scatter
  them elsewhere in the repository.
- If the `.\temp` folder does not exist, create it before use.
