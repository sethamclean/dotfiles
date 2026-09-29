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

## Global Python Tooling Config

These dotfiles include global config files for `ty` and `ruff`:

- `~/.config/ty/ty.toml`
- `~/.config/ruff/pyproject.toml`

They are managed from this repo at:

- `.config/ty/ty.toml`
- `.config/ruff/pyproject.toml`

Project-level config still takes precedence when present (for example, a local `ty.toml`, `pyproject.toml`, or `ruff.toml` in a project).

## Jira ACLI Wrapper

The `bin/jira-acli` script wraps `acli jira` with consistent auth/context and agent-friendly help.

### Environment

- `JIRA_USERNAME` (required)
- `JIRA_API` (required)
- `JIRA_SERVER` (optional, defaults to `https://example.atlassian.net`)

### Help and metadata

- `jira-acli --help` for deterministic human-readable help sections.
- `jira-acli --help-json` for machine-readable command metadata.

### Common usage

```bash
jira-acli issue PROJ-201
jira-acli project
jira-acli jql "project = PROJ ORDER BY updated DESC"
jira-acli create --project PROJ --type Story --summary "Add wrapper"
jira-acli update PROJ-201 --priority High --labels platform,automation
jira-acli transitions PROJ-201
jira-acli status PROJ-201 "In Progress"
```

### Notes

- Wrapper-managed commands default to JSON output; use `--text` for pretty-printed JSON.
- `raw` passes arguments directly to `acli jira` while still injecting `--server`, `--user`, and `--token`.
- `--dry-run` prints resolved commands with token values redacted.

## Terraform Cloud CLI Helper

The `bin/tfc-cli` script provides read-only Terraform Cloud visibility scoped to
project `example-project`.

### Environment

- `TFC_RO` (required)
- `TFC_ORG` (optional, defaults to `example`)
- `TFC_BASE_URL` (optional, defaults to `https://app.terraform.io`)

### Commands

- `tfc-cli workspaces [--limit N]`
- `tfc-cli runs [--workspace NAME] [--limit N]`
- `tfc-cli errors [--workspace NAME] [--limit N]`
- `tfc-cli attention [--workspace NAME] [--limit N]`
- `tfc-cli plan-analyze [--plan PLAN_ID | --run RUN_ID | --workspace NAME --latest]`
- `tfc-cli plan-log [--plan PLAN_ID | --run RUN_ID | --workspace NAME --latest] [--raw]`
- `tfc-cli workspace-impact [--limit N]`
- `tfc-cli run <RUN_ID>`
- `tfc-cli plan <PLAN_ID>`
- `tfc-cli apply <APPLY_ID>`

Use `--json` with any command to output raw API payload JSON.

Use `--markdown` with `tfc-cli plan-analyze` for one-workspace review output
that is easy to paste into PRs or Slack.

Use `tfc-cli plan-log` to view the actual Terraform plan log output:
- default renders a focused summary (planned changes + drift) then full human-readable log messages
- `--raw` prints newline-delimited Terraform JSON log events
- `--json` prints parsed JSON array of plan log events

`tfc-cli attention` reasons:
- `error` - run status is `errored`, `failed`, or canceled variants
- `pending_run` - run status is `pending`
- `pending_apply` - non-speculative run with changes waiting for confirm/apply
- `speculative_plan_changes` - speculative (`plan-only`) run found changes

`tfc-cli plan-analyze` and `tfc-cli workspace-impact` support gating flags:
- `--fail-on-non-import`
- `--fail-on-drift`

`tfc-cli plan-analyze` also supports strict classification:
- `--strict` uses plan JSON output to classify exact changed attributes
- distinguishes import-only vs repo archived-only flips vs unexpected config/ruleset/non-repo changes
- excludes `actions=["no-op"]` from strict unexpected counts
- includes `safe_to_apply_strict` in JSON/markdown/text output

If a selected gate condition is found, command exits non-zero.

### Examples

```bash
tfc-cli workspaces
tfc-cli runs --limit 20
tfc-cli runs --workspace workspace-c --limit 10
tfc-cli errors --workspace workspace-a --limit 30
tfc-cli attention --limit 100
tfc-cli attention --workspace workspace-a --limit 50
tfc-cli attention --reason pending_apply --limit 100
tfc-cli plan-analyze --workspace workspace-a --latest
tfc-cli plan-analyze --workspace workspace-a --latest --strict
tfc-cli --markdown plan-analyze --workspace workspace-a --latest
tfc-cli plan-log --workspace workspace-a --latest
tfc-cli plan-log --run run-abc123 --raw
tfc-cli --json plan-log --plan plan-def456
tfc-cli plan-analyze --run run-abc123 --fail-on-drift
tfc-cli workspace-impact --limit 100 --fail-on-non-import --fail-on-drift
tfc-cli run run-abc123
tfc-cli plan plan-def456
tfc-cli apply apply-ghi789
tfc-cli --json runs --workspace workspace-b --limit 5
```
