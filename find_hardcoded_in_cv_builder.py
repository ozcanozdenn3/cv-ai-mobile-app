import re

with open('lib/screens/cv_builder_screen.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

for i, line in enumerate(lines, 1):
    # Check for hardcoded quotes that look like UI text (not keys or icons or colors)
    if "LocalizationService.tr" in line or "import " in line or line.strip().startswith("//"):
        continue
    # find strings like '...' or "..."
    matches = re.findall(r"'([^']*)'", line)
    for m in matches:
        if any(w in m.lower() for w in ['yeni', 'ekle', 'kaydet', 'seç', 'sil', 'başlık', 'açıklama', 'düzenle']):
            print(f"Line {i}: {line.strip()} -> matched: {m}")

