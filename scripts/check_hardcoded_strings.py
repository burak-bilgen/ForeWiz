#!/usr/bin/env python3
"""check_hardcoded_strings.py
CI script: finds hardcoded user-facing strings in Swift files.
Reports likely violations where Text(" or Label(" are used without L10n.
"""

import os
import re
import sys

SRC_DIR = os.environ.get("SRC_DIR", "ForeWiz")
fail = 0

swift_files = []
for root, dirs, files in os.walk(SRC_DIR):
    for fname in files:
        if fname.endswith(".swift"):
            swift_files.append(os.path.join(root, fname))

for path in swift_files:
    with open(path) as f:
        lines = f.readlines()

    for i, line in enumerate(lines, 1):
        stripped = line.strip()

        # Skip comments, imports, empty, debug-only
        if stripped.startswith("//") or stripped.startswith("import") or not stripped:
            continue
        if "print(" in stripped or "Logger" in stripped or "AppLogger" in stripped:
            continue

        # Text("...") without L10n.
        matches = re.findall(r'Text\("([^"]{3,})"\)', stripped)
        for m in matches:
            # Allow known non-localized values: numbers, symbols, empty
            if m.isdigit() or m in ("...", "—", "·", ""):
                continue
            print(f"  {path}:{i}: Text(\"{m}\")")
            fail += 1

        # Label("...", with hardcoded string
        matches2 = re.findall(r'Label\("([^"]{3,})"', stripped)
        for m in matches2:
            if m.isdigit() or m in ("...",):
                continue
            print(f"  {path}:{i}: Label(\"{m}\")")
            fail += 1

if fail:
    print(f"❌ Found {fail} potential hardcoded user-facing strings (use L10n.text)")
else:
    print("✅ No hardcoded user-facing strings detected")

sys.exit(1 if fail else 0)
