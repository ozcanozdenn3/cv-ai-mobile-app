import os
import re

screens_dir = 'lib/screens'
turkish_keywords = ['yeni', 'ekle', 'kaydet', 'seç', 'sil', 'başlık', 'açıklama', 'düzenle', 'yükle', 'ayarlar', 'galeri', 'tara', 'fotoğraf', 'belge', 'şablon', 'sıralama']

for root, _, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart') and file != 'localization_service.dart':
            filepath = os.path.join(root, file)
            with open(filepath, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            for i, line in enumerate(lines, 1):
                if "LocalizationService.tr" in line or line.strip().startswith("//") or "import " in line:
                    continue
                # find string literals
                matches = re.findall(r"'([^']*)'", line) + re.findall(r'"([^"]*)"', line)
                for m in matches:
                    if len(m) > 3 and any(w in m.lower() for w in turkish_keywords) and not m.startswith('key_') and not m.startswith('assets/') and not m.startswith('hint_') and not m.startswith('cv_'):
                        print(f"{filepath}:{i} -> {m}")

