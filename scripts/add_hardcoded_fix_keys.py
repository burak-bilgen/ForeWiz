import json

with open('ForeWiz/Core/Localization/Localizable.xcstrings', 'r') as f:
    data = json.load(f)

keys = {
    # DepartureOptimizerService - formattedTimeUntil
    "departure_min_format": {
        "comment": "Duration in minutes only",
        "en": "%lld min",
        "tr": "%lld dk"
    },
    "departure_hours_minutes_format": {
        "comment": "Duration in hours and minutes",
        "en": "%lldh %lldm",
        "tr": "%llds %lldd"
    },
    # DepartureOptimizerService - DepartureRecommendation displayText
    "departure_rec_optimal": {
        "comment": "Optimal departure time recommendation",
        "en": "Best Time",
        "tr": "En İyi Zaman"
    },
    "departure_rec_good": {
        "comment": "Good departure time recommendation",
        "en": "Good Time",
        "tr": "İyi Zaman"
    },
    "departure_rec_moderate": {
        "comment": "Moderate departure time recommendation",
        "en": "Acceptable",
        "tr": "Kabul Edilebilir"
    },
    "departure_rec_caution": {
        "comment": "Caution departure time recommendation",
        "en": "Use Caution",
        "tr": "Dikkatli Olun"
    },
    "departure_rec_poor": {
        "comment": "Poor/not recommended departure time",
        "en": "Not Recommended",
        "tr": "Önerilmez"
    },
    # WizPathSentinelService - SuppressionReason descriptions
    "sentinel_reason_below_threshold": {
        "comment": "Suppression reason: delay below minimum threshold",
        "en": "Delay below sentinel threshold",
        "tr": "Gecikme eşik değerin altında"
    },
    "sentinel_reason_rate_limited": {
        "comment": "Suppression reason: too many notifications per hour",
        "en": "Rate limit exceeded (max 3/hour)",
        "tr": "Hız sınırı aşıldı (en fazla 3/saat)"
    },
    "sentinel_reason_cooldown": {
        "comment": "Suppression reason: cooldown period active",
        "en": "Cooldown period active (15 min)",
        "tr": "Bekleme süresi aktif (15 dk)"
    },
    "sentinel_reason_disabled": {
        "comment": "Suppression reason: user disabled notifications",
        "en": "User disabled notifications",
        "tr": "Bildirimler kullanıcı tarafından kapatıldı"
    },
    # WeatherDetailSheet - visibility display
    "weather_visibility_high": {
        "comment": "Visibility is very good, more than 10 km",
        "en": ">10 km",
        "tr": ">10 km"
    },
    "weather_visibility_value": {
        "comment": "Visibility value in kilometers with one decimal",
        "en": "%.1f km",
        "tr": "%.1f km"
    },
    # WeatherDetailSheet - visibility fallback (em dash)
    "weather_visibility_na": {
        "comment": "Visibility not available",
        "en": "—",
        "tr": "—"
    },
}

for key, info in keys.items():
    if key not in data['strings']:
        data['strings'][key] = {
            'extractionState': 'manual',
            'comment': info['comment'],
            'localizations': {
                'en': {'stringUnit': {'state': 'translated', 'value': info['en']}},
                'tr': {'stringUnit': {'state': 'translated', 'value': info['tr']}}
            }
        }
        print(f"  ADDED: {key}")
    else:
        print(f"  EXISTS: {key}")

with open('ForeWiz/Core/Localization/Localizable.xcstrings', 'w') as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print(f"\nDone! Total keys added: {sum(1 for k in keys if k in data['strings'])}")
