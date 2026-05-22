#!/usr/bin/env python3
import json

with open('ForeWiz/Core/Localization/Localizable.xcstrings', 'r', encoding='utf-8') as f:
    raw = f.read()

# Fix 1: sentinel_body_gridlock
# "Yo\u011fun trafik tespit edildi. Rota %@ \u2192 %@." -> "Yo\u011fun trafik var. Rota %@ \u2192 %@."
raw = raw.replace(
    'Yo\u011fun trafik tespit edildi. Rota',
    'Yo\u011fun trafik var. Rota'
)

# Fix 2: sentinel_body_storm
# "Rota \u00fczerinde \u015fiddetli f\u0131rt\u0131nalar tespit edildi. S\u00fcre %@ \u2192 %@." 
# -> "Rota \u00fczerinde \u015fiddetli f\u0131rt\u0131nalar bekleniyor. S\u00fcre %@ \u2192 %@."
raw = raw.replace(
    '\u015fiddetli f\u0131rt\u0131nalar tespit edildi. S\u00fcre',
    '\u015fiddetli f\u0131rt\u0131nalar bekleniyor. S\u00fcre'
)

# Fix 3: wizpath_cycling_crosswind_caution_reason
# "Kuvvetli yan r\u00fczg\u00e2r tespit edildi \u2014 gidonu" 
# -> "Kuvvetli yan r\u00fczg\u00e2r var \u2014 gidonu"
raw = raw.replace(
    'Kuvvetli yan r\u00fczg\u00e2r tespit edildi \u2014 gidonu',
    'Kuvvetli yan r\u00fczg\u00e2r var \u2014 gidonu'
)

# Fix 4: wizpath_rec_high_wind
# "Kuvvetli r\u00fczg\u00e2r tespit edildi. Direksiyonu s\u0131k\u0131 tutun. Yoldaki enkazlara dikkat edin."
# -> "Kuvvetli r\u00fczg\u00e2r var. Direksiyonu s\u0131k\u0131 tutun. Yoldaki d\u00f6k\u00fcnt\u00fclere dikkat edin."
raw = raw.replace(
    'Kuvvetli r\u00fczg\u00e2r tespit edildi. Direksiyonu s\u0131k\u0131 tutun. Yoldaki enkazlara dikkat edin. Seyahati ertelemeyi d\u00fc\u015f\u00fcn\u00fcn.',
    'Kuvvetli r\u00fczg\u00e2r var. Direksiyonu s\u0131k\u0131 tutun. Yoldaki d\u00f6k\u00fcnt\u00fclere dikkat edin. Seyahati ertelemeyi d\u00fc\u015f\u00fcn\u00fcn.'
)

with open('ForeWiz/Core/Localization/Localizable.xcstrings', 'w', encoding='utf-8') as f:
    f.write(raw)

print("✅ 4 düzeltme uygulandı:")
print("  sentinel_body_gridlock: 'tespit edildi' → 'var'")
print("  sentinel_body_storm: 'tespit edildi' → 'bekleniyor'")
print("  wizpath_cycling_crosswind_caution_reason: 'tespit edildi' → 'var'")
print("  wizpath_rec_high_wind: 'tespit edildi' → 'var', 'enkazlar' → 'döküntüler'")
