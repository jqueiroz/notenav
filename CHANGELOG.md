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

### Added

- **Archive-only view mode** – `defaults.archive_visibility = "only"` (or pressing `zh` twice from the default) shows only notes whose status is in `[status] archive`. Useful for reviewing what you've finished or dropped. The `zh` key now cycles `hide → show → only → hide`.

### Changed

- **`defaults.show_archive` (boolean) renamed to `defaults.archive_visibility`** – now an enum: `"hide"` (default), `"show"`, or `"only"`. The new `"only"` value is the runtime-visible reason for the rename.
- **`type.visibility` moved to `defaults.type_visibility`** – this setting was the only user preference living under the workflow-definition `[type]` table. It now lives under `[defaults]` alongside other view preferences.
- **`refresh.max_files` renamed to `refresh.auto_max_files`** – clarifies that this is the auto-refresh threshold, not a hard cap on indexed files.
- **`meta.schema` renamed to `meta.schema_version`** – more descriptive name for the workflow schema version.
- **`defaults.group_by` uses `"none"` as the canonical "no grouping" value** – the built-in defaults use `"none"` instead of the empty string.
- **`ui.header` renamed to `ui.initial_header_mode`** – sets the header mode on launch (`"clean"` or `"guided"`). Default is `"guided"`. Press `h` to toggle at runtime. The old `"full"`, `"auto"`, and `"compact"` modes have been replaced by `"clean"` and `"guided"`.
- **Filter keybindings moved under `f` prefix with pickers** – type (`ft`), status (`fs`), priority (`fp`), and tags (`f#`) are now all under the filter mode prefix. Each opens a picker showing all values with an "all" option to clear. `T`/`S`/`P` clear keys removed (pickers replace them).
- **Sort and group cycling replaced with pickers** – `zo` (sort order) and `zg` (group by) now open single-select pickers instead of cycling through values.

### Removed

- **`f n` (name filter) sub-popup** – replaced by `/` search mode, which is faster (one keystroke) and uses fuzzy matching.
- **`f c` (content filter) sub-popup** – replaced by `/?` content search mode, which provides live inline results instead of a separate popup.

### Fixed

- **Zettelkasten workflow now respects `priority.enabled = false`** – the loader used `jq '.priority.enabled // true'`, but jq's `//` filters out `false` as well as `null`, so an explicit `false` was silently coerced to `true`. The result was that zettelkasten failed `nn doctor` with three errors and rendered priority bindings, columns, and sort options that did nothing. Hardened the three call sites with explicit `has("enabled")` checks, and applied the same prophylactic fix to the latent `defaults.sort_reverse`/`show_archive`/`wrap_preview` loaders.
- **Filter, change, and help headers no longer advertise `[p]riority` when priority is disabled** – previously the headers pointed users at sub-key bindings (`fp`, `cp`) that silently no-op'd in zettelkasten. Hidden when `priority.enabled = false`.
- **`nn doctor` no longer skips its own `type.visibility = "show_defined"` warning** – the check read `$NN_TYPE_VISIBILITY`, but doctor calls `nn_load_config` without `nn_precompute_workflow`, so the variable is never populated in doctor's scope. The warning that flags "all notes will be hidden" silently never fired. Now reads from `nn_cfg` directly with the same default the runtime uses.
- **`nn doctor` survives `mktemp` failures** – the Phase 2 config-merge check used to abort the entire doctor run if `mktemp` failed (broken `TMPDIR`, full disk). It now falls back to letting `nn_load_config` write to stderr directly, matching the graceful pattern Phase 5 already uses for `.nnignore` warnings.
- **`nn doctor` no longer prints an empty "Trusted sources:" header** – a comment-only `trusted-sources` file caused the section header and a redundant "none configured" line to render. Now the section is skipped entirely unless at least one non-comment URL is present.
- **`nn doctor` previewer detection no longer over-warns** – previously, every missing previewer encountered before the first found one was reported as a warning, so a list like `mdcat glow bat` with only `bat` installed produced two warnings even though preview worked fine. Now missing previewers are always informational; the section emits a single actionable warning only when *no* previewer is available at all.
- **`nn doctor` now flags malformed `[queries]` entries** – a top-level assignment like `[queries] foo = "bar"` (instead of `[queries.foo]`) used to make jq error out silently, suppressing all query-preset validation for the offending entry. Doctor now reports `foo: must be a table, got string` and continues validating the rest of the presets.
- **`nn doctor` hints when an unrecognized frontmatter value looks like a YAML inline comment** – notenav's frontmatter parser stores `type: task # important` verbatim as `task # important`, so doctor previously reported the value as unrecognized without explaining why. When an unknown type/status/priority value contains `#`, doctor now suggests removing or quoting the comment.
