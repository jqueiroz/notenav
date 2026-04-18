# Releasing

[Back to README](../README.md)

## Version source of truth

The `VERSION` file at the repo root is the single source of truth for the version string. It is read at runtime by `lib/notenav.sh` and at build time by `flake.nix`. No other file should hardcode the version.

## Branching model

- **`main`** – bleeding edge development. All work lands here.
- **`stable`** – always points at the latest release. Updated as part of the release process.
- **Tags** (`v0.1.0`, `v0.2.0`, ...) mark individual releases.

## Version string format

- During development: `X.Y.Z-dev` (e.g., `0.2.0-dev`)
- At release: `X.Y.Z` (e.g., `0.2.0`)

## Release notes

Each release gets a section in [`CHANGELOG.md`](../CHANGELOG.md) at the repo root. The notes are written as part of the release commit.

### Generating notes

1. List commits since the previous tag (or from the beginning for the first release):

   ```
   git log --oneline v0.1.0..HEAD   # subsequent releases
   git log --oneline                 # first release (no prior tag)
   ```

2. Group commits under `###` sub-headings (omit any with no entries):

   - `### Added`
   - `### Changed`
   - `### Deprecated`
   - `### Removed`
   - `### Fixed`
   - `### Security`

3. Write each entry as a concise, user-facing bullet. Merge closely related commits into a single bullet. Drop commits that are invisible to users (typo fixes in comments, internal refactors with no behavior change, CI tweaks).

4. Move the contents of the `## [Unreleased]` section under a new `## [X.Y.Z] – YYYY-MM-DD` heading, then add a fresh empty `## [Unreleased]` section above it.

## Release checklist

1. **Write release notes** – follow the [release notes](#release-notes) process above and add the new section to `CHANGELOG.md`.

2. **Update VERSION** – remove the `-dev` suffix:

   ```
   echo "0.2.0" > VERSION
   ```

3. **Commit the release**:

   ```
   git add CHANGELOG.md VERSION
   git commit -m "Release v0.2.0"
   ```

4. **Tag the release**:

   ```
   git tag v0.2.0
   ```

5. **Update the stable branch**:

   ```
   git branch -f stable v0.2.0
   ```

6. **Bump to next dev version**:

   ```
   echo "0.3.0-dev" > VERSION
   git add VERSION
   git commit -m "Begin v0.3.0 development"
   ```

7. **Push everything**:

   ```
   git push origin main stable v0.2.0
   ```

8. **Create a GitHub Release**:

   ```
   gh release create v0.2.0 --title "v0.2.0" --notes-file - <<< "$(sed -n '/^## \[0\.2\.0\]/,/^## \[/{/^## \[0\.2\.0\]/d;/^## \[/d;p}' CHANGELOG.md)"
   ```

   This extracts the release section from `CHANGELOG.md` and uses it as the release body. For a release without changelog entries, use `--notes "Initial release."` or similar.
