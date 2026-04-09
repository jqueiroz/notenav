# Changelog

All notable changes to notenav are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/).

<!-- Newest release goes at the top. -->

## [Unreleased]

### Added

- **`d` delete note(s)** – press `d` in command mode to delete the focused note, or all multi-selected notes. Single-delete prompts `y/N` (respects `delete_confirm`); multi-delete lists all targets and requires typing `YES`. Configurable via `ui.delete_method` (`"trash"` or `"rm"`) and `ui.delete_confirm` (`"always"` or `"never"`). Trash mode uses `trash-put` or `gio trash` with a fallback to `rm`.
- **`/` search mode** – press `/` to search by title (fuzzy-filter) or by note contents (live grep). Press `?` to toggle between modes. Two exits: `enter` (open note) and `esc` (keep filter active). Re-entering `/` resumes the last search mode and query.
- **`/?` content search** – press `?` while in title search to switch to content search (uses `rg`/`grep`, or `zk --match` when available). The query carries over. Press `esc` to persist as a pipeline-level filter.
- **`?` help toggle** – press `?` to show a keybinding reference overlay; press again to dismiss. Especially useful with the `clean` header mode.
- **`h` header mode toggle** – press `h` to switch between `clean` (state only) and `guided` (keybinding hints) header modes at runtime.
- Named color aliases for workflow config – use `"red"`, `"bold-red"`, `"dim"`, etc. instead of raw ANSI codes like `"31;1"`. Raw codes still accepted. All built-in workflows now use named colors.

### Changed

- **`ui.header` renamed to `ui.initial_header_mode`** – sets the header mode on launch (`"clean"` or `"guided"`). Default is `"clean"`. Press `h` to toggle at runtime. The old `"full"`, `"auto"`, and `"compact"` modes have been replaced by `"clean"` and `"guided"`.
- **Filter keybindings moved under `f` prefix with pickers** – type (`ft`), status (`fs`), priority (`fp`), and tags (`f#`) are now all under the filter mode prefix. Each opens a picker showing all values with an "all" option to clear. `T`/`S`/`P` clear keys removed (pickers replace them).

### Removed

- **`f n` (name filter) sub-popup** – replaced by `/` search mode, which is faster (one keystroke) and uses fuzzy matching.
- **`f c` (content filter) sub-popup** – replaced by `/?` content search mode, which provides live inline results instead of a separate popup.
