import os

def replace_in_file(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    for old_str, new_str in replacements:
        content = content.replace(old_str, new_str)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

replacements_doc_parser = [
    ("['Giriş ve Genel Bakış', 'Temel Başlıklar ve Veriler', 'Sonuç ve Değerlendirme']",
     "[LocalizationService.tr('pptx_bullet_1'), LocalizationService.tr('pptx_bullet_2'), LocalizationService.tr('pptx_bullet_3')]")
]
replace_in_file('lib/services/document_parser_service.dart', replacements_doc_parser)

replacements_office = [
    ("['No', 'Bölüm / Başlık', 'İçerik']",
     "[LocalizationService.tr('doc_table_no'), LocalizationService.tr('doc_table_section'), LocalizationService.tr('doc_table_content')]"),
    ("['Slayt No', 'Slayt Başlığı', 'Slayt İçeriği / Maddeler']",
     "[LocalizationService.tr('slide_no'), LocalizationService.tr('slide_title'), LocalizationService.tr('slide_content')]"),
    ("['Genel Bakış ve Detaylar']",
     "[LocalizationService.tr('general_overview_details')]")
]
replace_in_file('lib/services/office_converter_service.dart', replacements_office)

replacements_ocr = [
    ("'Dosya bulunamadı.'", "LocalizationService.tr('file_not_found')"),
    ("'Google ML Kit OCR Hatası: $e'", "'${LocalizationService.tr('ocr_error')}: $e'"),
    ("'OCR processImageBytes Hatası: $e'", "'${LocalizationService.tr('ocr_process_error')}: $e'")
]
replace_in_file('lib/services/ocr_engine_service.dart', replacements_ocr)

replacements_sub = [
    ("return 'Haftalık VIP Plan'", "return LocalizationService.tr('sub_weekly')"),
    ("return 'Aylık VIP Plan'", "return LocalizationService.tr('sub_monthly')"),
    ("return 'Yıllık VIP Plan (Tavsiye Edilen)'", "return LocalizationService.tr('sub_yearly')")
]
replace_in_file('lib/models/subscription_model.dart', replacements_sub)

print("Done phase 2")
