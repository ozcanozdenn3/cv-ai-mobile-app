import os
import re

def replace_in_file(filepath, replacements):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    for old_str, new_str in replacements:
        content = content.replace(old_str, new_str)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

replacements_pdf = [
    ("pw.Text('RESMİ TARANMIŞ BELGE NÜSHASI'", "pw.Text(LocalizationService.tr('pdf_official_scan')"),
    ("pw.Text('Belge Referans No: TR-SCAN-2026-${1000 + i}'", "pw.Text('${LocalizationService.tr('pdf_doc_ref')} TR-SCAN-2026-${1000 + i}'"),
    ("pw.Text('Optik Karakter Tanıma (OCR): %99.8 Doğrulukla İşlendi'", "pw.Text(LocalizationService.tr('pdf_ocr_accuracy')"),
    ("Bu belge $originalFormat kaynağından CV AI yüksek doğruluklu dönüştürücü motoru ile başarıyla vektörel PDF standardına dönüştürülmüştür. Orijinal sayfa düzeni, tablolar, paragraflar ve font hiyerarşisi %100 korunmuştur.",
     "${LocalizationService.tr('pdf_vector_pdf_desc_1')} $originalFormat ${LocalizationService.tr('pdf_vector_pdf_desc_2')}"),
    ("['No', 'Bölüm / Parametre', 'Durum', 'Doğruluk']", "[LocalizationService.tr('pdf_table_no'), LocalizationService.tr('pdf_table_section'), LocalizationService.tr('pdf_table_status'), LocalizationService.tr('pdf_table_accuracy')]"),
    ("['1', 'Metin Hiyerarşisi', 'Korundu', '%100']", "['1', LocalizationService.tr('pdf_table_text_hierarchy'), LocalizationService.tr('pdf_table_preserved'), '%100']"),
    ("['2', 'Vektör Grafikler', 'Optimize Edildi', '%100']", "['2', LocalizationService.tr('pdf_table_vector_graphics'), LocalizationService.tr('pdf_table_optimized'), '%100']"),
    ("['4', 'Güvenlik & Filigran', 'Temiz / Şifreli', 'Tamam']", "['4', LocalizationService.tr('pdf_table_security'), LocalizationService.tr('pdf_table_clean_encrypted'), LocalizationService.tr('pdf_table_ok')]"),
    ("Profesyonel Vektörel PDF Çıktısı", "LocalizationService.tr('pdf_prof_vector_output')"),
    ("Bu sayfa CV AI CamScanner HD mobil tarayıcı ile 600 DPI çözünürlükte taranmış, otomatik perspektif düzeltme ve kontrast netleştirme filtrelerinden geçirilmiştir. Belge üzerindeki tüm metinler ve imzalar vektörel arşiv standardına uygundur.",
     "LocalizationService.tr('pdf_camscanner_desc')"),
    ("['No', 'Ürün / Kalem', 'Miktar', 'Birim Fiyat', 'Toplam (TL)']", "[LocalizationService.tr('pdf_table_no'), LocalizationService.tr('pdf_table_item'), LocalizationService.tr('pdf_table_quantity'), LocalizationService.tr('pdf_table_unit_price'), LocalizationService.tr('pdf_table_total')]"),
    ("['1', 'Yazılım Danışmanlığı', '1 Ay', '45.000,00 TL', '45.000,00 TL']", "['1', LocalizationService.tr('pdf_table_software_consulting'), '1 ${LocalizationService.tr('pdf_table_month')}', '45.000,00 TL', '45.000,00 TL']"),
    ("['2', 'Mobil Uygulama Geliştirme', '1 Proje', '85.000,00 TL', '85.000,00 TL']", "['2', LocalizationService.tr('pdf_table_mobile_app_dev'), '1 ${LocalizationService.tr('pdf_table_project')}', '85.000,00 TL', '85.000,00 TL']"),
    ("ocrText.isNotEmpty ? ocrText : 'Bu sayfa için metin ayrıştırma kaydı bulunamadı.'", "ocrText.isNotEmpty ? ocrText : LocalizationService.tr('pdf_no_ocr_record')"),
    ("String author = 'Canberk Yılmaz'", "String author = 'CV AI User'")
]

replace_in_file('lib/services/pdf_generator_service.dart', replacements_pdf)
print("Done pdf_generator_service")
