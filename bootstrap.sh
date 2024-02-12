#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
flags=${1-}
stow ${flags} --no-folding --target=${HOME} .

