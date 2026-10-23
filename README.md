# Dotfiles

Seth McLean's dotfiles

## Prerequisites

### Required Dependencies

- `git` - Version control and dotfiles management
- `stow` - Symlink management for dotfiles
- `zsh` - Shell environment
- `nvim` - Text editor (Neovim)
- `shellcheck` - Shell script linting (used in pre-commit hooks)

### Optional Dependencies

- `tmux` - Terminal multiplexer for managing terminal sessions
- `bat` - Better cat with syntax highlighting
- `fzf` - Fuzzy finder for command line
- `ripgrep` (rg) - Fast text search
- `fd` - User-friendly alternative to find

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/.dotfiles
   cd ~/.dotfiles
   ```

2. Install required dependencies:

   ```bash
   # On Ubuntu/Debian
   sudo apt update
   sudo apt install git stow zsh tmux neovim shellcheck

   # On macOS with Homebrew
   brew install git stow zsh tmux neovim shellcheck
   ```

3. Run the bootstrap script:
   ```bash
   ./bootstrap.sh
   ```

## Machine-Local Git Config

`.config/git/config` holds shared settings only. It includes
`~/.config/git/local.gitconfig`, which is not tracked, for work identity, org
URL aliases, and other machine-specific settings. Git skips the include when
the file is missing.

`bootstrap.sh` does not create it. A private overlay (for example a codespace
repo's post-create script) can drop it in place after the dotfiles bootstrap.
In Codespaces, `user.email` also comes from `/etc/gitconfig`.

## Global Python Tooling Config

These dotfiles include global config files for `ty` and `ruff`:

- `~/.config/ty/ty.toml`
- `~/.config/ruff/pyproject.toml`

They are managed from this repo at:

- `.config/ty/ty.toml`
- `.config/ruff/pyproject.toml`

Project-level config still takes precedence when present (for example, a local `ty.toml`, `pyproject.toml`, or `ruff.toml` in a project).

## Claude Code Config

These dotfiles manage Claude Code's user-level config:

- `~/.claude/settings.json` - user settings
- `~/.claude/CLAUDE.md` - global instructions loaded in every session
- `~/.claude/themes/catppuccin.json` - custom theme matching OpenCode's `catppuccin`, selected as
  `custom:catppuccin`

They are managed from this repo under `.claude/`. Stow links individual files (`--no-folding`), so runtime
state in `~/.claude/` (credentials, history, projects, sessions, plugins)
stays local and untracked.

Claude Code creates a real `~/.claude/settings.json` on first run, which
conflicts with the stow link. Move it aside before running `./bootstrap.sh`:

```bash
mv ~/.claude/settings.json ~/.claude/settings.json.backup.$(date +%Y%m%d%H%M%S)
```

`~/.claude/settings.json` is the only user-level settings file; there is no
user-level `settings.local.json`. Per-project personal overrides go in
`<repo>/.claude/settings.local.json`, which stays out of git.
