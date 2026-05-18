#!/bin/bash
# check_localization_completeness.sh — Wrapper for check_localization_completeness.py
set -euo pipefail

cd "$(dirname "$0")/.."
python3 scripts/check_localization_completeness.py
