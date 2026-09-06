import re

loc_path = 'lib/services/localization_service.dart'
with open(loc_path, 'r', encoding='utf-8') as f:
    text = f.read()

extra_system_keys = {
    'login_pill_templates': {
        'tr': '6 Pro CV Şablonu',
        'en': '6 Pro CV Templates',
        'de': '6 Pro Lebenslauf-Vorlagen',
        'fr': '6 Modèles de CV Pro',
        'es': '6 Plantillas de CV Pro',
        'pt_BR': '6 Modelos de CV Pro',
        'it': '6 Modelli di CV Pro',
        'nl': '6 Pro CV-sjablonen',
        'pl': '6 Profesjonalnych szablonów CV',
        'ru': '6 Профессиональных шаблонов резюме',
        'ar': '6 قوالب سيرة ذاتية احترافية',
        'hi': '6 प्रो सीवी टेम्पलेट्स',
        'zh': '6 套专业精选简历模板',
        'ja': '6種類のプロ仕様履歴書テンプレート',
        'ko': '6가지 프로페셔널 이력서 템플릿',
        'id': '6 Templat CV Profesional'
    },
    'paywall_feat_office': {
        'tr': 'Office Dönüştürücüler (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'en': 'Office Converters (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'de': 'Office-Konverter (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'fr': 'Convertisseurs Office (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'es': 'Convertidores Office (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'pt_BR': 'Conversores Office (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'it': 'Convertitori Office (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'nl': 'Office-converters (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'pl': 'Konwertery Office (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'ru': 'Конвертеры Office (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'ar': 'محولات أوفيس (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'hi': 'ऑफिस कन्वर्टर्स (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'zh': 'Office 全能格式互转 (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'ja': 'Office変換機能 (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'ko': 'Office 파일 변환기 (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)',
        'id': 'Konverter Office (Word, Excel, PPTX ➔ PDF/DOCX/XLSX)'
    },
    'paywall_feat_cloud': {
        'tr': 'Supabase Bulut Yedekleme & Sınırsız Arşiv',
        'en': 'Supabase Cloud Backup & Unlimited Archive',
        'de': 'Supabase Cloud-Backup & Unbegrenztes Archiv',
        'fr': 'Sauvegarde Cloud Supabase & Archive Illimitée',
        'es': 'Copia de seguridad en la nube Supabase y archivo ilimitado',
        'pt_BR': 'Backup em nuvem Supabase e arquivo ilimitado',
        'it': 'Backup su Cloud Supabase e archivio illimitato',
        'nl': 'Supabase Cloud-back-up & Onbeperkt archief',
        'pl': 'Kopia zapasowa w chmurze Supabase i nielimitowane archiwum',
        'ru': 'Облачное резервное копирование Supabase и безлимитный архив',
        'ar': 'نسخ احتياطي سحابي مع Supabase وأرشيف غير محدود',
        'hi': 'Supabase क्लाउड बैकअप और असीमित संग्रह',
        'zh': 'Supabase 云端实时同步与无限文档档案库',
        'ja': 'Supabaseクラウドバックアップ＆無制限アーカイブ',
        'ko': 'Supabase 클라우드 실시간 백업 및 무제한 보관함',
        'id': 'Pencadangan Cloud Supabase & Arsip Tanpa Batas'
    },
    'cv_new_slide': {
        'tr': 'Yeni Slayt',
        'en': 'New Slide',
        'de': 'Neue Folie',
        'fr': 'Nouvelle Diapositive',
        'es': 'Nueva Diapositiva',
        'pt_BR': 'Novo Slide',
        'it': 'Nuova Diapositiva',
        'nl': 'Nieuwe Dia',
        'pl': 'Nowy Slajd',
        'ru': 'Новый слайд',
        'ar': 'شريحة جديدة',
        'hi': 'नई स्लाइड',
        'zh': '新幻灯片',
        'ja': '新しいスライド',
        'ko': '새 슬라이드',
        'id': 'Slide Baru'
    },
    'share_pdf_to_word_msg': {
        'tr': 'CV AI ile PDF\'ten Word\'e dönüştürülen belge.',
        'en': 'Document converted from PDF to Word with CV AI Studio.',
        'de': 'Mit CV AI Studio von PDF in Word konvertiertes Dokument.',
        'fr': 'Document converti de PDF en Word avec CV AI Studio.',
        'es': 'Documento convertido de PDF a Word con CV AI Studio.',
        'pt_BR': 'Documento convertido de PDF para Word com CV AI Studio.',
        'it': 'Documento convertito da PDF a Word con CV AI Studio.',
        'nl': 'Document geconverteerd van PDF naar Word met CV AI Studio.',
        'pl': 'Dokument przekonwertowany z formatu PDF na Word w programie CV AI Studio.',
        'ru': 'Документ, конвертированный из PDF в Word с помощью CV AI Studio.',
        'ar': 'مستند تم تحويله من PDF إلى Word عبر CV AI Studio.',
        'hi': 'CV AI Studio के साथ PDF से Word में कनवर्ट किया गया दस्तावेज़।',
        'zh': '使用 CV AI Studio 从 PDF 智能转换生成的 Word 文档。',
        'ja': 'CV AI Studio で PDF から Word に変換されたドキュメント。',
        'ko': 'CV AI Studio를 통해 PDF에서 Word로 변환된 문서입니다.',
        'id': 'Dokumen dikonversi dari PDF ke Word dengan CV AI Studio.'
    }
}

all_locales = ['tr', 'en', 'en_GB', 'de', 'fr', 'es', 'es_MX', 'pt_BR', 'pt_PT', 'it', 'nl', 'pl', 'ru', 'ar', 'hi', 'zh', 'ja', 'ko', 'id']

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

extracted = {}
for loc in all_locales:
    extracted[loc] = extract_locale_dict(loc, text)

for k, trans in extra_system_keys.items():
    for loc in all_locales:
        root_loc = loc if loc in trans else loc.split('_')[0]
        if root_loc in trans:
            extracted[loc][k] = trans[root_loc]
        elif 'en' in trans:
            extracted[loc][k] = trans['en']

start_marker = 'static final Map<String, Map<String, String>> _translations = {'
start_pos = text.find(start_marker)
prefix = text[:start_pos + len(start_marker)]

end_pos = text.rfind('  };')
if end_pos == -1:
    end_pos = text.rfind('};')
suffix = text[end_pos:]

locale_order = ['tr', 'en', 'en_GB', 'de', 'fr', 'es', 'es_MX', 'pt_BR', 'pt_PT', 'it', 'nl', 'pl', 'ru', 'ar', 'hi', 'zh', 'ja', 'ko', 'id']
locale_blocks_code = []
for loc in locale_order:
    d = extracted[loc]
    lines = [f"    // {loc.upper()} ({loc})", f"    '{loc}': {{"]
    for k in sorted(d.keys()):
        v = d[k]
        v_escaped = v.replace('\\', '\\\\').replace("'", "\\'").replace('\n', '\\n')
        lines.append(f"      '{k}': '{v_escaped}',")
    lines.append("    },")
    locale_blocks_code.append("\n".join(lines))

final_code = prefix + "\n" + "\n\n".join(locale_blocks_code) + "\n" + suffix

with open(loc_path, 'w', encoding='utf-8') as f:
    f.write(final_code)

print("Extra system keys injected successfully!")
