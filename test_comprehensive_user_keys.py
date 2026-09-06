import re

with open('lib/services/localization_service.dart', 'r', encoding='utf-8') as f:
    text = f.read()

def extract_locale_dict(locale, text):
    pattern = rf"'{locale}'\s*:\s*\{{(.*?)\n\s*\}},"
    m = re.search(pattern, text, re.DOTALL)
    if not m:
        return {}
    body = m.group(1)
    entries = {}
    entry_pattern = re.compile(r"^\s*'([a-zA-Z0-9_\-]+)'\s*:\s*(?:'([^']*(?:\\'[^']*)*)'|'''(.*?)''')", re.MULTILINE | re.DOTALL)
    for match in entry_pattern.finditer(body):
        k = match.group(1)
        v = match.group(2) if match.group(2) is not None else match.group(3)
        entries[k] = v
    return entries

check_keys = [
    'gallery',
    'add',
    'cv_add_experience',
    'cv_add_education',
    'cv_add_language',
    'cv_add_project',
    'cv_add_reference',
    'cv_create_section',
    'cv_add_custom_skill',
    'cv_add_custom_trait',
    'cv_popular_skills',
    'cv_skills_sub',
    'cv_soft_skills_title',
    'cv_soft_skills_sub',
    'cv_ready_traits_pool',
    'cv_skill_level',
    'skill_expert',
    'skill_advanced',
    'skill_intermediate',
    'skill_basic',
    'cv_lang_name',
    'cv_lang_level',
    'lang_level_native',
    'lang_level_c1',
    'lang_level_b2',
    'cv_projects_title',
    'cv_projects_sub',
    'cv_proj_title',
    'hint_project_title',
    'cv_references_title',
    'cv_references_sub',
    'cv_ref_name',
    'hint_ref_name',
    'cv_custom_sections_title',
    'cv_custom_sections_sub',
    'hint_custom_section_title',
    'cv_ordering_title',
    'cv_ordering_sub',
    'cv_active_layout',
    'cv_inspect_pdf',
    'cv_template_title',
    'cv_theme_title',
    'cv_tpl_subtitle_modern',
    'cv_tpl_badge_popular',
    'cv_tpl_badge_ats',
    'cv_tpl_badge_luxury'
]

locales = ['ru', 'de', 'fr', 'es', 'pt_BR', 'it', 'nl', 'pl', 'ar', 'hi', 'zh', 'ja', 'ko', 'id']

missing_by_locale = {}
for loc in locales:
    d = extract_locale_dict(loc, text)
    missing = [k for k in check_keys if k not in d]
    missing_by_locale[loc] = missing
    print(f"Locale {loc.upper()}: {len(check_keys) - len(missing)}/{len(check_keys)} keys found. Missing: {missing}")

