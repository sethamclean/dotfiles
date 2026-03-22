## OpenCode Session Checkpoint (2026-03-22)

- Confirmed `/root/.config/opencode/opencode.json` is a symlink to `/workspaces/dotfiles/.config/opencode/opencode.json`.
- Confirmed bootstrap instructions from `AGENTS.md` were present at session start, but rule file contents are loaded at runtime (not pre-inlined).
- Observed permission prompt likely came from directory traversal scope (`glob` on folder) vs file-only allow patterns.
- Updated `opencode.json` read permissions to include directory-wide patterns:
  - `~/.llm-rules/**`: `allow`
  - `~/Documents/obsidian-vault/**`: `allow`
- Kept existing markdown-specific rules in place.

### After Restart

1. Restart OpenCode.
2. Re-test by listing `/root/.llm-rules` and reading `rules.md`.
3. If prompts still appear, verify the running process loaded the updated config path.
