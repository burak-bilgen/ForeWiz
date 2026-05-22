#!/usr/bin/env python3
"""Add WizPath localization keys for CyclingSafetyPanel and WeatherDetailSheet"""
import json

path = "ForeWiz/Core/Localization/Localizable.xcstrings"
with open(path, "r") as f:
    data = json.load(f)

new_keys = {
    # CyclingSafetyPanel badges
    "wizpath_cycling_badge_safe": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Safe"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Güvenli"}},
        },
    },
    "wizpath_cycling_badge_caution": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Caution"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Dikkat"}},
        },
    },
    "wizpath_cycling_badge_not_recommended": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Not Recommended"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Önerilmez"}},
        },
    },
    # Units
    "wizpath_unit_kmh": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "km/h"}},
            "tr": {"stringUnit": {"state": "translated", "value": "km/sa"}},
        },
    },
    "wizpath_unit_gust": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "gust"}},
            "tr": {"stringUnit": {"state": "translated", "value": "rüzgar"}},
        },
    },
    # Cycling crosswind short label
    "wizpath_cycling_crosswind_short": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "crosswind"}},
            "tr": {"stringUnit": {"state": "translated", "value": "yan rüzgar"}},
        },
    },
    # Cycling extra time
    "wizpath_cycling_extra_time": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "+%lld%% estimated extra time"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Tahmini +%%%lld ek süre"}},
        },
    },
    # Crosswind segments
    "wizpath_cycling_crosswind_segments_singular": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Strong crosswinds on %lld segment"}},
            "tr": {"stringUnit": {"state": "translated", "value": "%lld bölümde kuvvetli yan rüzgar"}},
        },
    },
    "wizpath_cycling_crosswind_segments_plural": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Strong crosswinds on %lld segments"}},
            "tr": {"stringUnit": {"state": "translated", "value": "%lld bölümde kuvvetli yan rüzgar"}},
        },
    },
    # Safe conditions text
    "wizpath_cycling_safe_conditions": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Conditions are safe for cycling."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Koşullar bisiklet için güvenli."}},
        },
    },
    # Weather Detail Sheet UI
    "wizpath_weather_detail_title": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Weather Detail"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Hava Durumu Detayı"}},
        },
    },
    "wizpath_weather_eta": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "ETA"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Varış Süresi"}},
        },
    },
    "wizpath_weather_precipitation": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Precipitation"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Yağış"}},
        },
    },
    "wizpath_weather_visibility": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Visibility"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Görüş Mesafesi"}},
        },
    },
    "wizpath_weather_severity": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Severity"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Şiddet"}},
        },
    },
    "wizpath_weather_recommendation": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Recommendation"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Öneri"}},
        },
    },
    # Weather conditions
    "wizpath_condition_clear": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Clear"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Açık"}},
        },
    },
    "wizpath_condition_partly_cloudy": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Partly Cloudy"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Parçalı Bulutlu"}},
        },
    },
    "wizpath_condition_cloudy": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Cloudy"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Bulutlu"}},
        },
    },
    "wizpath_condition_rain": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Rain"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Yağmur"}},
        },
    },
    "wizpath_condition_heavy_rain": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Heavy Rain"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Şiddetli Yağmur"}},
        },
    },
    "wizpath_condition_snow": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Snow"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Kar"}},
        },
    },
    "wizpath_condition_sleet": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Sleet"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Sulu Kar"}},
        },
    },
    "wizpath_condition_thunderstorm": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Thunderstorm"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Gök Gürültülü Fırtına"}},
        },
    },
    "wizpath_condition_fog": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Fog"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Sis"}},
        },
    },
    "wizpath_condition_windy": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Windy"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Rüzgarlı"}},
        },
    },
    "wizpath_condition_unknown": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Unknown"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Bilinmiyor"}},
        },
    },
    # Severity levels
    "wizpath_severity_good": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Good"}},
            "tr": {"stringUnit": {"state": "translated", "value": "İyi"}},
        },
    },
    "wizpath_severity_fair": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Fair"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Orta"}},
        },
    },
    "wizpath_severity_caution": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Caution"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Dikkat"}},
        },
    },
    "wizpath_severity_severe": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Severe"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Şiddetli"}},
        },
    },
    # Weather recommendations
    "wizpath_rec_thunderstorm": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Seek shelter immediately. Avoid open areas, tall objects, and water. Stay in your vehicle if possible."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Hemen sığınak bulun. Açık alanlardan, yüksek nesnelerden ve sudan uzak durun. Mümkünse aracınızda kalın."}},
        },
    },
    "wizpath_rec_heavy_rain": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Reduce speed and increase following distance. Watch for standing water on roads. Consider delaying travel."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Hızınızı azaltın ve takip mesafesini artırın. Yolda birikmiş suya dikkat edin. Seyahati ertelemeyi düşünün."}},
        },
    },
    "wizpath_rec_snow": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Drive with extreme caution. Ensure proper tires and slow down. Allow extra time for your journey."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Aşırı dikkatli sürün. Uygun lastikleri kullanın ve yavaşlayın. Yolculuğunuz için ek süre ayırın."}},
        },
    },
    "wizpath_rec_fog": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Use low-beam headlights and reduce speed significantly. Increase following distance. Pull over if visibility drops too low."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Kısa farları kullanın ve hızı önemli ölçüde azaltın. Takip mesafesini artırın. Görüş çok düşerse kenara çekin."}},
        },
    },
    "wizpath_rec_high_wind": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "High winds detected. Hold the steering wheel firmly. Watch for debris on the road. Consider delaying travel."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Kuvvetli rüzgar tespit edildi. Direksiyonu sıkı tutun. Yoldaki enkazlara dikkat edin. Seyahati ertelemeyi düşünün."}},
        },
    },
    "wizpath_rec_rain": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Drive carefully. Wet roads may be slippery. Allow extra braking distance."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Dikkatli sürün. Islak yollar kaygan olabilir. Fazladan fren mesafesi bırakın."}},
        },
    },
    "wizpath_rec_extreme_heat": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Extreme heat. Stay hydrated, use air conditioning, and avoid prolonged exposure. Check on vulnerable passengers."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Aşırı sıcak. Bol su için, klimayı kullanın ve uzun süre maruz kalmaktan kaçının. Hassas yolcuları kontrol edin."}},
        },
    },
    "wizpath_rec_freezing": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Freezing temperatures. Watch for black ice on roads. Dress warmly and limit exposure."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Donma sıcaklıkları. Yollarda gizli buza dikkat edin. Sıcak giyinin ve maruziyeti sınırlayın."}},
        },
    },
    "wizpath_rec_normal": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Conditions are normal. Drive safely and enjoy your journey."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Koşullar normal. Güvenli sürüşler ve keyifli bir yolculuk dileriz."}},
        },
    },
    # Wet roads message for cycling (from ClimateService)
    "wizpath_cycling_wet_roads_title": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Wet Roads"}},
            "tr": {"stringUnit": {"state": "translated", "value": "Islak Yollar"}},
        },
    },
    "wizpath_cycling_wet_roads_desc": {
        "extractionState": "manual",
        "localizations": {
            "en": {"stringUnit": {"state": "translated", "value": "Rain reduces tire grip. Reduce speed and avoid sudden braking."}},
            "tr": {"stringUnit": {"state": "translated", "value": "Yağmur lastik tutuşunu azaltır. Hızınızı düşürün ve ani fren yapmaktan kaçının."}},
        },
    },
}

data["strings"].update(new_keys)

with open(path, "w") as f:
    json.dump(data, f, indent=2, ensure_ascii=False)

print("OK - added", len(new_keys), "keys (v2)")
