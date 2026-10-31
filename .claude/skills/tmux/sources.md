# Sources and adaptation

The `tmux` skill is adapted from a third-party skill. This file is the provenance record that the skill definition's `metadata` points to.

## Provenance

Repository: [mitsuhiko/agent-stuff](https://github.com/mitsuhiko/agent-stuff). Path: `skills/tmux/SKILL.md`. Adapted: 2026-10-31. Upstream commit not recorded; the file was downloaded from `main` that day.

## License

The upstream `SKILL.md` declares `license: Vibecoded`, which is not a recognised license. The repository's root `LICENSE` is Apache License 2.0, with the copyright owner left as a template placeholder (read through a summarising fetch, not checked against the raw file). The two do not agree, so this record does not rely on either.

The wording is original and no upstream script is copied; the commands are standard tmux, and the background-session example follows the shape of upstream's quickstart. What it takes from upstream is the approach: drive panes with `send-keys -l`, read them with `capture-pane -p -J`, poll for text instead of `tmux wait-for`, use a private socket for background sessions, and set `PYTHON_BASIC_REPL=1`.

The guidance to send `Enter` separately for TUIs is not from upstream, whose own examples send text and `Enter` together. It comes from search-result summaries of other community tmux skills (for example the openclaw variant), which were not read in full, and has not been tested here; the skill marks it unverified.

The skill text is original to this repository and carries no third-party licence; the repository has no `LICENSE` file. Ideas and commands are not copyrightable, but if the license question matters, resolve it with the upstream author.

## What was changed

- Default target is the user's own tmux server and panes, not a private socket; the private socket is kept for background sessions only.
- Added rules that upstream lacks: address panes by id, never send to the agent's own pane, check what the pane is running and its prompt before typing, restrict control keys, ask before any `kill-*`, treat pane text as possibly secret, and read other sessions only when asked (they can belong to other Tasks).
- Added finding panes (including "the split next to this one") and searching the contents of every pane. Upstream finds sessions by name and polls one pane.
- Replaced the `find-sessions.sh` and `wait-for-text.sh` helper scripts with inline commands, so the skill has no files to deploy.
- Dropped the lldb default, the gdb recipe, and the requirement to print monitor commands after every session.
