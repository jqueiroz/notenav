# FAQ

[Back to README](../README.md)

## How does `nn` find my project configuration?

The `.nn/` directory is found by walking up from your current working directory toward the filesystem root – the same way git finds `.git/`. The first `.nn/` directory found wins.

This means you can run `nn` from any subdirectory of your project and it will use the same `.nn/workflow.toml`.

```
~/notes/
├── .nn/
│   └── workflow.toml      ← found from anywhere below ~/notes/
├── projects/
│   └── alpha/
│       └── spec.md
├── journal/
│   └── 2026-03-21.md
└── inbox.md
```

If no `.nn/` directory is found anywhere in the path, notenav falls back to the `default_workflow` setting in your user config (`~/.config/notenav/config.toml`), or to the built-in Zenith workflow if that's not set either.

## Do I need zk?

No. [zk](https://github.com/zk-org/zk) is optional and transparent – notenav auto-detects it and uses it when available, with no extra setup beyond `zk init`. Without it, notenav uses its own frontmatter parser and `rg`/`grep` for body text search. The core experience works – you just lose a few features:

- **Link graph:** the Links/Backlinks sections in the preview pane are skipped (they rely on zk's index)
- **Body text search:** uses `rg` or `grep` instead of zk's indexed `--match` (slower on large notebooks)
- **Note creation:** generates files directly instead of using zk templates
- **Listing performance:** may be slower for very large notebooks (no SQLite index)

Install zk when you want these features. `nn doctor` will tell you whether zk is detected and which backend is active.

## How do I set up zk?

Install [zk](https://github.com/zk-org/zk) via your package manager (Homebrew, AUR, or [GitHub releases](https://github.com/zk-org/zk/releases)), then run `zk init` at the root of your notebook:

```bash
cd ~/notes
zk init
```

This creates a `.zk/` directory. That's it – notenav auto-detects `.zk/` and switches to the zk backend automatically. No configuration needed on the notenav side. Run `nn doctor` to confirm it's detected.

The `.zk/` directory should be at the same level as or above `.nn/`. If your notebook root is `~/notes` and `.nn/` is at `~/notes/.nn/`, then `~/notes/.zk/` is the right place.

## Do I need to manually trigger indexing when using zk?

No. zk incrementally re-indexes on every query – there is no manual sync step. Just edit your notes and `nn` always shows the latest state.

## Which notes does `nn` show?

notenav discovers notes by recursively finding all markdown files under the current directory. When zk is installed, it delegates to `zk list` for faster indexed listing.

**At the notebook root:** `nn` shows all notes in the entire notebook.

**From a subdirectory:** `nn` scopes results to the current directory and everything below it. This is useful for focusing on a subset of notes:

```bash
cd ~/notes              # shows everything
cd ~/notes/projects     # shows only notes under projects/
cd ~/notes/projects/alpha  # shows only notes under projects/alpha/
```

The project configuration (`.nn/workflow.toml`) still applies regardless of which subdirectory you're in – only the set of visible notes changes.

## Where do config files go?

Two locations, serving different purposes:

| File | Path | Purpose |
|------|------|---------|
| Project workflow | `.nn/workflow.toml` | Workflow definition and project-specific query presets. Lives in the project root, alongside `.git/`. Shared with collaborators via version control. |
| User preferences | `~/.config/notenav/config.toml` | Personal preferences (editor, colors, sorting, default workflow). Applies to all projects. Not shared. |

These are orthogonal – project config defines *what the workflow looks like*, user config defines *how you prefer to use it*.

Use `nn init` to scaffold these files:

```bash
nn init                    # create .nn/workflow.toml
nn init --user             # create ~/.config/notenav/config.toml
```

Or start from the built-in workflows and annotated samples:

| File | Description |
|------|-------------|
| [config/workflows/zenith.toml](../config/workflows/zenith.toml) | Built-in Zenith workflow (default) |
| [config/workflows/cubic.toml](../config/workflows/cubic.toml) | Built-in Cubic workflow |
| [config/workflows/ado.toml](../config/workflows/ado.toml) | Built-in ADO workflow |
| [config/workflows/gtd.toml](../config/workflows/gtd.toml) | Built-in GTD workflow |
| [config/workflows/zettelkasten.toml](../config/workflows/zettelkasten.toml) | Built-in Zettelkasten workflow |
| [samples/workflows/project-workflow.toml](../samples/workflows/project-workflow.toml) | Annotated project config template |
| [samples/user-config.toml](../samples/user-config.toml) | Annotated user preferences template |

## Why is the project directory called `.nn/` but the user config is under `notenav/`?

Short name where you see it often, full name where discoverability matters. `.nn/` is concise alongside `.git/` and `.vscode/` in a project root. `~/.config/notenav/` is unambiguous in a directory shared by dozens of tools.

## Can I use `nn` without a `.nn/` directory?

Yes. If there's no `.nn/workflow.toml`, notenav uses your `default_workflow` from `~/.config/notenav/config.toml` (defaults to Zenith) and treats the current directory as the notebook root. This works well for personal notebooks that don't need project-specific configuration.

## Can I use `nn` with Obsidian / Dendron / Jekyll / other tools?

Yes. notenav works with any markdown files that use YAML frontmatter. It reads `type`, `status`, `priority`, and `tags` fields from the frontmatter – the rest of the file is untouched. notenav and Obsidian (or any other tool) can coexist on the same vault without conflicts.

## How do I troubleshoot setup problems?

Run `nn doctor` – it checks all dependencies (versions, variants), validates your config files, verifies workflow integrity (types, statuses, lifecycles), and confirms your notebook is reachable.

```bash
nn doctor
```

If something is wrong, the output tells you exactly what failed and why. Info markers (`[-]`) note optional dependencies that aren't installed; warnings (`[!]`) are non-fatal; failures (`[✗]`) indicate problems that will prevent `nn` from working correctly.

## Why does a note show a yellow "pinned" badge?

You performed an action (advance status, bump priority, change a field) that caused the note to no longer match your active filters. Instead of disappearing, it stays visible in place as a "ghost row" so you can see what you just changed.

Pins accumulate – acting on multiple notes pins all of them. They also survive filter changes, so cycling through types or statuses won't clear them. To dismiss ghost rows, press `x`. A full reset (`R` or `0`) also clears them along with all filters, sort order, grouping, and display settings.

## How do I scope `nn` to a subfolder without `cd`-ing into it?

Use a subshell[^1]:

```bash
(cd ./projects/alpha && nn)
```

This scopes results to the subfolder without changing the working directory in your main shell.

[^1]: Yes, I realize that this did not quite answer the question (see also: [XY problem](https://en.wikipedia.org/wiki/XY_problem)).
