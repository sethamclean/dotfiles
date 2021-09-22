#!/bin/bash
set -euo pipefail

setup_dotfiles(){
    for package in */; do
        stow --target=${HOME} ${package}
    done
}

setup_dotfiles