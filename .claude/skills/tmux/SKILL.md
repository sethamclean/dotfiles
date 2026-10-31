---
name: tmux
description: Find, read, search, and type into tmux panes with the tmux CLI.
  Use when the user asks to look at, find, or search another pane, window, or
  session, to open a file or run a command in a neighbouring pane, or to
  drive an interactive CLI (REPL, debugger) through tmux. For agents and
  worktrees managed by workmux, use the workmux skill instead.
license: Original text; see sources.md
metadata:
  source-repository: https://github.com/mitsuhiko/agent-stuff
  source-path: skills/tmux/SKILL.md
  adapted-on: '2026-10-31'
  adaptation-record: sources.md
---

# tmux

Drive tmux with its CLI. The commands below act on the user's default tmux
server, so every pane is the user's own work.

## Rules

- Read the panes of this window freely. Read other sessions, which can belong
  to other Tasks, only when the user asks. Type into a pane, or kill anything,
  only when the user asks.
- Address panes by id (`%5`), not by index; indexes shift. Resolve the id again
  before each send.
- Never send to your own pane: compare the target with `$TMUX_PANE`.
- Before typing, check `#{pane_current_command}` with `list-panes` and capture
  the pane to confirm an empty prompt: a shell can hold half-typed input. Send
  only to an idle shell, or to the program the user named. Do not type into a
  pane running another agent or an editor unless asked.
- `kill-pane`, `kill-window`, `kill-session`, and `kill-server` are
  destructive. Ask first and name the target.
- Pane text can hold secrets. Quote only the lines that matter.

## Find panes

```bash
tmux display-message -p '#{pane_id}'    # this pane ($TMUX_PANE holds the same)
tmux list-panes -F '#{pane_id} #{pane_active} #{pane_current_command} #{pane_current_path}'    # this window
tmux list-panes -a -F '#{pane_id} #{session_name}:#{window_index}.#{pane_index} #{pane_current_command} #{pane_current_path}'    # every session; only when asked
```

"The split next to this one" is the other pane in this window: the row where
`pane_id` differs from `$TMUX_PANE`. With more than two panes, add
`#{pane_left} #{pane_top} #{pane_width} #{pane_height}` to the format and pick
the pane that touches this one; ask if that is still unclear.

## Search panes

Search the last 2000 lines of every other pane in this window for a regex. Each
match is prefixed with its pane id and line number and cut to 200 characters;
drop `-i` for a case-sensitive search. This pane is skipped because it holds
the pattern.

```bash
pat='error|panic'
tmux list-panes -F '#{pane_id}' | while read -r p; do
  [ "$p" = "$TMUX_PANE" ] && continue
  tmux capture-pane -p -J -t "$p" -S -2000 | grep -n -i -E -- "$pat" | cut -c1-200 | sed "s/^/$p:/"
done
```

Use `grep -C 3` for context. When the user asks to search every session, use
`list-panes -a`. Panes
running a full-screen program (Neovim, another agent) can match on screen
furniture; read the pane to confirm.

## Read output

```bash
tmux capture-pane -p -J -t %5 -S -200    # last 200 lines, wrapped lines joined
tmux capture-pane -p -t %5               # visible screen only
```

## Send input

```bash
tmux send-keys -t %5 -l -- 'nvim notes.md'    # literal text, no key-name parsing
tmux send-keys -t %5 Enter
tmux send-keys -t %5 C-c                      # control keys by name, e.g. Escape
```

- Send control keys such as `C-c` and `C-d` only to a program you started or
  the user named. `C-d` to a shell exits it and should close the pane; never
  send it to one.
- A shell prompt takes the text and `Enter` in one `Bash` call. For a TUI, send
  them as separate `tmux` invocations with `sleep 0.3` between: a TUI may read
  a fast text-plus-Enter as a paste and not submit it (unverified here).
- Capture the pane afterwards to confirm the result; do not assume it worked.

## Wait for output

Poll for text instead of sleeping a fixed time. `tmux wait-for` does not watch
pane output.

```bash
for _ in $(seq 30); do
  tmux capture-pane -p -J -t %5 -S -50 | grep -q -E -- '^>>> ' && break
  sleep 0.5
done
```

## Background sessions

To run something the user did not ask to see among their panes, use a private
socket and tell the user how to watch it, right after starting it and again at
the end:

```bash
SOCK=${TMPDIR:-/tmp}/claude-tmux.sock    # or the session scratchpad, if the harness names one
tmux -S "$SOCK" new -d -s job -n shell
tmux -S "$SOCK" send-keys -t job: -l -- 'python3 -q'
tmux -S "$SOCK" send-keys -t job: Enter
# watch: tmux -S "$SOCK" attach -t job
# once:  tmux -S "$SOCK" capture-pane -p -J -t job: -S -200
tmux -S "$SOCK" kill-session -t job    # when done
```

- `job:` means the session's active pane. Window numbers depend on the user's
  `base-index`, so do not write `job:0.0`.
- Set `PYTHON_BASIC_REPL=1` before starting a Python shell; the default console
  interferes with `send-keys`.
- For agents in their own worktree and tmux session, use the `workmux` skill.
