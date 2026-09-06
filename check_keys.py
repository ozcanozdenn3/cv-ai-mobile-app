import re

with open('lib/services/localization_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Extract each language dictionary in _translations
locales = re.findall(r"'([a-zA-Z_]+)'\s*:\s*\{", text)
print("Locales found in file:", locales)

# Extract all keys in 'tr' and 'en'
def get_keys(locale):
    pattern = rf"'{locale}'\s*:\s*\{{(.*?)\n\s*\}},"
    m = re.search(pattern, text, re.DOTALL)
    if not m:
        return set()
    body = m.group(1)
    keys = set(re.findall(r"^\s*'([a-zA-Z0-9_\-]+)'\s*:", body, re.MULTILINE))
    return keys

tr_keys = get_keys('tr')
en_keys = get_keys('en')
all_needed_keys = tr_keys.union(en_keys)

print(f"Total keys in 'tr': {len(tr_keys)}")
print(f"Total keys in 'en': {len(en_keys)}")
print(f"Total union keys: {len(all_needed_keys)}")

for loc in ['tr', 'en', 'de', 'fr', 'es', 'pt_BR', 'pt_PT', 'it', 'nl', 'pl', 'ru', 'ar', 'hi', 'zh', 'ja', 'ko', 'id']:
    loc_keys = get_keys(loc)
    missing = all_needed_keys - loc_keys
    print(f"Locale '{loc}': {len(loc_keys)} keys (Missing: {len(missing)})")
    if missing and len(missing) < 20:
        print(f"  Missing sample: {list(missing)[:10]}")

