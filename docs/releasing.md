# Releasing

## Version source of truth

The `VERSION` file at the repo root is the single source of truth for the version string. It is read at runtime by `lib/notenav.sh` and at build time by `flake.nix`. No other file should hardcode the version.

## Branching model

- **`main`** -- bleeding edge development. All work lands here.
- **`stable`** -- always points at the latest release. Updated as part of the release process.
- **Tags** (`v0.1.0`, `v0.2.0`, ...) mark individual releases.

## Version string format

- During development: `X.Y.Z-dev` (e.g., `0.2.0-dev`)
- At release: `X.Y.Z` (e.g., `0.2.0`)

## Release checklist

1. **Update VERSION** -- remove the `-dev` suffix:

   ```
   echo "0.2.0" > VERSION
   ```

2. **Commit the release**:

   ```
   git add VERSION
   git commit -m "Release v0.2.0"
   ```

3. **Tag the release**:

   ```
   git tag v0.2.0
   ```

4. **Update the stable branch**:

   ```
   git branch -f stable v0.2.0
   ```

5. **Bump to next dev version**:

   ```
   echo "0.3.0-dev" > VERSION
   git add VERSION
   git commit -m "Begin v0.3.0 development"
   ```

6. **Push everything**:

   ```
   git push origin main stable v0.2.0
   ```
