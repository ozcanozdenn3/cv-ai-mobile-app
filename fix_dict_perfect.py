import re

loc_path = 'lib/services/localization_service.dart'
with open(loc_path, 'r', encoding='utf-8') as f:
    text = f.read()

# Let's extract each locale's dictionary by finding 'key': 'value'
def parse_locale_map(loc, text):
    pattern = rf"'{loc}'\s*:\s*\{{(.*?)\n\s*\}},"
    m = re.search(pattern, text, re.DOTALL)
    if not m:
        return {}
    content = m.group(1)
    res = {}
    # match each key: value line
    lines = content.split('\n')
    for line in lines:
        line = line.strip()
        if not line or line.startswith('//'):
            continue
        # match 'key': 'value',
        km = re.match(r"^'([a-zA-Z0-9_\-]+)'\s*:\s*'(.*)',?$", line)
        if km:
            k = km.group(1)
            v = km.group(2)
            # unescape excessive backslashes
            v = v.replace('\\\\', '\\')
            while '\\\\' in v:
                v = v.replace('\\\\', '\\')
            # clean \n
            v = v.replace(r'\n', '\n')
            # remove trailing backslashes if any
            v = v.rstrip('\\')
            res[k] = v
        else:
            # check triple quotes or other formats
            km3 = re.match(r"^'([a-zA-Z0-9_\-]+)'\s*:\s*'''(.*)''',?$", line, re.DOTALL)
            if km3:
                res[km3.group(1)] = km3.group(2)
    return res

all_locales = ['tr', 'en', 'en_GB', 'de', 'fr', 'es', 'es_MX', 'pt_BR', 'pt_PT', 'it', 'nl', 'pl', 'ru', 'ar', 'hi', 'zh', 'ja', 'ko', 'id']
parsed_all = {}
for loc in all_locales:
    parsed_all[loc] = parse_locale_map(loc, text)
    print(f"Parsed {loc}: {len(parsed_all[loc])} keys")

# Build the cleanest Dart code
def escape_dart_string(s):
    # escape single quotes and newlines
    s = s.replace('\\', '') # remove stray backslashes
    s = s.replace("'", r"\'")
    s = s.replace('\n', r'\n')
    return s

start_marker = 'static final Map<String, Map<String, String>> _translations = {'
start_pos = text.find(start_marker)
prefix = text[:start_pos + len(start_marker)]

end_pos = text.rfind('  /// Translate a key')
if end_pos == -1:
    end_pos = text.find('  static String tr(String rawKey)')

# find the closing }; before tr
end_brace_pos = text.rfind('  };', 0, end_pos)
suffix = text[end_brace_pos:]

blocks = []
for loc in all_locales:
    d = parsed_all[loc]
    lines = [f"    // {loc.upper()} ({loc})", f"    '{loc}': {{"]
    for k in sorted(d.keys()):
        val = escape_dart_string(d[k])
        lines.append(f"      '{k}': '{val}',")
    lines.append("    },")
    blocks.append("\n".join(lines))

full_dart = prefix + "\n" + "\n\n".join(blocks) + "\n" + suffix
with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(full_dart)

print("Generated clean Dart file!")
