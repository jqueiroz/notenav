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

No. [zk](https://github.com/zk-org/zk) is optional. Without it, notenav uses its own frontmatter parser and `rg`/`grep` for body text search. The core experience works – you just lose a few features:

- **Link graph:** the Links/Backlinks sections in the preview pane are skipped (they rely on zk's index)
- **Body text search:** uses `rg` or `grep` instead of zk's indexed `--match` (slower on large notebooks)
- **Note creation:** generates files directly instead of using zk templates
- **Listing performance:** may be slower for very large notebooks (no SQLite index)

Install zk when you want these features. `nn doctor` will tell you whether zk is detected.

## Which notes does `nn` show?

notenav discovers notes by recursively finding all markdown files under the notebook root. When zk is installed, it delegates to `zk list` for faster indexed listing.

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

Or start from the annotated examples: [`samples/user-config.toml`](../samples/user-config.toml) and [`samples/workflows/project-workflow.toml`](../samples/workflows/project-workflow.toml).

## Why is the project directory called `.nn/` but the user config is under `notenav/`?

Short name where you see it often, full name where discoverability matters. `.nn/` is concise alongside `.git/` and `.vscode/` in a project root. `~/.config/notenav/` is unambiguous in a directory shared by dozens of tools.

## Can I use `nn` without a `.nn/` directory?

Yes. If there's no `.nn/workflow.toml`, notenav uses your `default_workflow` from `~/.config/notenav/config.toml` (defaults to Zenith). This works well for personal notebooks that don't need project-specific configuration.

## Can I use `nn` with Obsidian / Dendron / Jekyll / other tools?

Yes. notenav works with any markdown files that use YAML frontmatter. It reads `type`, `status`, `priority`, and `tags` fields from the frontmatter – the rest of the file is untouched. notenav and Obsidian (or any other tool) can coexist on the same vault without conflicts.

## How do I troubleshoot setup problems?

Run `nn doctor` – it checks all dependencies (versions, variants), validates your config files, verifies workflow integrity (types, statuses, lifecycles), and confirms your notebook is reachable.

```bash
nn doctor
```

If something is wrong, the output tells you exactly what failed and why. Info markers (`[-]`) note optional dependencies that aren't installed; warnings (`[!]`) are non-fatal; failures (`[✗]`) indicate problems that will prevent `nn` from working correctly.

## How do I scope `nn` to a subfolder without `cd`-ing into it?

Use a subshell:

```bash
(cd ~/notes/projects/alpha && nn)
```

This scopes results to the subfolder without changing the working directory in your main shell.
