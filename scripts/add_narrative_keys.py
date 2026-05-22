import json

with open('ForeWiz/Core/Localization/Localizable.xcstrings', 'r') as f:
    data = json.load(f)

# New dynamic narrative keys for context-aware stories
new_keys = {
    "narrative_dynamic_temp_ideal": {
        "comment": "Dynamic narrative opener for ideal temperature",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "At a perfect %lld°C"}},
            "tr": {"stringUnit": {"state": "translated", "value": "İdeal %lld°C ile"}}
        }
    },
    "narrative_dynamic_temp_warm": {
        "comment": "Dynamic narrative opener for warm temperature",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "With a warm %lld°C"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Ilık %lld°C'lik havayla"}}
        }
    },
    "narrative_dynamic_temp_hot": {
        "comment": "Dynamic narrative opener for hot temperature",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Scorching %lld°C out there"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Kavurucu %lld°C ile"}}
        }
    },
    "narrative_dynamic_temp_cold": {
        "comment": "Dynamic narrative opener for cold temperature",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "A chilly %lld°C"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Soğuk %lld°C ile"}}
        }
    },
    "narrative_dynamic_temp_cool": {
        "comment": "Dynamic narrative opener for cool temperature",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "A crisp %lld°C"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Serin %lld°C ile"}}
        }
    },
    "narrative_dynamic_wind_calm": {
        "comment": "Dynamic narrative wind context - calm",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "with barely a whisper of wind."}},
            "tr": {"stringUnit": {"state": "translated", "value": "rüzgâr neredeyse hiç yok."}}
        }
    },
    "narrative_dynamic_wind_light": {
        "comment": "Dynamic narrative wind context - light breeze",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "with a gentle breeze to keep things fresh."}},
            "tr": {"stringUnit": {"state": "translated", "value": "hafif bir meltem serinletiyor."}}
        }
    },
    "narrative_dynamic_wind_moderate": {
        "comment": "Dynamic narrative wind context - moderate wind",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "with a noticeable wind picking up."}},
            "tr": {"stringUnit": {"state": "translated", "value": "rüzgâr iyiden iyiye hissediliyor."}}
        }
    },
    "narrative_dynamic_wind_strong": {
        "comment": "Dynamic narrative wind context - strong wind",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "with strong gusts to watch out for."}},
            "tr": {"stringUnit": {"state": "translated", "value": "kuvvetli rüzgâra dikkat!"}}
        }
    },
    "narrative_dynamic_humidity_high": {
        "comment": "Dynamic narrative humidity context - humid",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Humidity at %lld%% makes it feel heavier."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Nem %lld%% ile havayı ağırlaştırıyor."}}
        }
    },
    "narrative_dynamic_humidity_low": {
        "comment": "Dynamic narrative humidity context - dry air",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "The air is dry and comfortable."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Hava kuru ve ferah."}}
        }
    },
    "narrative_dynamic_morning": {
        "comment": "Dynamic narrative time context - morning",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Good morning!"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Günaydın!"}}
        }
    },
    "narrative_dynamic_evening": {
        "comment": "Dynamic narrative time context - evening",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Evening settling in"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Akşam çöküyor"}}
        }
    },
    "narrative_dynamic_context_connector": {
        "comment": "Connector between dynamic context and story",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": " — "}},
            "tr": {"stringUnit": {"state": "translated", "value": " — "}}
        }
    },
    "narrative_dynamic_score_high": {
        "comment": "Dynamic score reaction - high score",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Outdoor score %lld/100 — today is looking fantastic!"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Açık hava puanı %lld/100 — bugün harika görünüyor!"}}
        }
    },
    "narrative_dynamic_score_low": {
        "comment": "Dynamic score reaction - low score",
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Outdoor score %lld/100 — might want to stay in."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Açık hava puanı %lld/100 — belki de evde kalmak iyi fikir."}}
        }
    }
}

# Add new keys
added = 0
for key, value in new_keys.items():
    if key not in data['strings']:
        data['strings'][key] = value
        added += 1

with open('ForeWiz/Core/Localization/Localizable.xcstrings', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)
    f.write('\n')

print(f'✅ Added {added} new narrative keys')
print('Keys added:')
for key in sorted(new_keys.keys()):
    en_val = new_keys[key]['localizations']['en']['stringUnit']['value']
    tr_val = new_keys[key]['localizations']['tr']['stringUnit']['value']
    print(f'  {key}: EN={en_val} | TR={tr_val}')
