#!/usr/bin/env python3
"""check_localization_completeness.py
CI script: checks that all localization keys referenced in code exist
in the xcstrings file, and that no EN key is missing its TR translation.
Handles both modern (top-level keys) and legacy (data['strings']) xcstrings formats.
"""

import json
import os
import re
import sys

SRC_DIR = os.environ.get("SRC_DIR", "ForeWiz")
XCSTRINGS = "ForeWiz/Core/Localization/Localizable.xcstrings"

if not os.path.exists(XCSTRINGS):
    print(f"ERROR: {XCSTRINGS} not found")
    sys.exit(1)

with open(XCSTRINGS) as f:
    data = json.load(f)

# Keys can be at the top level (modern) OR inside data['strings'] (legacy)
top_keys = set()
if "strings" in data and isinstance(data["strings"], dict):
    top_keys.update(data["strings"].keys())
for k in data.keys():
    if k not in ("sourceLanguage", "version", "strings"):
        top_keys.add(k)

def get_localization(key):
    """Get localizations for a key from either storage location."""
    entry = data.get(key)
    if entry is None and "strings" in data:
        entry = data["strings"].get(key)
    if entry is None:
        return {}
    if "localizations" in entry:
        return entry["localizations"]
    return {}

code_keys = set()
search_dirs = [SRC_DIR, "Packages"]
for s_dir in search_dirs:
    if os.path.exists(s_dir):
        for root, dirs, files in os.walk(s_dir):
            for fname in files:
                if not fname.endswith(".swift"):
                    continue
                path = os.path.join(root, fname)
                try:
                    with open(path) as sf:
                        content = sf.read()
                except Exception:
                    continue
                code_keys.update(re.findall(r'L10n\.text\(["\']([^"\']+)["\']\)', content))
                code_keys.update(re.findall(r'L10n\.formatted\(["\']([^"\']+)["\']\)', content))
                code_keys.update(re.findall(r'WizPathKitL10n\.text\(["\']([^"\']+)["\']\)', content))
                code_keys.update(re.findall(r'WizPathKitL10n\.formatted\(["\']([^"\']+)["\']\)', content))

fail = 0

missing_from_loc = code_keys - top_keys
if missing_from_loc:
    print("❌ Keys in code but missing from xcstrings:")
    for k in sorted(missing_from_loc):
        print(f"   {k}")
    fail += 1

dead_keys = top_keys - code_keys - {"strings", "sourceLanguage"}
if dead_keys:
    print("⚠️  Keys in xcstrings but NOT referenced in code:")
    for k in sorted(dead_keys):
        print(f"   {k}")

for key in top_keys:
    locs = get_localization(key)
    en_val = locs.get("en", {}).get("stringUnit", {}).get("value", "")
    tr_val = locs.get("tr", {}).get("stringUnit", {}).get("value", "")
    if en_val and not tr_val:
        print(f'❌ Key "{key}" has EN but missing TR translation')
        fail += 1
    if tr_val and not en_val:
        print(f'⚠️  Key "{key}" has TR but missing EN translation')

sys.exit(1 if fail else 0)
