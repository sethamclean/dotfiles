#!/usr/bin/env bash

set -euo pipefail

exec nvim "+lua pcall(function() require('persistence').load() end)"
