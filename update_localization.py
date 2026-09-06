import re

file_path = '/Users/md/.gemini/antigravity-ide/scratch/mobile-app/lib/services/localization_service.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# New keys to add
new_keys = {
    'cv_hint_exp_desc': {'tr': '• Uygulama performansını %40 artırdı.\n• 10+ kişilik geliştirici ekibine liderlik etti.', 'en': '• Increased app performance by 40%.\n• Led a developer team of 10+ people.'},
    'cv_default_lang_level': {'tr': 'B2 - İyi / Profesyonel', 'en': 'B2 - Upper Intermediate / Professional'},
    'cv_hint_project_desc': {'tr': 'Projenin amacı, mimarisi ve sağladığı somut çıktılar...', 'en': 'Project goal, architecture and concrete outputs...'},
    'cv_default_bullet': {'tr': 'İlk başarı / madde metni...', 'en': 'First achievement / bullet point...'},
    'cv_default_bullet_short': {'tr': 'İlk madde metni...', 'en': 'First bullet point...'},
    
    'cv_tpl_subtitle_modern': {'tr': 'Koyu renkli sol panel, seviye çubukları ve sağ gövde', 'en': 'Dark left panel, level bars and right body'},
    'cv_tpl_badge_popular': {'tr': 'POPÜLER', 'en': 'POPULAR'},
    'cv_tpl_subtitle_tech': {'tr': 'Çift sütunlu, modern simgeli teknoloji standardı', 'en': 'Dual-column, tech standard with modern icons'},
    'cv_tpl_badge_ats': {'tr': 'ATS LİDERİ', 'en': 'ATS LEADER'},
    'cv_tpl_subtitle_exec': {'tr': 'Klasik ortalanmış başlık, üst düzey yönetici standardı', 'en': 'Classic centered header, top executive standard'},
    'cv_tpl_badge_exec': {'tr': 'YÖNETİCİ', 'en': 'EXECUTIVE'},
    'cv_tpl_subtitle_design': {'tr': 'Görsel tam boy renkli şeritli, portfolyo stili', 'en': 'Visual full-length colored strip, portfolio style'},
    'cv_tpl_badge_design': {'tr': 'TASARIM', 'en': 'DESIGN'},
    'cv_tpl_subtitle_elegant': {'tr': 'Sade İskandinav stili, net tipografi', 'en': 'Simple Scandinavian style, clean typography'},
    'cv_tpl_badge_elegant': {'tr': 'ZARİF', 'en': 'ELEGANT'},
    'cv_tpl_subtitle_academic': {'tr': 'Akademisyenler ve resmi başvurular standardı', 'en': 'Standard for academics and official applications'},
    'cv_tpl_badge_academic': {'tr': 'AKADEMİK', 'en': 'ACADEMIC'},
    'cv_tpl_subtitle_engineering': {'tr': 'Tek sayfaya maksimum deneyim sığdıran mühendislik formatı', 'en': 'Engineering format fitting max experience on one page'},
    'cv_tpl_badge_engineering': {'tr': 'MÜHENDİSLİK', 'en': 'ENGINEERING'},
    'cv_tpl_subtitle_metric': {'tr': 'Görsel metrikler, renkli başlık ve seviye barları', 'en': 'Visual metrics, colored header and level bars'},
    'cv_tpl_badge_metric': {'tr': 'METRİK', 'en': 'METRIC'},
    'cv_tpl_subtitle_luxury': {'tr': 'Altın çerçeveli lüks üst düzey yönetici formatı', 'en': 'Gold-framed luxury top executive format'},
    'cv_tpl_badge_luxury': {'tr': 'ELİT LÜKS', 'en': 'ELITE LUXURY'},
    'cv_tpl_subtitle_nordic': {'tr': 'İskandinav geometrik vurgu bloklu modern mizanpaj', 'en': 'Modern layout with Scandinavian geometric highlight blocks'},
    'cv_tpl_badge_nordic': {'tr': 'NORDİK', 'en': 'NORDIC'},

    # Converter Errors & Messages
    'converter_err_read': {'tr': 'Dosya okunamadı: ', 'en': 'Failed to read file: '},
    'converter_err_no_text': {'tr': 'Dönüştürülecek metin veya paragraf bulunamadı.', 'en': 'No text or paragraph found to convert.'},
    'converter_err_no_table': {'tr': 'Tabloda veri bulunamadı.', 'en': 'No data found in table.'},
    'converter_err_no_slide': {'tr': 'Slayt bulunamadı.', 'en': 'No slide found.'},
    'converter_success_msg': {'tr': 'başarıyla oluşturuldu!', 'en': 'created successfully!'},
    'converter_err_convert': {'tr': 'Dönüştürme hatası: ', 'en': 'Conversion error: '},
}

locales = {
    'tr': 'TR', 'en': 'EN', 'de': 'DE', 'fr': 'FR', 'es': 'ES',
    'pt': 'PT', 'it': 'IT', 'nl': 'NL', 'pl': 'PL', 'ru': 'RU',
    'ar': 'AR', 'zh': 'ZH', 'ja': 'JA', 'hi': 'HI', 'ko': 'KO', 'id': 'ID'
}

def inject_keys(content, locale_code):
    marker = f"// {list(locales.keys()).index(locale_code) + 1}. LANGUAGE ({locale_code})"
    if marker not in content:
        return content

    start_idx = content.find(marker)
    # find the opening brace for this locale's map
    brace_idx = content.find('{', start_idx)
    
    # Generate the block to insert
    lines = []
    for k, v_dict in new_keys.items():
        val = v_dict['tr'] if locale_code == 'tr' else v_dict['en']
        lines.append(f"      '{k}': '{val}',")
    
    insert_str = "\n" + "\n".join(lines) + "\n"
    
    new_content = content[:brace_idx+1] + insert_str + content[brace_idx+1:]
    return new_content

for loc in locales.keys():
    content = inject_keys(content, loc)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Localization keys injected successfully!")
