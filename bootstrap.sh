#!/bin/bash
set -euo pipefail

setup_dotfiles(){
    for package in */; do
        stow $package
    done
}

setup_dotfiles