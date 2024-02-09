#!/bin/bash
set -euo pipefail

dest=${XDG_CONFIG_HOME-$HOME/.config}

flags=${1-}
stow ${flags} --no-folding --target=${HOME} zshenv 
stow ${flags} --no-folding --target=${dest} .config

