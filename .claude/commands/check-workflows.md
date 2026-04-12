Validate notenav workflow files and config defaults for internal consistency.

Read all relevant files and cross-reference them against each other. Report every inconsistency found.

## Files to read

- `config/workflows/*.toml`: built-in workflow definitions
- `samples/workflows/*.toml`: sample workflow files (may use `extends`)
- `config/base.toml`: base config with default values
- `lib/notenav.sh`: grep for `nn_cfg` calls to find fallback defaults

## Categories to check

### 1. Workflow file integrity

For every TOML in `config/workflows/` and `samples/workflows/`:

**Meta section:**
- If `meta.schema_version` is present, it must be a positive integer (currently only `1` is valid)

**Type section:**
- Every value in `type.values` has a corresponding `[type.<name>]` with `icon` and `color`

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
- Load the base workflow for validation context – values from the base apply unless overridden

### 2. Config defaults consistency

- Grep `lib/notenav.sh` for every `nn_cfg` call and extract the JSON path argument and fallback default
- Check `jq` fallback defaults (the `// "value"` pattern) in code against corresponding values in `config/base.toml`
- Flag any mismatches between code fallbacks and base config values

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

If no issues are found in a category, report it as clean. Do NOT make any changes – this is an audit only.
