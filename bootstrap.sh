#!/bin/bash
set -euo pipefail

setup_dotfiles(){
    for package in */; do
        stow --no-folding --target=${HOME} ${package}
    done
}

setup_dotfiles
