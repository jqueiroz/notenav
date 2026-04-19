# Changelog

All notable changes to notenav are documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/).

<!-- Newest release goes at the top. -->

## [Unreleased]

### Added

- **Sort chains**: configurable tie-breaking sequences for each primary sort field. When two notes share the same primary sort value, the chain fields break the tie in order. Default chains: `priority → [status, created, title]`, `status → [priority, created, title]`, timestamps → `[title]`, title → `[created]`. Configurable via `[defaults.sort_chain]`.
