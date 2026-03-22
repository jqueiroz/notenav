# notenav

TUI faceted browser for [zk](https://github.com/zk-org/zk) notebooks, built on fzf.

## Repo Layout

```
bin/nn              # Entry point: resolves root, sources lib, calls notenav_main
lib/notenav.sh      # Full implementation (~1700 LOC)
config/
  base.toml        # Base config (ships with notenav; user/project configs overlay on top)
  workflows/       # Built-in workflows: compass, ado, gtd, zettelkasten
curl/
  install.sh       # curl-pipe-sh installer script
docs/
  install.md          # Full install instructions (requirements, all methods)
  configuration.md    # Config system + workflow reference
  faq.md              # Frequently asked questions
  workflows/          # Per-workflow documentation (compass.md, ado.md, etc.)
samples/
  user-config.toml      # Example ~/.config/notenav/config.toml
  workflows/            # Example .nn/workflow.toml files
.claude/
  commands/           # Claude Code slash commands (best-practices, review-config, etc.)
flake.nix           # Nix package definition
CLAUDE.md           # This file
GUIDELINES.md       # Development guidelines
README.md           # Public-facing README
LICENSE             # MIT
```

## Three Operating Modes

1. **Faceted browser** (`nn` with no args) – full TUI with filters, query presets, inline actions
2. **Named query** (`nn <name>`) – runs a query preset by name
3. **Ad-hoc query** (`nn key=value ...`) – filters notes by frontmatter fields; `-i` for interactive mode

## Data Flow

1. `zk list` outputs TSV: `type \t status \t priority \t tags \t title \t absPath \t modified \t created`
2. `filter.sh` applies awk conditions based on current filter state
3. Colored output piped to fzf via `.current` file
4. Actions update frontmatter in-place via `action.sh`, then regenerate `.raw` and re-filter

## Config System

Project config (`.nn/workflow.toml`) and user config (`~/.config/notenav/config.toml`) are orthogonal – project defines the workflow, user defines personal preferences. See [docs/configuration.md](docs/configuration.md) for full reference.

The merged config is stored in `NN_CFG_JSON` and queried via `nn_cfg '.path.to.value'`.

## Testing

```bash
which nn                                      # should show bin/nn path
nn --version                                  # notenav 0.1.0-dev
nn doctor                                     # check dependencies, config, notebook

cd ~/Writing/obsidian-johnjq
nn                                            # interactive TUI
nn type=task                                  # ad-hoc query
nn backlog                                    # query preset
nn type=task -i                               # interactive ad-hoc
```

## Key References

- [GUIDELINES.md](GUIDELINES.md) – development conventions (architecture, shell scripting, keybindings, naming, config, docs, standards, **audit command inventory**)
- [docs/configuration.md](docs/configuration.md) – config system, workflow reference, and preferences
- [docs/faq.md](docs/faq.md) – directory discovery, note scoping, config file locations
- [docs/install.md](docs/install.md) – requirements and installation methods
- [README.md](README.md) – user-facing overview, getting started, keybindings

When adding, renaming, or removing slash commands in `.claude/commands/`, update the audit command table in [GUIDELINES.md](GUIDELINES.md#audit-commands).
