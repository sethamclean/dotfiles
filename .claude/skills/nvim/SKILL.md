---
name: nvim
description: Read and control a running Neovim, such as the editor in a
  neighbouring tmux pane, with `nvim --server`. Use when the user asks what is
  open in nvim, which file or line they are on, what the selection or
  diagnostics are, or to open a file or jump to a line in their editor. To
  start nvim in a pane or type into one, use the tmux skill.
license: Original text
---

# nvim

Talk to a running Neovim over its RPC socket with the `nvim` CLI. Tested on
Neovim 0.12.6. The editor is the user's own work.

## Rules

- Reading (`--remote-expr` with a query) is free once the user has pointed at
  the editor. Changing it (`--remote-send`, `--remote`, or an expression with
  side effects) only when the user asks.
- Never run `:w`, `:q`, `:bd`, `:%d`, or a `:!` command unless the user names
  it. Buffers can hold unsaved work; check `changed` before switching away.
- Do not type into the editor with `tmux send-keys`; use the socket.
- Editor text can hold secrets. Quote only the lines that matter.

## Find the socket

Inside a Neovim `:terminal`, `$NVIM` holds the socket path. From another pane,
the server is a descendant of the pane's process with `--embed` in its
arguments (a child of the pane process when nvim was started directly, a
grandchild when started from a shell). Find the descendant, then the socket it
listens on:

```bash
pane=%8    # the pane running nvim; get ids from the tmux skill
pid=$(tmux display-message -p -t "$pane" '#{pane_pid}')
ps -e -o pid=,ppid=,args= | awk -v root="$pid" '
  {p[$1]=$2; a[$1]=$0}
  END{for(i in p){x=i; while(x in p){ if(p[x]==root){ if(a[i] ~ /nvim.* --embed/) print i; break } x=p[x] }}}' |
while read -r n; do ss -xlp | grep -F "pid=$n," | grep -o '/[^ ]*nvim\.[0-9]*\.0'; done
```

It prints one socket path per editor in the pane. Set `sock` to it, and
confirm with `nvim --server "$sock" --remote-expr 'v:servername'`. If nothing
prints, or the pane does not run nvim, ask. Several paths mean several
editors; ask which. `ss` and `ps` are the only tools used (no `pstree`).

To get a fixed path, the user or you can start nvim with
`nvim --listen /tmp/nvim-work.sock`.

## Read

`--remote-expr` prints the result with no trailing newline. A list or dict
prints as `table: 0x...`, so wrap those in `luaeval` with `vim.json.encode`.

```bash
nvim --server "$sock" --remote-expr 'expand("%:p")'      # current file
nvim --server "$sock" --remote-expr 'getcwd()'
nvim --server "$sock" --remote-expr 'line(".")'           # cursor line
nvim --server "$sock" --remote-expr 'mode()'              # n, i, v, ...
nvim --server "$sock" --remote-expr 'join(getline(1,20), "\n")'    # lines 1-20
nvim --server "$sock" --remote-expr 'execute("ls")'       # buffer list text
nvim --server "$sock" --remote-expr \
  'luaeval("vim.json.encode(vim.tbl_map(function(b) return {b.bufnr, b.name, b.changed} end, vim.fn.getbufinfo({buflisted=1})))")'
nvim --server "$sock" --remote-expr 'luaeval("vim.json.encode(vim.diagnostic.count(0))")'
nvim --server "$sock" --remote-expr 'luaeval("#vim.lsp.get_clients({bufnr=0})")'    # attached LSP clients
```

Visual selection: `getpos("v")` and `getpos(".")` give the two ends while in
visual mode; `getregion(getpos("v"), getpos("."), {"type": mode()})` returns
the text. In normal mode it fails with `E475: Invalid value for argument type: n`.
The visual-mode call was not run here.

A failing expression exits 2 and prints a Lua error naming the Vim error, for
example `E117: Unknown function`.

## Change

```bash
nvim --server "$sock" --remote /path/to/file       # open a file in the current window
nvim --server "$sock" --remote-send '<C-\><C-N>:call cursor(120,1)<CR>'    # jump to a line
```

- Start `--remote-send` with `<C-\><C-N>` so an editor in insert mode returns
  to normal mode before the `:` command. Without it, the keys are typed into
  the buffer.
- `--remote-send` is asynchronous and runs as typed keys. Sleep 0.3 s, then
  read back (`expand("%:p")`, `line(".")`) to confirm.
- A `--remote` of a path while the current buffer has unsaved changes may fail
  or hide the buffer; check `changed` first.
