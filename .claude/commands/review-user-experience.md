Review notenav from the user's perspective. Read all source files and evaluate the experience against the categories below.

This is NOT a code quality audit (`/audit-code` covers that). Focus on what the user sees, feels, and has to figure out.

## Files to read

- `lib/notenav.sh`: all user-facing output, fzf configuration, keybindings, error messages, header/hints
- `bin/nn`: entry point, argument parsing, help text
- `docs/cli.md`: CLI reference (compare against actual behavior)
- `config/base.toml`: defaults the user inherits
- `config/workflows/*.toml`: what workflows look like out of the box
- `curl/install.sh`: first-run experience

## Categories to review

### 1. First-run & onboarding

- Install to first launch: is the path obvious? Does `nn` without a notebook give a clear next step?
- `nn init`: does it explain what it created and what to do next?
- `nn doctor`: does it catch everything a confused user might hit? Are its messages actionable?
- Missing dependencies: does the error say what version is needed and how to install it?

### 2. Feedback & state visibility

- After an inline action (status change, priority bump, archive), does the user see confirmation of what changed?
- Is the current filter state always visible? Can the user tell at a glance what's active?
- Mode switches (faceted, ad-hoc, interactive): does the user know which mode they're in?
- Loading/empty states: does an empty result set explain *why* it's empty (filters too narrow? no notes at all?)
- Preset switching: is it clear which preset is active and what it filters?

### 3. Error handling UX

Not "is the error caught" (that's `/audit-code`), but "does the message help the user fix it?"

- Bad config values: does the error name the key, show the bad value, and list valid options?
- Malformed frontmatter: does the user know which note is broken and what field is wrong?
- Missing workflow file: does the error explain what `.nn/workflow.toml` is and how to create it?
- `zk` failures: are upstream errors surfaced clearly or swallowed silently?

### 4. Discoverability

- Can a user figure out keybindings without reading docs? Are on-screen hints sufficient?
- `nn --help`: does it cover all three operating modes with clear examples?
- Header line: does it show enough context (notebook, workflow, filter state) without clutter?
- Are less-common features (group-by, sort, archive toggle) findable from the TUI?

### 5. Consistency

- Terminology: is the same concept called the same thing everywhere? (TUI header, CLI output, help text, error messages, config comments)
- Behavior symmetry: if you can add a filter, can you clear it the same way? If `+` promotes, does `-` demote?
- Keybinding patterns: do similar actions use similar key patterns? Are there surprising outliers?

### 6. Edge cases & graceful degradation

- Notes with missing or unexpected frontmatter values (empty type, unknown status, no tags)
- Special characters in titles, paths, or tag names (spaces, quotes, colons, unicode)
- Very large notebooks (1000+ notes): does performance degrade? Does the UI stay responsive?
- Zero notes matching a filter vs zero notes in the notebook entirely: are these distinguished?
- `NO_COLOR` / `TERM=dumb`: does the TUI degrade to something usable?

### 7. Workflow friction

Walk through common user journeys and flag unnecessary steps or lost context:

- **Triage**: open TUI, scan inbox/backlog, update statuses, re-filter. How many keystrokes?
- **Find & edit**: search for a note, open it in editor, return to the TUI. Is context preserved?
- **Filter drill-down**: narrow by type, then status, then tag. Is it fluid or cumbersome?
- **Ad-hoc to interactive**: `nn type=task` then deciding to go interactive with `-i`. Is the transition smooth?
- **Config iteration**: change a setting, see the effect. Does the user need to restart `nn`?

## Output format

For each finding:
1. **Category** (1-7 above)
2. **What the user experiences** –describe the scenario from the user's perspective
3. **What would be better** –concrete suggestion
4. **Impact**: high (users will hit this and get stuck), medium (causes confusion but recoverable), low (minor polish)

Group findings by category. End with a summary table sorted by impact.

Do NOT make any changes –this is a review only. Report findings so the user can decide what to fix.
