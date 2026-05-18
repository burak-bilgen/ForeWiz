#!/bin/bash
# check_hardcoded_strings.sh
# CI guard: fails if any Swift file contains hardcoded user-facing strings
# Ignores: logs, comments, debug-only code, localized strings via L10n

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

SRC_DIR="${1:-ForeWiz}"
EXIT_CODE=0

# Patterns that indicate hardcoded user-facing strings
# These are likely mistakes vs. using L10n.text/L10n.formatted
echo "🔍 Scanning for hardcoded user-facing strings..."

# Check for string literals used directly with Text() or Label()
violations=$(grep -rn 'Text("' "$SRC_DIR" --include="*.swift" 2>/dev/null | \
  grep -v 'L10n\.\|accessibility\|\.strings\|import\|//\|print\|Logger\|OSLog\|AppLogger' | \
  grep -v '"/' | grep -v '"_"' || true)

# Check for String(format: with hardcoded strings
violations2=$(grep -rn 'String(format:' "$SRC_DIR" --include="*.swift" 2>/dev/null | \
  grep -v 'L10n\.\|//.*String' || true)

if [ -n "$violations" ]; then
  echo -e "${RED}❌ Potential hardcoded strings in Text():${NC}"
  echo "$violations"
  EXIT_CODE=1
fi

if [ -n "$violations2" ]; then
  echo -e "${RED}❌ Potential hardcoded String(format:) usage:${NC}"
  echo "$violations2"
  EXIT_CODE=1
fi

# Check for Label("
violations3=$(grep -rn 'Label("' "$SRC_DIR" --include="*.swift" 2>/dev/null | \
  grep -v 'L10n\.\|accessibility\|import\|//' || true)

if [ -n "$violations3" ]; then
  echo -e "${RED}❌ Potential hardcoded strings in Label():${NC}"
  echo "$violations3"
  EXIT_CODE=1
fi

if [ $EXIT_CODE -eq 0 ]; then
  echo -e "${GREEN}✅ No hardcoded user-facing strings detected${NC}"
fi

exit $EXIT_CODE
