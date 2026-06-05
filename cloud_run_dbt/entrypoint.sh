#!/usr/bin/env bash
set -euo pipefail
dbt deps
dbt debug
dbt build

# Add more sophisticated select later like dbt build --select ...