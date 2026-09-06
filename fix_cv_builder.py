import re

file_path = '/Users/md/.gemini/antigravity-ide/scratch/mobile-app/lib/screens/cv_builder_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace explicit strings
replacements = {
    r"'• Uygulama performansını %40 artırdı.\\n• 10\+ kişilik geliştirici ekibine liderlik etti.'": "LocalizationService.tr('cv_hint_exp_desc')",
    r"'B2 - İyi / Profesyonel'": "LocalizationService.tr('cv_default_lang_level')",
    r"'Projenin amacı, mimarisi ve sağladığı somut çıktılar...'": "LocalizationService.tr('cv_hint_project_desc')",
    r"'İlk başarı / madde metni...'": "LocalizationService.tr('cv_default_bullet')",
    r"'İlk madde metni...'": "LocalizationService.tr('cv_default_bullet_short')",

    r"'Koyu renkli sol panel, seviye çubukları ve sağ gövde'": "LocalizationService.tr('cv_tpl_subtitle_modern')",
    r"'POPÜLER'": "LocalizationService.tr('cv_tpl_badge_popular')",
    r"'Çift sütunlu, modern simgeli teknoloji standardı'": "LocalizationService.tr('cv_tpl_subtitle_tech')",
    r"'ATS LİDERİ'": "LocalizationService.tr('cv_tpl_badge_ats')",
    r"'Klasik ortalanmış başlık, üst düzey yönetici standardı'": "LocalizationService.tr('cv_tpl_subtitle_exec')",
    r"'YÖNETİCİ'": "LocalizationService.tr('cv_tpl_badge_exec')",
    r"'Görsel tam boy renkli şeritli, portfolyo stili'": "LocalizationService.tr('cv_tpl_subtitle_design')",
    r"'TASARIM'": "LocalizationService.tr('cv_tpl_badge_design')",
    r"'Sade İskandinav stili, net tipografi'": "LocalizationService.tr('cv_tpl_subtitle_elegant')",
    r"'ZARİF'": "LocalizationService.tr('cv_tpl_badge_elegant')",
    r"'Akademisyenler ve resmi başvurular standardı'": "LocalizationService.tr('cv_tpl_subtitle_academic')",
    r"'AKADEMİK'": "LocalizationService.tr('cv_tpl_badge_academic')",
    r"'Tek sayfaya maksimum deneyim sığdıran mühendislik formatı'": "LocalizationService.tr('cv_tpl_subtitle_engineering')",
    r"'MÜHENDİSLİK'": "LocalizationService.tr('cv_tpl_badge_engineering')",
    r"'Görsel metrikler, renkli başlık ve seviye barları'": "LocalizationService.tr('cv_tpl_subtitle_metric')",
    r"'METRİK'": "LocalizationService.tr('cv_tpl_badge_metric')",
    r"'Altın çerçeveli lüks üst düzey yönetici formatı'": "LocalizationService.tr('cv_tpl_subtitle_luxury')",
    r"'ELİT LÜKS'": "LocalizationService.tr('cv_tpl_badge_luxury')",
    r"'İskandinav geometrik vurgu bloklu modern mizanpaj'": "LocalizationService.tr('cv_tpl_subtitle_nordic')",
    r"'NORDİK'": "LocalizationService.tr('cv_tpl_badge_nordic')",
}

for old, new in replacements.items():
    content = re.sub(old, new, content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("CV builder localized!")
