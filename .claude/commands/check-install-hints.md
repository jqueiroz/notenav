Validate that all distro-specific install hints in `lib/notenav.sh` are correct and consistent with the provisioning scripts.

Read all relevant files and cross-reference them. Report every issue found.

## Files to read

- `lib/notenav.sh`: all install hint blocks – both runtime startup errors and `nn_doctor()` output (search for `echo.*Install via` and `echo.*Install from`)
- `virtualization/*/guest/provision.sh`: verified install commands for each distro

## Distros to cover

Ubuntu/Debian, Fedora, Alpine, Arch, Gentoo, FreeBSD, macOS (Homebrew).

## Dependencies to check

All hard runtime dependencies that block startup: fzf, gawk, yq-go, jq.

## Checks

### 1. Package name accuracy

For each dependency and each distro:

- Extract the package name from the install hint in `lib/notenav.sh`
- Extract the package name from the corresponding `provision.sh`
- Flag any mismatch (wrong package name, wrong package manager command)

### 2. Distro detection accuracy

For each distro detection branch in the install hints:

- Verify the detection method matches the distro (e.g., `/etc/debian_version` for Debian/Ubuntu, `/etc/fedora-release` for Fedora, `/etc/alpine-release` for Alpine, `command -v pacman` for Arch, `command -v emerge` for Gentoo, `uname == FreeBSD` for FreeBSD, `command -v brew` for macOS)
- Flag any detection that could misfire (e.g., matching a different distro)

### 3. Coverage completeness

- For each dependency, verify all distros are covered (or have a reasonable generic fallback)
- Flag any distro that has a provision script but no corresponding install hint
- Flag any dependency that is missing install hints entirely

### 4. Cascade order

- Verify the `if/elif` chain is ordered correctly so that more specific checks come before more general ones (e.g., file-based detection before command-based detection, `brew` last as a macOS catch-all)
- Flag any ordering issue that could cause a wrong hint to be shown

### 5. Consistency

- Verify all install hints use the same format (`Install via: <command>` for packaged, `Install from <url>` for GitHub)
- Verify the fzf "not found" and fzf "too old" paths are consistent with each other
- Verify the runtime startup hints and `nn_doctor()` hints match for each dependency and distro
- Flag any formatting inconsistencies

## Output format

For each finding:
1. **Dependency** (fzf, gawk, yq, jq)
2. **Distro** affected
3. **Issue** description
4. **Expected** vs **actual**

At the end, provide a summary table:

| Dependency | Distros with hints | Missing hints | Issues |
|---|---|---|---|

If no issues are found, report it as clean. Do NOT make any changes – this is a check only.
