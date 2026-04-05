# Changelog

All notable changes to notenav are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/).

<!-- Newest release goes at the top. -->

## [Unreleased]

### Added

- **`d` delete note(s)** – press `d` in command mode to delete the focused note, or all multi-selected notes. Single-delete prompts `y/N` (respects `delete_confirm`); multi-delete lists all targets and requires typing `YES`. Configurable via `ui.delete_method` (`"trash"` or `"rm"`) and `ui.delete_confirm` (`"always"` or `"never"`). Trash mode uses `trash-put` or `gio trash` with a fallback to `rm`.
- **`/` search mode** – press `/` in the main TUI to fuzzy-filter notes by title and metadata. Three exits: `enter` (open note), `tab` (keep filter active), `esc` (cancel). The `tab`-persist flow lets you narrow the list and then use command-mode actions on the results.
- **`?` content search mode** – press `?` for live grep of note bodies (uses `rg`/`grep`, or `zk --match` when available). Same three exits as `/`. Pressing `tab` persists the content filter at the pipeline level, surviving reloads and filter changes.
- Named color aliases for workflow config – use `"red"`, `"bold-red"`, `"dim"`, etc. instead of raw ANSI codes like `"31;1"`. Raw codes still accepted. All built-in workflows now use named colors.

### Removed

- **`f n` (name filter) sub-popup** – replaced by `/` search mode, which is faster (one keystroke) and uses fuzzy matching.
- **`f c` (content filter) sub-popup** – replaced by `?` content search mode, which provides live inline results instead of a separate popup.
