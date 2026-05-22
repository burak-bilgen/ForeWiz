#!/usr/bin/env python3
"""Add WizPath cycling localization keys to Localizable.xcstrings"""
import json, sys

path = "ForeWiz/Core/Localization/Localizable.xcstrings"
with open(path, "r") as f:
    data = json.load(f)

new_keys = {
    "wizpath_mode_cycling": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Cycling"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Bisiklet"}},
        },
    },
    "wizpath_cycling_crosswind_title": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Crosswind Alert"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Yan Rüzgar Uyarısı"}},
        },
    },
    "wizpath_cycling_crosswind_message": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Strong crosswinds at %@ — gusts up to %lld km/h. Cycling may be hazardous."}},
            "tr": {"stringUnit": {"state": "translated", "value": "%@'da kuvvetli yan rüzgar — rüzgar hızı %lld km/saate kadar. Bisiklet sürmek tehlikeli olabilir."}},
        },
    },
    "wizpath_cycling_headwind_title": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Headwind Warning"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Ön Rüzgar Uyarısı"}},
        },
    },
    "wizpath_cycling_headwind_message": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Strong headwind along route — travel time may increase by %lld%%"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Rota boyunca kuvvetli ön rüzgar — seyahat süresi %lld%% artabilir"}},
        },
    },
    "wizpath_cycling_effort_title": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Cycling Effort"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Bisiklet Eforu"}},
        },
    },
    "wizpath_cycling_effort_low": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Low effort — favorable conditions for cycling"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Düşük efor — bisiklet için uygun koşullar"}},
        },
    },
    "wizpath_cycling_effort_moderate": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Moderate effort — expect some resistance"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Orta efor — biraz direnç bekleyin"}},
        },
    },
    "wizpath_cycling_effort_high": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "High effort — strong wind resistance expected"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Yüksek efor — kuvvetli rüzgar direnci bekleniyor"}},
        },
    },
    "wizpath_cycling_safety_title": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Cycling Safety"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Bisiklet Güvenliği"}},
        },
    },
    "wizpath_cycling_not_recommended": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Cycling is not recommended due to hazardous weather conditions"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Tehlikeli hava koşulları nedeniyle bisiklet önerilmez"}},
        },
    },
    "wizpath_cycling_crosswind_risk": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Crosswind Risk"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Yan Rüzgar Riski"}},
        },
    },
    "wizpath_cycling_wind_analysis": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Wind Analysis"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Rüzgar Analizi"}},
        },
    },
    "wizpath_cycling_effort_level": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Effort Level"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Efor Seviyesi"}},
        },
    },
}

data["strings"].update(new_keys)

with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("OK - added", len(new_keys), "keys")
