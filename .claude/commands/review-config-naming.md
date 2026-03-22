Review all notenav config key names for quality, consistency, and future-proofing.

Read all relevant files and evaluate every config key against the criteria below. Report findings and recommendations.

## Files to read

- `config/base.toml` – all default config keys
- `lib/notenav.sh` – grep for `nn_cfg` calls to find every key used in code
- `docs/configuration.md` – documented keys and their descriptions
- `config/workflows/*.toml` – workflow-specific keys (entity, status, priority, lifecycle, queries)
- `GUIDELINES.md` – config key naming guidelines (the authoritative rules)

## Evaluation criteria

### 1. Naming quality

For each config key, evaluate:

- **Clarity** – does the name unambiguously describe what the setting controls? Could a new user guess what it does from the name alone?
- **Consistency** – does it follow the same patterns as other keys? (e.g., `sort_by` / `group_by` are consistent; `sort_by` / `grouping` would not be)
- **Positive framing** – is the name positive? (`show_archive` good, `hide_archive` / `no_archive` bad)
- **snake_case** – all keys must be snake_case, no exceptions

### 2. Booleans vs enums

This is critical. For every boolean config key, ask:

- Is this genuinely binary with no plausible third state, now or in the future?
- Could this reasonably need a third option later? If so, it should be an enum today.
- Example of a good boolean: `show_archive` (true/false is the natural domain)
- Example where an enum is better: `priority_plus = "demote"` instead of `priority_plus_demotes = true`

Flag any boolean that might need to become an enum in the future. This is a backwards-compatibility hazard – changing a boolean to an enum is a breaking change.

### 3. Future-proofing

For each key, consider:

- Is the name specific enough that it won't become ambiguous when the feature grows?
- Is it general enough that minor feature extensions won't require renaming?
- Would adding a related setting create an awkward naming collision?

### 4. Table structure

- Are keys grouped under the right TOML tables?
- Are there keys that belong together but are in different tables?
- Are there top-level keys that should be nested, or nested keys that should be top-level?

### 5. Missing or redundant keys

- Are there behaviors controlled by hardcoded values in the code that should be configurable?
- Are there config keys that aren't used anywhere in the code?
- Are there settings that overlap or conflict with each other?

## Output format

For each finding:
1. **Key name** and current value/type
2. **Category** (1–5 above)
3. **Issue** – what's wrong or what could be improved
4. **Recommendation** – specific suggestion (rename, change type, move table, etc.)
5. **Risk** – low (cosmetic), medium (could cause confusion), high (future breaking change)

At the end, provide:
- Summary table of all keys with a pass/flag/fail rating
- Overall assessment of the config key namespace quality
- Prioritized list of recommended changes (if any)

Do NOT make any changes – this is a review only.
