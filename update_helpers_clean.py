with open('lib/services/localization_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

start_marker = '  static List<String> getQuickTraits() {'
end_marker = '  /// Translate a key with fallback cascade'

start_pos = text.find(start_marker)
end_pos = text.find(end_marker)

if start_pos == -1 or end_pos == -1:
    print(f"Error finding markers: start={start_pos}, end={end_pos}")
    exit(1)

with open('update_localization_all_helpers.py', 'r', encoding='utf-8') as f:
    helper_script = f.read()

traits_start = helper_script.find("traits_code = '''") + len("traits_code = '''")
traits_end = helper_script.find("'''\n\n# 2. Update")
traits_code = helper_script[traits_start:traits_end]

titles_start = helper_script.find("titles_code = '''") + len("titles_code = '''")
titles_end = helper_script.find("'''\n\n# 3. Update")
titles_code = helper_script[titles_start:titles_end]

palettes_start = helper_script.find("palettes_code = '''") + len("palettes_code = '''")
palettes_end = helper_script.find("'''\n\n# Replace")
palettes_code = helper_script[palettes_start:palettes_end]

new_block = f"{traits_code}\n\n{titles_code}\n\n{palettes_code}\n\n"

new_text = text[:start_pos] + new_block + text[end_pos:]

with open('lib/services/localization_service.dart', 'w', encoding='utf-8') as f:
    f.write(new_text)

print("Helpers successfully replaced!")
