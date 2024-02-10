#!/bin/bash
set -euo pipefail

flags=${1-}
stow ${flags} --no-folding --target=${HOME} .

