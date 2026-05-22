#!/usr/bin/env python3
"""Add remaining WizPath localization keys"""
import json

path = "ForeWiz/Core/Localization/Localizable.xcstrings"
with open(path, "r") as f:
    data = json.load(f)

new_keys = {
    # Wind speed format
    "wizpath_wind_speed_format": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "%lld km/h"}},
            "tr": {"stringUnit": {"state": "translated", "value": "%lld km/sa"}},
        },
    },
    # Cycling safety reason strings
    "wizpath_cycling_crosswind_wet_reason": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Strong winds and wet roads make cycling hazardous"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Kuvvetli rüzgar ve ıslak yollar bisiklet sürmeyi tehlikeli hale getiriyor"}},
        },
    },
    "wizpath_cycling_crosswind_caution_reason": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Strong crosswinds detected — hold handlebars firmly and reduce speed"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Kuvvetli yan rüzgar tespit edildi — gidonu sıkı tutun ve hızınızı azaltın"}},
        },
    },
    "wizpath_cycling_wet_roads_reason": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Wet roads reduce traction — increase braking distance"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Islak yollar tutuşu azaltır — fren mesafesini artırın"}},
        },
    },
    "wizpath_cycling_high_effort_reason": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "High effort required due to wind resistance"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Rüzgar direnci nedeniyle yüksek efor gerekiyor"}},
        },
    },
    # Effort level descriptions (for potential future UI use)
    "wizpath_cycling_effort_desc_low": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Low effort — favorable conditions for cycling"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Düşük efor — bisiklet için uygun koşullar"}},
        },
    },
    "wizpath_cycling_effort_desc_moderate": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Moderate effort — expect some resistance"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Orta efor — biraz direnç bekleyin"}},
        },
    },
    "wizpath_cycling_effort_desc_high": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "High effort — strong wind resistance expected"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Yüksek efor — kuvvetli rüzgar direnci bekleniyor"}},
        },
    },
}

data["strings"].update(new_keys)

with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("OK - added", len(new_keys), "keys (v3)")
