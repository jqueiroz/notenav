# Changelog

All notable changes to notenav are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/).

<!-- Newest release goes at the top. -->

## [Unreleased]

### Added

- **Sort chains**: configurable tie-breaking sequences for each primary sort field. When two notes share the same primary sort value, the chain fields break the tie in order. Default chains: `priority → [status, created, title]`, `status → [priority, created, title]`, timestamps → `[title]`, title → `[created]`. Configurable via `[defaults.sort_chain]`.
- `nn doctor` now reports line-ending diagnostics: CRLF and BOM note counts (informational), mixed-line-ending warnings, and detection of duplicated frontmatter blocks left by the CRLF write bug (see Fixed), listing affected paths.
- `nn doctor --fix-frontmatter`: opt-in repair for notes with a duplicated frontmatter block – merges the blocks (latest edits win), writes a `.bak` backup per note, and refuses files that don't match the known damage pattern.
- Test suite (`tests/run.sh`) covering the frontmatter write paths byte-for-byte across LF/CRLF/BOM/mixed line-ending variants, wired into CI.

### Changed

- Default `sort_by` is now `"priority"` (was `"created"`). Workflows that disable priority (e.g. zettelkasten) automatically fall back to `"created"`.
- Default `group_by` is now `"type"` (was `"none"`).
- Cuboid workflow: tasks now appear before ideas in grouped views (type display order).

### Fixed

- **Notes with Windows (CRLF) line endings or a UTF-8 BOM are no longer corrupted by inline actions.** Previously, setting a type/status/priority (including status cycle, priority bump, and bulk edit) on such a note prepended a duplicate frontmatter block, hiding the note's real metadata. Frontmatter detection now tolerates CRLF, BOMs, and trailing blanks after the `---` fence; rewrites preserve each file's own line endings byte-for-byte (inserted lines match the file's style, a BOM stays at byte 0). Existing damage can be repaired with `nn doctor --fix-frontmatter`.
- New notes created by notenav (native backend) now match the notebook's prevailing line-ending style instead of always using LF; zk-created notes follow zk's own output.
- Inline and bulk edits no longer reset a note's file permissions to 0600 (the temp-file mode used to survive the atomic rename); `nn doctor --fix-frontmatter` preserves permissions too.
- Notes with long frontmatter (over ~200 lines) are editable again; the unclosed-frontmatter safety check and the rewriters share a single 100000-line cap.
- `nn doctor --fix-frontmatter` raises the scan cap from 2000 to 200000 files (and says so when even that is exceeded), streams large notes instead of buffering them in memory, claims its `.bak` backups atomically (concurrent runs can no longer clobber each other's backup), and reports honestly when a merge leaves an unverifiable fenced block behind.
- Filenames containing a newline are excluded from indexing with a doctor warning (their phantom rows could previously misdirect an edit onto an innocent file); concurrent list reloads no longer garble the internal index (per-invocation temp files).
- zk backend: notes with a UTF-8 BOM now appear with correct metadata in listings and filtered views (zk itself cannot parse BOM'd frontmatter; notenav detects such rows and re-lists those notes natively).
- Clearing the search query and pressing Esc no longer restores the previous search; it clears the search filter as expected.
