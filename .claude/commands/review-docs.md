Review all documentation for quality, accuracy, and consistency. Read every doc and cross-reference against the actual codebase.

Files to review: `README.md`, `docs/install.md`, `docs/configuration.md`, `docs/faq.md`, `docs/workflows/*.md`, `config/base.toml`, `config/workflows/*.toml`, `samples/`, and `CLAUDE.md`. This includes TOML file comments — they are documentation too.

## What to check

### 1. Accuracy against implementation
- Read `lib/notenav.sh` and `bin/nn` alongside the docs
- Keybinding tables match actual fzf bind calls in the code
- CLI usage, flags, and examples in docs match actual argument parsing
- Described data flow matches what the code actually does
- State files and helper scripts listed in docs match what the code generates

### 2. Accuracy against config files
- Feature descriptions match what the TOML workflows actually define
- Workflow doc pages (`docs/workflows/*.md`) match their corresponding `config/workflows/*.toml`
- Sample files (`samples/`) match the documented config format and use valid keys
- `docs/configuration.md` covers all config keys used in the codebase

### 2b. TOML files as documentation

TOML files with comments are documentation artifacts — often the first thing a user reads or copies. Review them as such:

- **`config/base.toml`**: every key has a comment explaining what it does and what values are valid. Comments stay in sync with `docs/configuration.md`.
- **`config/workflows/*.toml`**: each major section has a comment block explaining what it configures. Non-obvious keys have inline comments. ANSI color codes have a color name comment (e.g. `# bold red`). Tombstone/omission patterns are explained.
- **`samples/user-config.toml`**: all values commented out (matching base defaults), annotations explain each option. No stale keys or wrong defaults.
- **`samples/workflows/*.toml`**: header comments explain purpose and placement. Inline comments guide a user building their first workflow. All keys, values, and extends references are valid.
- Across all TOML files: comments match actual behavior — no outdated value lists, no wrong defaults, no references to renamed keys.

### 3. Completeness
- Are any features, keybindings, or config options missing from the docs?
- Are any documented features no longer implemented?
- Do all workflows have a doc page under `docs/workflows/`?
- Does `docs/install.md` cover all installation methods that exist?

### 4. Consistency across docs
- Terminology is used consistently (e.g. "query preset" vs "saved query" vs "named query")
- Note type names, status names, and priority values are spelled the same everywhere
- The same feature isn't described differently in README vs configuration.md vs workflow docs
- Formatting conventions are consistent (table style, heading levels, code block usage)
- **Naming convention**: `.nn/` for project-local paths, `notenav` for user-global paths – verify no doc uses `.notenav/` or `~/.config/nn/` (see `GUIDELINES.md`)

### 5. Writing quality
- Concise, no unnecessary repetition
- Clear structure — easy to find what you need
- Code examples are correct and runnable
- No stale TODOs, placeholders, or draft text left in

### 6. Cross-document navigation
- Every doc is reachable from README or another doc (no orphan pages)
- Relative links between docs are correct and resolve
- README provides a clear path to detailed docs for each topic

## Output format

Group findings by document. For each finding:
1. **File** and line number
2. **Category** (1–6 above)
3. **Issue** — what's wrong
4. **Suggestion** — how to fix it

End with a summary table: files reviewed, issues per category, overall assessment.

Do NOT make any changes — this is a review only.
