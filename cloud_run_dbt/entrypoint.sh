#!/usr/bin/env bash
set -euo pipefail

# Run a custom command when one is provided, e.g. `dbt debug`.
if [ "$#" -gt 0 ]; then
  exec "$@"
fi

# Install dbt packages only when the project defines them.
if [ -f packages.yml ]; then
  dbt deps
fi

# Default Cloud Run Job command.
dbt build

# Add more sophisticated select later like dbt build --select ...