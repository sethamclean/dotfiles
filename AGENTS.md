# Dotfiles

Seth's dotfiles, deployed into `$HOME` with GNU Stow. This repository is public:
nothing company- or repository-specific belongs here.

`.claude/CLAUDE.md` is the _global_ agent rules file that gets stowed into `~`.
OpenCode has no copy: `.config/opencode/opencode.jsonc` lists
`~/.claude/CLAUDE.md` under `instructions` (OpenCode 2.1.1 did not apply its
documented fallback to that file), so do not add a `~/.config/opencode/AGENTS.md`.
This file is the guidance for working _on_ this repository.

## Layout

- Stow runs from the repository root with `stow --no-folding --target=$HOME .`
  (see `bootstrap.sh`), so each file is linked individually and runtime state
  such as `~/.claude/` credentials and history stays local.
- `.stow-local-ignore` lists what is not linked into `~`, including this file
  and `CLAUDE.md` at the repository root.
- `.claude/skills/` holds the shared skills. OpenCode discovers
  `~/.claude/skills` itself, so there is no per-skill allowlist.
- `.claude/agents/` and `.config/opencode/agents/` hold paired reviewer
  agents; `.hook-scripts/check-agent-sync.zsh` keeps their bodies equal. Both
  copies are needed:
  - OpenCode does not load `~/.claude/agents/`, so it needs its own copy.
  - OpenCode drops an agent whose frontmatter has `tools: Read, Glob, Grep`
    (string or list), so one shared file with both harnesses' frontmatter does
    not work. A symlink between the copies was tried and fails for that reason.
  - Both reviewers read `.claude/skills/change-review/reviews.md` first.
- `.hook-scripts/` holds the `lefthook` pre-commit checks (`.lefthook.yml`).

## Testing changes from a worktree

The links in `~` point at exactly one worktree at a time, and every Claude Code
and OpenCode session on the machine reads through them. Editing the active
worktree changes the running system immediately.

Use `bin/dotfiles-switch` to choose which worktree is live. Do not run `stow`
by hand from a second worktree, and do not restow from the base checkout while
another worktree is live: stow will not take over links that point into another
tree, and a restow from the base would drop work in progress.

```bash
dotfiles-switch                  # which worktree owns how many links
dotfiles-switch <target>         # dry run
dotfiles-switch <target> --apply
```

`<target>` is a worktree path, its directory name, a branch name, or `main`.
It is stowed into `~/bin`, so run it as `dotfiles-switch`.

A switch unstows every other worktree, removes hand-made absolute symlinks into
a worktree (stow does not recognize them), stows the target, and checks for
dangling links. If stowing fails it restores what it removed. It refuses to
apply when a real file is in the way: move the file aside and rerun.

Rules for agents:

- Always dry-run first and read the output. The dry run lists links that will
  be removed, conflicts, and worktrees with uncommitted changes.
- Running `--apply` requires the user's permission each time. It changes the
  live configuration for every session on the machine.
- A new file in the worktree has no link in `~` until the target is applied
  again, because stow links each file individually. Applying again is required
  even when the file is only for testing; do not make the link by hand. Rename
  and delete leave a dangling or missing link in the same way.
- After a switch, the OpenCode background service (`opencode serve --service`)
  keeps its old config until restarted. The script prints its pid but does not
  kill it; ask before stopping it.
- Claude Code reloads most `settings.json` edits live; skills and other files
  may need a new session.

### Cutting over after merge

1. Check the worktree has nothing uncommitted or untracked that should survive
   (`git status`); removing a worktree deletes its untracked files.
2. Merge the branch and update the base checkout's `main`.
3. `dotfiles-switch main` to dry-run, then `dotfiles-switch main --apply`.
4. Confirm `dotfiles-switch` shows the base owning the links and the worktree
   owning none, then `git worktree remove` the worktree and delete the branch.

Removing a worktree before step 3 leaves dangling links in `~` and the tools
start with no configuration.

## Conventions

- Do not commit, push, or amend unless asked.
- Shell scripts follow the style of the existing `.hook-scripts/*.zsh`.
