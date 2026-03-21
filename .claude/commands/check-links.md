Review all internal links in the repository's markdown files and ensure none are broken.

For every `.md` file in the repo, find all markdown links (`[text](path)`) and verify:

1. **Relative file links** — the target file exists at the resolved path
2. **Anchor links** (`#section`) — the target heading exists in the linked file
3. **Image links** — any referenced images exist

Report:
- Each broken link with the source file, line number, and target path
- A summary count of total links checked vs broken

Do NOT check external URLs (http/https) — only local file references.
