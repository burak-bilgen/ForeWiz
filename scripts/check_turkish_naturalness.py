#!/usr/bin/env python3
import json, re, sys

with open('ForeWiz/Core/Localization/Localizable.xcstrings', 'r') as f:
    data = json.load(f)

prefixes = ('wizpath_', 'hazard_', 'poi_', 'multiplier_', 'climate_', 'segment_', 'travel_', 'route_', 'sentinel_', 'departure_', 'format_', 'effort_')

print("=" * 100)
print("TÜM WIZPATH TÜRKÇE ÇEVİRİLERİ — DOĞALLIK DENETİMİ")
print("=" * 100)

issues = []

for key in sorted(data['strings'].keys()):
    if not key.startswith(prefixes):
        continue
    locs = data['strings'][key].get('localizations', {})
    en_val = locs.get('en', {}).get('stringUnit', {}).get('value', '')
    tr_val = locs.get('tr', {}).get('stringUnit', {}).get('value', '')
    comment = data['strings'][key].get('comment', '')
    
    print(f"\nKey: {key}")
    if comment:
        print(f"  CMT: {comment}")
    print(f"  EN: {en_val}")
    print(f"  TR: {tr_val}")
    
    # Check for unnatural patterns
    problems = []
    
    # Excessively literal/formal
    if 'tespit edildi' in tr_val.lower():
        problems.append(('RESMİ', "'tespit edildi' → daha doğal: 'var', 'görülüyor', 'bekleniyor'"))
    if 'muhafaza' in tr_val.lower():
        problems.append(('RESMİ', "'muhafaza' → 'koru', 'sürdür'"))
    if 'tavsiye edil' in tr_val.lower():
        problems.append(('RESMİ', "'tavsiye edilir' → 'önerilir' daha yaygın"))
    if 'ikaz' in tr_val.lower():
        problems.append(('ESKİ', "'ikaz' → 'uyarı' daha güncel"))
    if 'ziyan' in tr_val.lower():
        problems.append(('ESKİ', "'ziyan' → 'zarar' daha doğal"))
    if 'etkileşim' in tr_val.lower() and 'kullanıcı' in tr_val.lower():
        problems.append(('YAPAY', "'kullanıcı etkileşimi' çeviri kokuyor"))
    if 'teşkil' in tr_val.lower():
        problems.append(('ESKİ', "'teşkil' → 'oluştur' daha doğal"))
    if 'arz' in tr_val.lower() and 'etm' in tr_val.lower():
        problems.append(('ESKİ', "'arz etmek' → 'sunmak' daha doğal"))
    if 'vuku' in tr_val.lower():
        problems.append(('ESKİ', "'vuku' → 'oluşan', 'meydana gelen'"))
    if 'derecede' in tr_val.lower() and ('yüksek' in tr_val.lower() or 'düşük' in tr_val.lower()):
        problems.append(('RESMİ', "'derecede' yerine daha kısa ifade kullanılabilir"))
    if 'itibarıyla' in tr_val.lower():
        problems.append(('RESMİ', "'itibarıyla' → daha kısa ifade"))
    
    # Check for overly long sentences
    sentences = re.split(r'[.!?]', tr_val)
    for s in sentences:
        words = s.strip().split()
        if len(words) > 12:
            problems.append(('UZUN CÜMLE', f"{len(words)} kelimelik cümle: '{s.strip()[:60]}...' → bölünebilir"))
    
    if problems:
        print(f"  ⚠️  SORUNLAR:")
        for ptype, pdesc in problems:
            print(f"      [{ptype}] {pdesc}")
        issues.append((key, en_val, tr_val, problems))

print("\n" + "=" * 100)
print(f"ÖZET: {len(issues)} çeviride sorun tespit edildi")
print("=" * 100)

if issues:
    print("\nDÜZELTİLMESİ GEREKENLER:")
    for key, en_val, tr_val, problems in issues:
        print(f"\n📌 {key}")
        print(f"   EN: {en_val}")
        print(f"   TR: {tr_val}")
        for ptype, pdesc in problems:
            print(f"   ❌ [{ptype}] {pdesc}")
else:
    print("\n✅ Tüm çeviriler doğal görünüyor!")
