Audit the notenav config system for internal consistency across TOML workflow files, documentation, sample files, and implementation.

Read all relevant files and cross-reference them against each other. Report every inconsistency found.

## Categories to check

### 1. Workflow file integrity

For every TOML in `config/workflows/` and `samples/workflows/`:

**Entity section:**
- Every value in `entity.values` has a corresponding `[entity.<name>]` with `icon` and `color`

**Status section:**
- Every value in `status.values` has a color in `[status.colors]`
- Every entry in `status.filter_cycle` exists in `status.values`
- Every entry in `status.archive` exists in `status.values`
- Every key and value in `status.lifecycle.forward` exists in `status.values`
- Every key and value in `status.lifecycle.reverse` exists in `status.values`

**Priority section** (skip if `priority.enabled = false`):
- Every value in `priority.values` has a color in `[priority.colors]`
- Every entry in `priority.filter_cycle` exists in `priority.values`
- Every key and value in `priority.lifecycle.up` exists in `priority.values` (except `""` key for unset)
- Every key and value in `priority.lifecycle.down` exists in `priority.values`

**Query presets:**
- Every `[queries.<name>]` has an `args` key
- Type/status/priority values referenced in query `args` exist in their respective `values` arrays

**Extends files** (e.g. sample workflows with `extends`):
- Load the base workflow for validation context — values from the base apply unless overridden

### 2. Documentation links

For every `.md` file in the repo: verify all relative links (`[text](path)`) resolve to existing files. Check anchor links (`#section`) point to existing headings in the target file.

### 3. Config keys: docs vs implementation

- Grep `lib/notenav.sh` for every `nn_cfg` call and extract the JSON path argument
- Every config path used in code should be documented in `docs/configuration.md`
- Check `jq` fallback defaults (the `// "value"` pattern) in code against corresponding values in `config/base.toml`

### 4. Built-in workflow summary in docs

- The workflow comparison table in `docs/configuration.md` (entity types, statuses, priority settings per workflow) must match the actual TOML files in `config/workflows/`
- Verify entity lists, status lists, and priority enabled/disabled state are accurate

### 5. README consistency

- Every workflow file in `config/workflows/` is mentioned in `README.md`
- Workflow names in README prose match actual filenames (e.g. "compass" matches `compass.toml`)
- Any links to workflow files or docs resolve correctly

### 5b. Naming convention (`nn` vs `notenav`)

Verify that all config path references follow the naming convention defined in `GUIDELINES.md`:
- Project-local config directory is always `.nn/` (never `.notenav/`)
- User-global config directory is always `notenav/` under XDG paths (never `nn/`)
- Check code (`lib/notenav.sh`, `bin/nn`), docs, samples, and config file comments
- Temp file prefixes use `nn` (e.g. `.nn-c`, `.nn-s`), not `notenav`

### 6. Workflow doc pages vs TOML

For each file in `docs/workflows/`:
- Entity types table matches `entity.values` + icons from the corresponding TOML
- Status table matches `status.values` from the corresponding TOML
- Query presets table matches `[queries.*]` sections from the corresponding TOML
- Any described lifecycle transitions match the TOML lifecycle tables

## Output format

For each finding:
1. **Category** (numbered as above)
2. **File(s)** involved with line numbers where applicable
3. **Issue** description
4. **Expected** vs **actual** values

At the end, provide a summary:
- Number of files checked
- Number of issues found per category
- Overall pass/fail assessment

If no issues are found in a category, report it as clean. Do NOT make any changes — this is an audit only.
