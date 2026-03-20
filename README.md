# notenav

TUI faceted browser for [zk](https://github.com/zk-org/zk) notebooks, built on fzf.

Filter notes by frontmatter (type, status, priority, tags), body content, and saved queries. Supports inline actions (status cycling, priority bumping, bulk edits, note creation).

> **Early development** — extracted from a personal zshrc. Not yet packaged for general use.

## Requirements

- zsh
- [zk](https://github.com/zk-org/zk)
- [fzf](https://github.com/junegunn/fzf) (0.44+)
- [bat](https://github.com/sharkdp/bat) (for preview)

## Install

```bash
git clone https://github.com/jqueiroz/notenav.git
export PATH="$PWD/notenav/bin:$PATH"
```

## Usage

```bash
nn                              # faceted browser
nn type=task status=active      # ad-hoc query
nn backlog                      # saved query (from .nn/queries/)
nn type=task -i                 # interactive (fzf) ad-hoc query
nn --version                    # version info
```

## License

MIT
