---
name: nvim-debug
description: Debug a program in the user's running Neovim through its nvim-dap
  setup, from the outside over the nvim socket. Use when the user asks to set a
  breakpoint, run or debug the current file or a test in nvim, step over, into
  or out, continue, inspect variables or the stack, or evaluate an expression
  at a stop. Go (Delve) and Python (debugpy) are tested; Rust (codelldb) is
  configured. Needs the nvim skill to find the editor's socket.
license: Original text
---

# nvim-debug

Drives `nvim-dap` (with `nvim-dap-ui`) in a running Neovim, using the
[nvim](../nvim/SKILL.md) skill to find the socket. The setup is in
`/workspaces/dotfiles/.config/nvim/lua/seth/packages/debugging.lua`: Go through
Delve, Python through `debugpy`, Rust through `codelldb`. The editor, the
breakpoints and the debugged program are the user's own.

## Rules

- Start, step, or stop a debug session only when the user asks. `run` builds and
  executes their program.
- Breakpoints you set stay in the user's editor. Remove them with `unbreak`
  when the task is done. `clear` deletes every breakpoint, including the user's;
  use it only when asked.
- `run` starts from the current buffer: `${file}` and the filetype come from
  it. Open the file first with `--remote` (nvim skill) and check
  `expand("%:p")`. Do not switch away from a buffer with unsaved changes.
- `eval` runs code in the debugged program and can change its state. Use
  expressions without side effects unless the user asks for one.
- Program and variable values can hold secrets. Quote only what matters.

## Set up

Get `$sock` as in the nvim skill, then define the helper. It passes each
argument to `dbg.lua` and prints one line of JSON:

```bash
DBG=$HOME/.claude/skills/nvim-debug/dbg.lua
dbg() {    # dbg <op> [args...]
  local a="['$DBG'"; for x in "$@"; do a+=", '${x//\'/\'\'}'"; done; a+=']'
  nvim --server "$sock" --remote-expr "luaeval('dofile(_A[1])(unpack(_A, 2))', $a)"; echo
}
```

## Operations

Actions (`run`, `continue`, `over`, `into`, `out`, `pause`, `terminate`) block
until the program stops or the session ends, for up to 15 s, and return the new
state. The other operations return at once.

| Op | Effect |
| --- | --- |
| `break <path>:<line> [condition]` | set or replace a breakpoint; returns all breakpoints |
| `logpoint <path>:<line> '<message {expr}>'` | log instead of stopping |
| `unbreak <path>:<line>` | remove one breakpoint |
| `breakpoints` | list them |
| `exceptions <filters>` | stop on exceptions: `raised,uncaught` for `debugpy` |
| `configs [filetype]` | launch configurations for the current buffer's filetype |
| `run '<config name>'` | start a session and wait for the first stop |
| `continue`, `over`, `into`, `out` | resume or step; wait for the next stop |
| `pause`, `terminate` | stop the running program, end the session |
| `state` | session, stopped or running, frame with source line |
| `stack` | frames, the current one marked |
| `up`, `down` | move the current frame |
| `locals` | variables of each non-expensive scope; `ref` marks expandable ones |
| `expand <ref>` | children of a variable, valid only until the next resume |
| `eval '<expression>'` | evaluate in the current frame |

The state has `event`: `stopped`, `exited`, `terminated`, or `timeout` (the
program is still running). A `stopped` state carries `frame` (`name`, `line`,
`path`, `text`); `output` holds adapter and logpoint output received during the
action.

## Workflow

1. Open the file in the editor and confirm the current buffer. Run `state`:
   if a session is live, it is the user's; ask before `terminate`, because a
   second `run` would start a parallel session.
2. `break` at the lines of interest; `configs` to see the names;
   `run '<name>'`.
3. At each stop read `frame`, then `locals` or `eval` to inspect; choose
   `over`, `into`, `out`, or `continue`.
4. Stop at the end: `terminate` if the session is live, `unbreak` the
   breakpoints you set. Report what you observed, with the file and line.

Example, Go (`Delve: Debug` runs the package of the current file):

```bash
dbg break /work/app/main.go:12 'x == 2'
dbg run 'Delve: Debug'      # {"event":"stopped","frame":{"name":"main.main","line":12,...}}
dbg eval 'x'                # {"result":"2","type":"int"}
dbg into; dbg locals; dbg out; dbg continue
```

## Languages

- Go: configurations `Delve: Debug`, `Delve: Debug (Arguments)`,
  `Delve: Debug test`, `Delve: Debug test (go.mod)`. The program's own stdout
  was not captured over the socket; use `eval` or a `logpoint` to see values.
  Stepping out of `main` continues into the Go runtime sources; `continue`
  instead.
- Python: `Python: Launch file`. Logpoint messages arrive in `output`.
- Rust: `LLDB: Launch`. Its `program` function runs `cargo build` inside
  Neovim and blocks it; this path was not run here.
- Not run here: `pause`, `up`, `down`, and `exceptions` against a program that
  raises.
- Other filetypes: `configs` lists nothing; say so and stop.

## Failures

- `{"error":"no debug session"}`: nothing is running; `run` first.
- `{"error":"program is running, not stopped"}`: wait with `state`, or `pause`.
- `{"error":"no configuration named ..."}` lists the names that exist. The
  filetype is the current buffer's.
- `event: timeout` after `run` or `continue`: the program is still running (a
  server, a long loop, or a build). `state` to check, `pause` or `terminate`.
- The editor may show the dap-ui layout opening and closing; that is the user's
  `dapui` listeners, not an error.
