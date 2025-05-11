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

