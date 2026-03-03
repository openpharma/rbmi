#!/usr/bin/env bash
set -euo pipefail

Rscript - <<EOF
    options(crayon.enabled = TRUE, cli.dynamic = FALSE)
    devtools::document()
EOF

if [ -n "${GITHUB_ACTIONS:-}" ]; then
    git config --global --add safe.directory /__w/rbmi/rbmi
fi
if [ -z "$(git status --porcelain)" ]; then
    echo "Is Clean"
else
    echo "Changed Detected"
    # Print the status so user can see it in log
    git status
    exit 2
fi
