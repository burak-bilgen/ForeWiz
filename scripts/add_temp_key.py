#!/usr/bin/env python3
"""Add wizpath_temperature_format key"""
import json

path = "ForeWiz/Core/Localization/Localizable.xcstrings"
with open(path, "r") as f:
    data = json.load(f)

data["strings"]["wizpath_temperature_format"] = {
    "extractionState": "manual",
    "localizations": {
        "en": {"stringUnit": {"state": "translated", "value": "%lld\u00b0C"}},
        "tr": {"stringUnit": {"state": "translated", "value": "%lld\u00b0C"}},
    },
}

with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("OK - added wizpath_temperature_format")
