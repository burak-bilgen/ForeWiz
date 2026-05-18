#!/bin/bash
# check_lazy_tr.sh — Fails CI if any TR localization is a lazy lowercase copy of EN.
# Usage: bash scripts/check_lazy_tr.sh
# Returns exit code 1 if issues found, 0 if clean.

set -e

XCSTRINGS="ForeWiz/Core/Localization/Localizable.xcstrings"

if [ ! -f "$XCSTRINGS" ]; then
  echo "ERROR: $XCSTRINGS not found. Run from project root."
  exit 1
fi

FAILURES=$(python3 -c "
import json, sys

with open('$XCSTRINGS') as f:
    data = json.load(f)

fail = 0
for key, val in data['strings'].items():
    locs = val.get('localizations', {})
    en = locs.get('en', {}).get('stringUnit', {}).get('value', '')
    tr = locs.get('tr', {}).get('stringUnit', {}).get('value', '')

    # Skip format-only keys and structural artifacts
    if key in ('en', 'tr', 'localizations', 'strings', 'stringUnit'):
        continue
    if key.startswith('%') or key.startswith('\\\\'):
        continue

    # Check for lazy lowercase TR (TR is lowercase copy of EN)
    if tr and len(tr) > 3 and tr.islower() and en.lower() == tr.lower():
        print(f'LAZY_TR|{key}|EN: \"{en}\"|TR: \"{tr}\"')
        fail += 1

    # Check for missing Turkish characters where they should exist
    turkish_patterns = ['disarida', 'disari', 'Sehir', 'sehir', 'Güvenligi', 'kaynagi', 'yürüyüs', 'isler', 'kisa', 'kosullari', 'degil', 'batimini', 'isareti', 'aralik', 'planini', 'planlari']
    for pattern in turkish_patterns:
        if pattern in tr:
            print(f'BAD_CHAR|{key}|TR: \"{tr}\" (contains \"{pattern}\")')
            fail += 1
            break

sys.exit(1 if fail else 0)
" 2>&1) || true

if [ -n "$FAILURES" ]; then
  echo "❌ Lazy/broken Turkish translations detected:"
  echo "$FAILURES"
  echo ""
  echo "Fix the TR values in $XCSTRINGS to use proper Turkish."
  exit 1
fi

echo "✅ All Turkish translations pass lazy/bad-char check"
exit 0
