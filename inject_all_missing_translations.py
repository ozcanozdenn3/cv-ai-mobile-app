import re
import json

loc_path = 'lib/services/localization_service.dart'

with open(loc_path, 'r', encoding='utf-8') as f:
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

all_locales = ['tr', 'en', 'en_GB', 'de', 'fr', 'es', 'es_MX', 'pt_BR', 'pt_PT', 'it', 'nl', 'pl', 'ru', 'ar', 'hi', 'zh', 'ja', 'ko', 'id']
extracted = {}
for loc in all_locales:
    extracted[loc] = extract_locale_dict(loc, text)

# Comprehensive translations for every missing key
extra_translations = {
    'lang_level_native': {
        'tr': 'Ana Dil (Native)',
        'en': 'Native / Bilingual',
        'de': 'Muttersprache (Native)',
        'fr': 'Langue maternelle (Natif)',
        'es': 'Lengua materna (Nativo)',
        'pt_BR': 'Língua materna (Nativo)',
        'it': 'Madrelingua (Nativo)',
        'nl': 'Moedertaal (Native)',
        'pl': 'Język ojczysty (Native)',
        'ru': 'Родной язык (Native)',
        'ar': 'اللغة الأم (Native)',
        'hi': 'मातृभाषा (Native)',
        'zh': '母语 (Native)',
        'ja': '母国語 (ネイティブ)',
        'ko': '모국어 (원어민)',
        'id': 'Bahasa Ibu (Native)'
    },
    'lang_level_c2': {
        'tr': 'C2 - İleri / Uzman',
        'en': 'C2 - Mastery / Proficient',
        'de': 'C2 - Verhandlungssicher (Exzellent)',
        'fr': 'C2 - Maîtrise parfaite',
        'es': 'C2 - Dominio eficaz',
        'pt_BR': 'C2 - Fluência total',
        'it': 'C2 - Padronanza completa',
        'nl': 'C2 - Volledige beheersing',
        'pl': 'C2 - Biegłość pełna',
        'ru': 'C2 - Свободное владение',
        'ar': 'C2 - إتقان تام واحترافي',
        'hi': 'C2 - पूर्ण दक्षता',
        'zh': 'C2 - 精通 / 接近母语',
        'ja': 'C2 - ネイティブレベル',
        'ko': 'C2 - 원어민 수준',
        'id': 'C2 - Mahir Sempurna'
    },
    'lang_level_c1': {
        'tr': 'C1 - İleri Düzey (Advanced)',
        'en': 'C1 - Advanced (Effective Operational)',
        'de': 'C1 - Fließend (Fortgeschritten)',
        'fr': 'C1 - Avancé (Autonome)',
        'es': 'C1 - Avanzado (Operativo)',
        'pt_BR': 'C1 - Avançado (Fluente)',
        'it': 'C1 - Avanzato (Fluente)',
        'nl': 'C1 - Gevorderd',
        'pl': 'C1 - Zaawansowany',
        'ru': 'C1 - Продвинутый (Advanced)',
        'ar': 'C1 - متقدم (Advanced)',
        'hi': 'C1 - उन्नत (Advanced)',
        'zh': 'C1 - 高级熟练 (Advanced)',
        'ja': 'C1 - 上級・ビジネスレベル',
        'ko': 'C1 - 고급 비즈니스 수준',
        'id': 'C1 - Tingkat Lanjut (Advanced)'
    },
    'lang_level_b2': {
        'tr': 'B2 - Orta Üstü (Upper-Intermediate)',
        'en': 'B2 - Upper-Intermediate',
        'de': 'B2 - Gute Kenntnisse',
        'fr': 'B2 - Intermédiaire supérieur',
        'es': 'B2 - Intermedio alto',
        'pt_BR': 'B2 - Intermediário superior',
        'it': 'B2 - Intermedio superiore',
        'nl': 'B2 - Hoger gemiddeld',
        'pl': 'B2 - Średniozaawansowany wyższy',
        'ru': 'B2 - Выше среднего (Upper-Intermediate)',
        'ar': 'B2 - فوق المتوسط',
        'hi': 'B2 - उच्च मध्यम',
        'zh': 'B2 - 中高级 (Upper-Intermediate)',
        'ja': 'B2 - 中上級・日常会話以上',
        'ko': 'B2 - 중상급',
        'id': 'B2 - Menengah Atas'
    },
    'lang_level_b1': {
        'tr': 'B1 - Orta Düzey (Intermediate)',
        'en': 'B1 - Intermediate',
        'de': 'B1 - Mittlere Kenntnisse',
        'fr': 'B1 - Intermédiaire',
        'es': 'B1 - Intermedio',
        'pt_BR': 'B1 - Intermediário',
        'it': 'B1 - Intermedio',
        'nl': 'B1 - Gemiddeld',
        'pl': 'B1 - Średniozaawansowany',
        'ru': 'B1 - Средний (Intermediate)',
        'ar': 'B1 - متوسط',
        'hi': 'B1 - मध्यम',
        'zh': 'B1 - 中级 (Intermediate)',
        'ja': 'B1 - 中級・日常会話',
        'ko': 'B1 - 중급',
        'id': 'B1 - Menengah'
    },
    'lang_level_a2': {
        'tr': 'A2 - Temel Düzey (Elementary)',
        'en': 'A2 - Elementary',
        'de': 'A2 - Grundkenntnisse',
        'fr': 'A2 - Élémentaire',
        'es': 'A2 - Elemental',
        'pt_BR': 'A2 - Básico',
        'it': 'A2 - Elementare',
        'nl': 'A2 - Basis',
        'pl': 'A2 - Podstawowy wyższy',
        'ru': 'A2 - Базовый (Elementary)',
        'ar': 'A2 - أساسي',
        'hi': 'A2 - बुनियादी',
        'zh': 'A2 - 初级 (Elementary)',
        'ja': 'A2 - 初級',
        'ko': 'A2 - 초급',
        'id': 'A2 - Dasar (Elementary)'
    },
    'lang_level_a1': {
        'tr': 'A1 - Başlangıç (Beginner)',
        'en': 'A1 - Beginner',
        'de': 'A1 - Anfänger',
        'fr': 'A1 - Débutant',
        'es': 'A1 - Principiante',
        'pt_BR': 'A1 - Iniciante',
        'it': 'A1 - Principiante',
        'nl': 'A1 - Beginnend',
        'pl': 'A1 - Początkujący',
        'ru': 'A1 - Начальный (Beginner)',
        'ar': 'A1 - مبتدئ',
        'hi': 'A1 - शुरुआती',
        'zh': 'A1 - 入门 (Beginner)',
        'ja': 'A1 - 入門',
        'ko': 'A1 - 입문',
        'id': 'A1 - Pemula (Beginner)'
    },
    'hint_project_title': {
        'tr': 'Yapay Zeka Destekli Mobil Uygulama',
        'en': 'AI-Powered Mobile Application',
        'de': 'KI-gestützte mobile Anwendung',
        'fr': 'Application Mobile Alimentée par l\'IA',
        'es': 'Aplicación móvil con Inteligencia Artificial',
        'pt_BR': 'Aplicativo Mobile com Inteligência Artificial',
        'it': 'Applicazione Mobile con Intelligenza Artificiale',
        'nl': 'AI-gestuurde mobiele applicatie',
        'pl': 'Aplikacja mobilna oparta na sztucznej inteligencji',
        'ru': 'Мобильное приложение на базе ИИ',
        'ar': 'تطبيق جوال مدعوم بالذكاء الاصطناعي',
        'hi': 'एआई-संचालित मोबाइल एप्लिकेशन',
        'zh': 'AI 智能移动端应用程序',
        'ja': 'AI搭載型モバイルアプリケーション',
        'ko': 'AI 기반 스마트 모바일 애플리케이션',
        'id': 'Aplikasi Mobile Bertenaga AI'
    },
    'hint_project_tech': {
        'tr': 'Flutter, Dart, Python, Supabase, ML Kit',
        'en': 'Flutter, Dart, Python, Supabase, ML Kit',
        'de': 'Flutter, Dart, Python, Supabase, ML Kit',
        'fr': 'Flutter, Dart, Python, Supabase, ML Kit',
        'es': 'Flutter, Dart, Python, Supabase, ML Kit',
        'pt_BR': 'Flutter, Dart, Python, Supabase, ML Kit',
        'it': 'Flutter, Dart, Python, Supabase, ML Kit',
        'nl': 'Flutter, Dart, Python, Supabase, ML Kit',
        'pl': 'Flutter, Dart, Python, Supabase, ML Kit',
        'ru': 'Flutter, Dart, Python, Supabase, ML Kit',
        'ar': 'Flutter, Dart, Python, Supabase, ML Kit',
        'hi': 'Flutter, Dart, Python, Supabase, ML Kit',
        'zh': 'Flutter, Dart, Python, Supabase, ML Kit',
        'ja': 'Flutter, Dart, Python, Supabase, ML Kit',
        'ko': 'Flutter, Dart, Python, Supabase, ML Kit',
        'id': 'Flutter, Dart, Python, Supabase, ML Kit'
    },
    'hint_ref_name': {
        'tr': 'Prof. Dr. Ahmet Yılmaz',
        'en': 'Dr. Robert Jenkins',
        'de': 'Prof. Dr. Klaus Müller',
        'fr': 'Prof. Dr. Pierre Martin',
        'es': 'Dr. Alejandro Morales',
        'pt_BR': 'Dr. Fernando Oliveira',
        'it': 'Prof. Dott. Alessandro Bianchi',
        'nl': 'Prof. Dr. Jan de Vries',
        'pl': 'Prof. dr hab. Piotr Wiśniewski',
        'ru': 'Проф. д-р Михаил Иванов',
        'ar': 'د. خالد بن سلطان آل نهيان',
        'hi': 'डॉ. राजेश कुमार',
        'zh': '李明 教授 / 技术副总裁',
        'ja': '鈴木 一郎 教授・CTO',
        'ko': '박지훈 교수 / 상무',
        'id': 'Dr. Hendra Wijaya'
    },
    'hint_ref_position': {
        'tr': 'Mühendislik Direktörü / Bölüm Başkanı',
        'en': 'Engineering Director / Department Head',
        'de': 'Technischer Direktor / Abteilungsleiter',
        'fr': 'Directeur Technique / Chef de Département',
        'es': 'Director de Ingeniería / Jefe de Departamento',
        'pt_BR': 'Diretor de Engenharia / Chefe de Departamento',
        'it': 'Direttore Tecnico / Responsabile di Dipartimento',
        'nl': 'Technisch Directeur / Afdelingshoofd',
        'pl': 'Dyrektor ds. Inżynierii / Kierownik Katedry',
        'ru': 'Технический директор / Заведующий кафедрой',
        'ar': 'مدير الهندسة / رئيس القسم',
        'hi': 'इंजीनियरिंग निदेशक / विभागाध्यक्ष',
        'zh': '技术研发总监 / 学院院长',
        'ja': '開発本部長・教授',
        'ko': '연구개발 본부장 / 학과장',
        'id': 'Direktur Teknik / Kepala Departemen'
    },
    'hint_ref_company': {
        'tr': 'Global Tech Labs & İTÜ',
        'en': 'Global Tech Labs & Stanford',
        'de': 'Global Tech Labs & TU München',
        'fr': 'Global Tech Labs & Sorbonne',
        'es': 'Global Tech Labs & UPM',
        'pt_BR': 'Global Tech Labs & USP',
        'it': 'Global Tech Labs & PoliMi',
        'nl': 'Global Tech Labs & UvA',
        'pl': 'Global Tech Labs & PW',
        'ru': 'Global Tech Labs & МГУ',
        'ar': 'Global Tech Labs & جامعة خليفة',
        'hi': 'Global Tech Labs & IIT',
        'zh': '全球前沿科技实验室 & 上海交大',
        'ja': 'グローバルテックラボ＆東京大学',
        'ko': '글로벌 테크 랩스 & 서울대학교',
        'id': 'Global Tech Labs & UI'
    },
    'cv_tpl_subtitle_modern': {
        'tr': 'Sol sütunlu dengeli, modern ve profesyonel tasarım',
        'en': 'Balanced modern two-column layout with sidebar',
        'de': 'Ausgewogenes modernes zweispaltiges Layout mit Seitenleiste',
        'fr': 'Mise en page moderne à deux colonnes avec barre latérale',
        'es': 'Diseño moderno de dos columnas con barra lateral',
        'pt_BR': 'Layout moderno de duas colunas com barra lateral',
        'it': 'Layout moderno a due colonne con barra laterale',
        'nl': 'Gebalanceerde moderne lay-out met zijbalk',
        'pl': 'Zrównoważony nowoczesny układ dwukolumnowy z panelem bocznym',
        'ru': 'Сбалансированный современный двухколоночный макет с боковой панелью',
        'ar': 'تصميم حديث ومتوازن من عمودين مع شريط جانبي',
        'hi': 'साइडबार के साथ संतुलित आधुनिक दो-कॉलम लेआउट',
        'zh': '左侧边栏双栏专业布局，信息结构清晰紧凑',
        'ja': '左サイドバー付きの洗練された2カラムモダンレイアウト',
        'ko': '균형 잡힌 사이드바 2단 현대적 레이아웃',
        'id': 'Tata letak modern dua kolom yang seimbang dengan bilah samping'
    },
    'cv_tpl_badge_popular': {
        'tr': 'Çok Popüler',
        'en': 'Most Popular',
        'de': 'Sehr Beliebt',
        'fr': 'Très Populaire',
        'es': 'Muy Popular',
        'pt_BR': 'Muito Popular',
        'it': 'Molto Popolare',
        'nl': 'Zeer Populair',
        'pl': 'Najpopularniejszy',
        'ru': 'Популярный',
        'ar': 'الأكثر شعبية',
        'hi': 'सबसे लोकप्रिय',
        'zh': '最受欢迎',
        'ja': '人気No.1',
        'ko': '가장 인기',
        'id': 'Paling Populer'
    },
    'cv_tpl_subtitle_tech': {
        'tr': 'ATS tarayıcıları ve yazılım mühendisleri için optimize',
        'en': 'Optimized for ATS scanners and software engineers',
        'de': 'Optimiert für ATS-Scanner und Software-Ingenieure',
        'fr': 'Optimisé pour les scanners ATS et les ingénieurs',
        'es': 'Optimizado para sistemas ATS e ingenieros',
        'pt_BR': 'Otimizado para sistemas ATS e desenvolvedores',
        'it': 'Ottimizzato per scanner ATS e ingegneri software',
        'nl': 'Geoptimaliseerd voor ATS-scanners en ontwikkelaars',
        'pl': 'Zoptymalizowany pod kątem systemów ATS i inżynierów',
        'ru': 'Оптимизирован для систем ATS и IT-специалистов',
        'ar': 'محسّن لأنظمة فحص السير الذاتية ATS ومهندسي البرمجيات',
        'hi': 'ATS स्कैनर और सॉफ्टवेयर इंजीनियरों के लिए अनुकूलित',
        'zh': '针对 ATS 简历初筛与软件工程师深度优化',
        'ja': 'ATS自動選考システム・ITエンジニア向け最適化',
        'ko': 'ATS 자동 필터링 및 개발자 최적화 레이아웃',
        'id': 'Dioptimalkan untuk pemindai ATS dan insinyur perangkat lunak'
    },
    'cv_tpl_badge_ats': {
        'tr': 'ATS Uyumlu',
        'en': 'ATS Friendly',
        'de': 'ATS-Optimiert',
        'fr': 'Compatible ATS',
        'es': 'Compatible ATS',
        'pt_BR': 'Compatível ATS',
        'it': 'Ottimizzato ATS',
        'nl': 'ATS-Vriendelijk',
        'pl': 'Zgodny z ATS',
        'ru': 'ATS-Совместимый',
        'ar': 'متوافق مع ATS',
        'hi': 'ATS अनुकूल',
        'zh': 'ATS 友好',
        'ja': 'ATS最適化',
        'ko': 'ATS 최적화',
        'id': 'Ramah ATS'
    },
    'cv_tpl_subtitle_exec': {
        'tr': 'Üst düzey yöneticiler ve kurumsal liderler için prestijli',
        'en': 'Prestigious single-column for executive & C-level leaders',
        'de': 'Repräsentatives einspaltiges Layout für Führungskräfte',
        'fr': 'Prestigieux format pour cadres supérieurs et dirigeants',
        'es': 'Prestigioso formato para directivos y líderes corporativos',
        'pt_BR': 'Formato de prestígio para executivos e líderes C-Level',
        'it': 'Formato prestigioso per dirigenti e leader aziendali',
        'nl': 'Representatief formaat voor leidinggevenden en directie',
        'pl': 'Prestiżowy układ dla kadry zarządzającej i liderów',
        'ru': 'Престижный классический формат для топ-менеджеров и лидеров',
        'ar': 'تصميم مرموق للمديرين التنفيذيين وقادة الأعمال',
        'hi': 'कार्यकारी और सी-स्तरीय नेताओं के लिए प्रतिष्ठित प्रारूप',
        'zh': '专为高管与企业领袖打造的严谨权威经典单栏布局',
        'ja': '役員・エグゼクティブ・管理職向けの風格ある格式高いデザイン',
        'ko': '임원진 및 경영진을 위한 권위 있는 클래식 레이아웃',
        'id': 'Format prestisius untuk eksekutif dan pemimpin C-Level'
    },
    'cv_tpl_badge_exec': {
        'tr': 'Yönetici',
        'en': 'Executive',
        'de': 'Führungskraft',
        'fr': 'Cadre Dirigeant',
        'es': 'Ejecutivo',
        'pt_BR': 'Executivo',
        'it': 'Dirigenziale',
        'nl': 'Directie',
        'pl': 'Kierowniczy',
        'ru': 'Руководитель',
        'ar': 'تنفيذي',
        'hi': 'कार्यकारी',
        'zh': '高管精英',
        'ja': 'エグゼクティブ',
        'ko': '임원/경영',
        'id': 'Eksekutif'
    },
    'cv_tpl_subtitle_design': {
        'tr': 'Tasarımcılar, sanat yönetmenleri ve yaratıcı roller için',
        'en': 'Tailored for designers, creative directors & artists',
        'de': 'Maßgeschneidert für Designer und kreative Berufe',
        'fr': 'Conçu pour les designers, directeurs artistiques et créatifs',
        'es': 'Diseñado para diseñadores y perfiles creativos',
        'pt_BR': 'Desenvolvido para designers e profissionais criativos',
        'it': 'Progettato per designer e figure creative',
        'nl': 'Ontworpen voor ontwerpers en creatieve professionals',
        'pl': 'Stworzony dla projektantów i twórców',
        'ru': 'Создан для дизайнеров, арт-директоров и творческих профессий',
        'ar': 'مصمم خصيصاً للمصممين والمخرجين الفنيين والمبدعين',
        'hi': 'डिजाइनरों और रचनात्मक पेशेवरों के लिए तैयार',
        'zh': '专为设计师、创意总监与艺术从业者量身定制',
        'ja': 'デザイナー・クリエイター向けの洗練された視覚的デザイン',
        'ko': '디자이너 및 크리에이티브 직군을 위한 감각적인 서식',
        'id': 'Dirancang untuk desainer dan profesional kreatif'
    },
    'cv_tpl_badge_design': {
        'tr': 'Kreatif',
        'en': 'Creative',
        'de': 'Kreativ',
        'fr': 'Créatif',
        'es': 'Creativo',
        'pt_BR': 'Criativo',
        'it': 'Creativo',
        'nl': 'Creatief',
        'pl': 'Kreatywny',
        'ru': 'Креативный',
        'ar': 'إبداعي',
        'hi': 'रचनात्मक',
        'zh': '创意设计',
        'ja': 'クリエイティブ',
        'ko': '크리에이티브',
        'id': 'Kreatif'
    },
    'cv_tpl_subtitle_elegant': {
        'tr': 'Sade, okunabilir ve zamansız tipografi odaklı şablon',
        'en': 'Timeless typography-focused minimalist template',
        'de': 'Zeitloses minimalistisches typografisches Design',
        'fr': 'Modèle minimaliste intemporel axé sur la typographie',
        'es': 'Plantilla minimalista atemporal centrada en la tipografía',
        'pt_BR': 'Modelo minimalista atemporal focado em tipografia',
        'it': 'Modello minimalista senza tempo focalizzato sulla tipografia',
        'nl': 'Tijdloos minimalistisch ontwerp gericht op typografie',
        'pl': 'Ponadczasowy minimalistyczny szablon typograficzny',
        'ru': 'Минималистичный макет с упором на чистую типографику',
        'ar': 'قالب بسيط وخالد يركز على فن الخط والطباعة النقية',
        'hi': 'टाइपोग्राफी-केंद्रित न्यूनतम टेम्पलेट',
        'zh': '极简素雅排版，注重呼吸感与纯粹文字美感',
        'ja': 'タイポグラフィの美しさを極めたミニマル・シンプルデザイン',
        'ko': '타이포그래피 중심의 깔끔하고 절제된 미니멀 디자인',
        'id': 'Templat minimalis abadi yang berfokus pada tipografi'
    },
    'cv_tpl_badge_elegant': {
        'tr': 'Zarif & Sade',
        'en': 'Minimalist',
        'de': 'Minimalistisch',
        'fr': 'Épuré & Élégant',
        'es': 'Minimalista',
        'pt_BR': 'Minimalista',
        'it': 'Elegante',
        'nl': 'Minimalistisch',
        'pl': 'Elegancki',
        'ru': 'Минимализм',
        'ar': 'أنيق وبسيط',
        'hi': 'सुरुचिपूर्ण',
        'zh': '极简素雅',
        'ja': '洗練・ミニマル',
        'ko': '미니멀',
        'id': 'Minimalis'
    },
    'cv_tpl_subtitle_academic': {
        'tr': 'Akademisyenler, araştırmacılar ve burs başvuruları için',
        'en': 'Structured for researchers, scholars & grant applications',
        'de': 'Strukturiert für Forscher, Wissenschaftler und Stipendien',
        'fr': 'Structuré pour chercheurs, universitaires et bourses',
        'es': 'Estructurado para investigadores, becas y ámbito académico',
        'pt_BR': 'Estruturado para pesquisadores, acadêmicos e bolsas',
        'it': 'Strutturato per ricercatori, studiosi e borse di studio',
        'nl': 'Gestructureerd voor onderzoekers en wetenschappers',
        'pl': 'Ustrukturyzowany dla naukowców i stypendystów',
        'ru': 'Для исследователей, ученых, публикаций и грантов',
        'ar': 'مخصص للباحثين والأكاديميين والمنح الدراسية',
        'hi': 'शोधकर्ताओं, विद्वानों और अनुदान आवेदनों के लिए',
        'zh': '适用于科研学者、高校申请与学术基金申报',
        'ja': '研究者・大学院・学術論文・助成金申請に最適な構成',
        'ko': '연구원, 교수진, 학술 연구 및 장학 지원용 서식',
        'id': 'Terstruktur untuk peneliti, akademisi & aplikasi beasiswa'
    },
    'cv_tpl_badge_academic': {
        'tr': 'Akademik',
        'en': 'Academic',
        'de': 'Akademisch',
        'fr': 'Académique',
        'es': 'Académico',
        'pt_BR': 'Acadêmico',
        'it': 'Accademico',
        'nl': 'Academisch',
        'pl': 'Akademicki',
        'ru': 'Академический',
        'ar': 'أكاديمي',
        'hi': 'अकादमिक',
        'zh': '学术权威',
        'ja': 'アカデミック',
        'ko': '학술/연구',
        'id': 'Akademis'
    },
    'cv_tpl_subtitle_engineering': {
        'tr': 'Yüksek bilgi yoğunluklu, mühendislik odaklı ızgara',
        'en': 'High-density structured grid for technical roles',
        'de': 'Hochdichtes strukturiertes Raster für technische Berufe',
        'fr': 'Grille haute densité pour profils d\'ingénierie',
        'es': 'Cuadrícula de alta densidad para perfiles técnicos',
        'pt_BR': 'Grade de alta densidade para funções técnicas',
        'it': 'Griglia ad alta densità per ruoli ingegneristici',
        'nl': 'Gestructureerd raster met hoge informatiedichtheid',
        'pl': 'Siatka o wysokiej gęstości danych dla inżynierów',
        'ru': 'Плотная структурированная сетка для технических ролей',
        'ar': 'شبكة عالية الكثافة للمعلومات تناسب الأدوار الهندسية',
        'hi': 'तकनीकी भूमिकाओं के लिए उच्च-घनत्व ग्रिड',
        'zh': '高信息密度网格布局，专为工程技术与精细数据打造',
        'ja': '情報密度を高めたエンジニアリング特化グリッド配置',
        'ko': '엔지니어링 직무를 위한 고밀도 정보 그리드 서식',
        'id': 'Kisi terstruktur kepadatan tinggi untuk peran teknik'
    },
    'cv_tpl_badge_engineering': {
        'tr': 'Mühendislik',
        'en': 'Engineering',
        'de': 'Ingenieurwesen',
        'fr': 'Ingénierie',
        'es': 'Ingeniería',
        'pt_BR': 'Engenharia',
        'it': 'Ingegneria',
        'nl': 'Techniek',
        'pl': 'Inżynieria',
        'ru': 'Инженерия',
        'ar': 'هندسي',
        'hi': 'इंजीनियरिंग',
        'zh': '工程技术',
        'ja': 'エンジニアリング',
        'ko': '엔지니어링',
        'id': 'Teknik'
    },
    'cv_tpl_subtitle_metric': {
        'tr': 'İlerleme çubukları, KPI ve sayısal başarı vurgusu',
        'en': 'Visual metrics, progress meters and KPI highlight',
        'de': 'Visuelle Metriken, Fortschrittsbalken und KPI-Fokus',
        'fr': 'Métriques visuelles, jauges et mise en valeur des KPI',
        'es': 'Métricas visuales, barras de progreso y KPIs clave',
        'pt_BR': 'Métricas visuais, barras de progresso e KPIs',
        'it': 'Metriche visive, indicatori di progresso e KPI',
        'nl': 'Visuele statistieken, voortgangsbalken en KPI-focus',
        'pl': 'Wizualne metryki, paski postępu i akcent na KPI',
        'ru': 'Визуальные индикаторы прогресса и метрики KPI',
        'ar': 'مؤشرات أداء بصرية ورسوم بيانية لإبراز الإنجازات الرقمية',
        'hi': 'दृश्य मेट्रिक्स, प्रगति मीटर और KPI हाइलाइट',
        'zh': '可视化进度条与量化数据图表，突出关键 KPI 成果',
        'ja': 'スキルチャートや数値実績KPIを際立たせるインフォグラフィック',
        'ko': '진행도 게이지와 정량적 KPI 성과를 강조하는 인포그래픽',
        'id': 'Metrik visual, pengukur kemajuan, dan sorotan KPI'
    },
    'cv_tpl_badge_metric': {
        'tr': 'Metrik Odaklı',
        'en': 'Metric-Driven',
        'de': 'Metrik-Fokussiert',
        'fr': 'Orienté Métriques',
        'es': 'Basado en Métricas',
        'pt_BR': 'Focado em Métricas',
        'it': 'Orientato alle Metriche',
        'nl': 'Resultaatgericht',
        'pl': 'Metryczny',
        'ru': 'Метрический',
        'ar': 'مرتكز على الأرقام',
        'hi': 'माप-संचालित',
        'zh': '数据量化',
        'ja': '数値重視',
        'ko': '성과 중심',
        'id': 'Berbasis Metrik'
    },
    'cv_tpl_subtitle_luxury': {
        'tr': 'Altın varak hissi, zarif kenarlıklar ve lüks kurumsal duruş',
        'en': 'Gold foil accents, refined borders and luxury corporate feel',
        'de': 'Goldene Akzente, edle Ränder und luxuriöser Auftritt',
        'fr': 'Touches dorées, bordures raffinées et allure corporate haut de gamme',
        'es': 'Acentos dorados, bordes refinados y presencia ejecutiva de lujo',
        'pt_BR': 'Toques dourados, bordas refinadas e presença de prestígio',
        'it': 'Accenti dorati, bordi raffinati e presenza aziendale di lusso',
        'nl': 'Gouden accenten, verfijnde randen en luxe uitstraling',
        'pl': 'Złote akcenty, wyrafinowane obramowania i luksusowy charakter',
        'ru': 'Золотые акценты, изящные рамки и премиальный корпоративный стиль',
        'ar': 'لمسات ذهبية راقية وإطارات أنيقة تمنح طابعاً فخماً',
        'hi': 'गोल्ड एक्सेंट, परिष्कृत बॉर्डर और लक्जरी कॉर्पोरेट लुक',
        'zh': '黑金尊享质感，精细边框与奢华商务气场',
        'ja': 'ゴールドアクセントと上質フレームが放つ最高級の品格',
        'ko': '골드 엑센트와 세련된 테두리의 최고급 프레스티지 서식',
        'id': 'Aksen emas mewah, batas halus, dan kesan korporat premium'
    },
    'cv_tpl_badge_luxury': {
        'tr': 'Prestij VIP',
        'en': 'Prestige VIP',
        'de': 'Prestige VIP',
        'fr': 'Prestige VIP',
        'es': 'Prestigio VIP',
        'pt_BR': 'Prestígio VIP',
        'it': 'Prestigio VIP',
        'nl': 'Prestige VIP',
        'pl': 'Prestiż VIP',
        'ru': 'Престиж VIP',
        'ar': 'نخبة VIP',
        'hi': 'प्रतिष्ठित VIP',
        'zh': '尊享 VIP',
        'ja': 'プレミアムVIP',
        'ko': '프레스티지 VIP',
        'id': 'Prestisius VIP'
    },
    'cv_tpl_subtitle_nordic': {
        'tr': 'Kuzeyli ferahlık, geniş beyaz alanlar ve modern sadelik',
        'en': 'Nordic freshness, generous whitespace & modern clarity',
        'de': 'Nordische Frische, viel Weißraum und moderne Klarheit',
        'fr': 'Fraîcheur nordique, espaces aérés et clarté moderne',
        'es': 'Frescura nórdica, amplios espacios en blanco y claridad',
        'pt_BR': 'Frescor nórdico, amplos espaços em branco e clareza',
        'it': 'Freschezza nordica, ampi spazi bianchi e chiarezza',
        'nl': 'Noordse frisheid, veel witruimte en moderne helderheid',
        'pl': 'Nordycka świeżość, przestronność i nowoczesna przejrzystość',
        'ru': 'Скандинавская свежесть, просторный макет и кристальная четкость',
        'ar': 'بساطة نوردية مع مساحات بيضاء واسعة ووضوح فائق',
        'hi': 'नॉर्डिक ताजगी, पर्याप्त सफेद स्थान और आधुनिक स्पष्टता',
        'zh': '北欧通透留白艺术，视野开阔且极具现代感',
        'ja': '北欧の透明感・心地よい余白が生み出す究極の清潔感',
        'ko': '북유럽 감성의 여백과 현대적이고 명쾌한 레이아웃',
        'id': 'Kesegaran Nordik, ruang putih luas & kejelasan modern'
    },
    'cv_tpl_badge_nordic': {
        'tr': 'İskandinav',
        'en': 'Nordic Clean',
        'de': 'Skandinavisch',
        'fr': 'Nordique',
        'es': 'Nórdico',
        'pt_BR': 'Nórdico',
        'it': 'Nordico',
        'nl': 'Scandinavisch',
        'pl': 'Nordycki',
        'ru': 'Скандинавский',
        'ar': 'إسكندنافي',
        'hi': 'स्कैंडिनेवियाई',
        'zh': '北欧清爽',
        'ja': '北欧クリーン',
        'ko': '노르딕 클린',
        'id': 'Nordik Bersih'
    },
    'cv_new_bullet': {
        'tr': 'Yeni madde...',
        'en': 'New bullet item...',
        'de': 'Neuer Punkt...',
        'fr': 'Nouvel élément...',
        'es': 'Nuevo elemento...',
        'pt_BR': 'Novo item...',
        'it': 'Nuova voce...',
        'nl': 'Nieuw item...',
        'pl': 'Nowy punkt...',
        'ru': 'Новый пункт...',
        'ar': 'عنصر جديد...',
        'hi': 'नया बिंदु...',
        'zh': '新增要点内容...',
        'ja': '新しい項目...',
        'ko': '새 항목...',
        'id': 'Poin baru...'
    }
}

for k, trans in extra_translations.items():
    for loc in all_locales:
        root_loc = loc if loc in trans else loc.split('_')[0]
        if root_loc in trans:
            extracted[loc][k] = trans[root_loc]
        elif 'en' in trans:
            extracted[loc][k] = trans['en']

# Write back to localization_service.dart
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

print("Injected all missing translations into all 19 locales successfully!")
