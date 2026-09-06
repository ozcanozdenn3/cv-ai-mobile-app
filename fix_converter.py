import re

file_path = '/Users/md/.gemini/antigravity-ide/scratch/mobile-app/lib/screens/pdf_converter_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace hardcoded messages in Snackbars
content = re.sub(r"Text\('Dosya okunamadı: \$e'\)", r"Text('${LocalizationService.tr('converter_err_read')}$e')", content)
content = re.sub(r"Text\('Dönüştürülecek metin veya paragraf bulunamadı.'\)", r"Text(LocalizationService.tr('converter_err_no_text'))", content)
content = re.sub(r"Text\('Tabloda veri bulunamadı.'\)", r"Text(LocalizationService.tr('converter_err_no_table'))", content)
content = re.sub(r"Text\('Slayt bulunamadı.'\)", r"Text(LocalizationService.tr('converter_err_no_slide'))", content)
content = re.sub(r"Text\('✅ \$fileName başarıyla oluşturuldu!'\)", r"Text('✅ $fileName ${LocalizationService.tr('converter_success_msg')}')", content)
content = re.sub(r"Text\('Dönüştürme hatası: \$e'\)", r"Text('${LocalizationService.tr('converter_err_convert')}$e')", content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Converter screen localized!")
