import re
import json

loc_path = 'lib/services/localization_service.dart'
with open(loc_path, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Update getQuickTraits to support ALL 15 languages
traits_code = '''  static List<String> getQuickTraits() {
    final lang = currentLocale.toLowerCase();
    if (lang.startsWith('tr')) {
      return ['Problem Çözme', 'Analitik Düşünme', 'Takım Çalışması & Liderlik', 'Hızlı Öğrenme & Adaptasyon', 'Zaman Yönetimi', 'Sonuç Odaklılık', 'Çevik (Agile / Scrum)', 'Etkili İletişim', 'Kritik Düşünme', 'Stres Yönetimi', 'Müzakere & İkna', 'İnovatif Zihniyet', 'Detay Odaklılık', 'Kendi Kendini Motive Etme'];
    }
    if (lang.startsWith('de')) {
      return ['Problemlösung', 'Analytisches Denken', 'Teamarbeit & Führung', 'Schnelle Auffassungsgabe', 'Zeitmanagement', 'Ergebnisorientierung', 'Agile / Scrum', 'Effektive Kommunikation', 'Kritisches Denken', 'Stressresistenz', 'Verhandlungsgeschick', 'Innovationsgeist', 'Detailorientierung', 'Eigenmotivation'];
    }
    if (lang.startsWith('fr')) {
      return ['Résolution de problèmes', 'Esprit analytique', 'Travail d\\\'équipe & Leadership', 'Adaptabilité rapide', 'Gestion du temps', 'Orientation résultats', 'Méthodes Agiles / Scrum', 'Communication efficace', 'Pensée critique', 'Gestion du stress', 'Négociation & Persuasion', 'Esprit d\\\'innovation', 'Sens du détail', 'Autonomie & Motivation'];
    }
    if (lang.startsWith('es')) {
      return ['Resolución de problemas', 'Pensamiento analítico', 'Trabajo en equipo y liderazgo', 'Rápido aprendizaje', 'Gestión del tiempo', 'Orientación a resultados', 'Agile / Scrum', 'Comunicación asertiva', 'Pensamiento crítico', 'Manejo del estrés', 'Negociación', 'Innovación y creatividad', 'Atención al detalle', 'Automotivación'];
    }
    if (lang.startsWith('pt')) {
      return ['Resolução de problemas', 'Pensamento analítico', 'Trabalho em equipe e liderança', 'Aprendizado rápido', 'Gestão do tempo', 'Foco em resultados', 'Metodologias Ágeis / Scrum', 'Comunicação assertiva', 'Pensamento crítico', 'Gestão de estresse', 'Negociação e persuasão', 'Mentalidade inovadora', 'Atenção aos detalhes', 'Automotivação'];
    }
    if (lang.startsWith('it')) {
      return ['Problem Solving', 'Pensiero analitico', 'Lavoro di squadra e leadership', 'Apprendimento rapido', 'Gestione del tempo', 'Orientamento ai risultati', 'Metodologie Agile / Scrum', 'Comunicazione efficace', 'Pensiero critico', 'Gestione dello stress', 'Negoziazione', 'Mentalità innovativa', 'Attenzione ai dettagli', 'Forte motivazione'];
    }
    if (lang.startsWith('nl')) {
      return ['Probleemoplossend vermogen', 'Analytisch denken', 'Teamwork & Leiderschap', 'Snel lerend vermogen', 'Tijdmanagement', 'Resultaatgerichtheid', 'Agile / Scrum methodiek', 'Effectieve communicatie', 'Kritisch denken', 'Stressbestendigheid', 'Onderhandelingsvaardig', 'Innovatieve instelling', 'Oog voor detail', 'Zelfgemotiveerd'];
    }
    if (lang.startsWith('pl')) {
      return ['Rozwiązywanie problemów', 'Myślenie analityczne', 'Praca zespołowa i przywództwo', 'Szybkie uczenie się', 'Zarządzanie czasem', 'Nastawienie na wyniki', 'Metodyki Agile / Scrum', 'Skuteczna komunikacja', 'Krytyczne myślenie', 'Odporność na stres', 'Zdolności negocjacyjne', 'Innowacyjność', 'Dbałość o szczegóły', 'Wysoka motywacja'];
    }
    if (lang.startsWith('ru')) {
      return ['Решение сложных задач', 'Аналитическое мышление', 'Командная работа и лидерство', 'Быстрая обучаемость', 'Тайм-менеджмент', 'Ориентация на результат', 'Agile / Scrum методологии', 'Эффективная коммуникация', 'Критическое мышление', 'Стрессоустойчивость', 'Навыки ведения переговоров', 'Инновационное мышление', 'Внимание к деталям', 'Самомотивация'];
    }
    if (lang.startsWith('ar')) {
      return ['حل المشكلات المعقدة', 'التفكير التحليلي', 'العمل الجماعي والقيادة', 'سرعة التعلم والتكيف', 'إدارة الوقت', 'التركيز على النتائج', 'منهجيات Agile / Scrum', 'التواصل الفعال', 'التفكير النقدي', 'إدارة الضغوط', 'مهارات التفاوض والإقناع', 'عقلية ابتكارية', 'الاهتمام بالتفاصيل', 'التحفيز الذاتي'];
    }
    if (lang.startsWith('hi')) {
      return ['समस्या समाधान', 'विश्लेषणात्मक सोच', 'टीम वर्क और नेतृत्व', 'त्वरित सीखना और अनुकूलन', 'समय प्रबंधन', 'परिणाम-उन्मुख', 'Agile / Scrum पद्धतियां', 'प्रभावी संचार', 'आलोचनात्मक सोच', 'तनाव प्रबंधन', 'बातचीत और अनुनय', 'नवाचारी दृष्टिकोण', 'विवरण पर ध्यान', 'स्व-प्रेरित'];
    }
    if (lang.startsWith('zh')) {
      return ['复杂问题解决能力', '结构化与分析思维', '团队协作与领导力', '敏捷学习与快速适应', '高效时间管理', '目标与结果导向', '敏捷开发 (Agile / Scrum)', '跨部门高效沟通', '批判性思维', '高抗压能力', '商务谈判与说服力', '创新探索思维', '严谨注重细节', '高度自驱力'];
    }
    if (lang.startsWith('ja')) {
      return ['問題解決能力', '論理的・分析的思考力', 'チームワーク＆リーダーシップ', '高い学習意欲・適応力', 'タイムマネジメント', '成果・目標志向', 'アジャイル・Scrum実践', '円滑なコミュニケーション', 'クリティカルシンキング', 'ストレス耐性', '交渉・説得力', 'イノベーション志向', '細部へのこだわり', '高いセルフモチベーション'];
    }
    if (lang.startsWith('ko')) {
      return ['문제 해결 능력', '논리적/분석적 사고', '팀워크 및 리더십', '빠른 학습 및 적응력', '시간 관리 능력', '성과 및 목표 지향', '애자일(Agile/Scrum)', '효과적인 커뮤니케이션', '비판적 사고', '스트레스 관리 및 회복 탄력성', '협상 및 설득력', '혁신적 마인드셋', '꼼꼼한 디테일 추구', '강한 자기 주도성'];
    }
    if (lang.startsWith('id')) {
      return ['Pemecahan Masalah', 'Berpikir Analitis', 'Kerja Tim & Kepemimpinan', 'Cepat Belajar & Adaptif', 'Manajemen Waktu', 'Berorientasi pada Hasil', 'Metodologi Agile / Scrum', 'Komunikasi Efektif', 'Berpikir Kritis', 'Manajemen Stres', 'Negosiasi & Persuasi', 'Pola Pikir Inovatif', 'Perhatian pada Detail', 'Motivasi Diri Tinggi'];
    }
    return ['Problem Solving', 'Analytical Thinking', 'Teamwork & Leadership', 'Fast Learner & Adaptive', 'Time Management', 'Results-Driven', 'Agile / Scrum Methodologies', 'Effective Communication', 'Critical Thinking', 'Stress Management', 'Negotiation & Persuasion', 'Innovative Mindset', 'Attention to Detail', 'Self-Motivated'];
  }'''

# 2. Update getQuickCustomTitles to support ALL 15 languages
titles_code = '''  static List<String> getQuickCustomTitles() {
    final lang = currentLocale.toLowerCase();
    if (lang.startsWith('tr')) {
      return ['🏆 Ödüller & Başarılar', '📜 Sertifikalar', '🎗️ Gönüllülük', '📚 Yayınlar', '🎯 Hobiler & İlgi Alanları'];
    }
    if (lang.startsWith('de')) {
      return ['🏆 Auszeichnungen & Erfolge', '📜 Zertifikate', '🎗️ Ehrenamt', '📚 Publikationen', '🎯 Hobbys & Interessen'];
    }
    if (lang.startsWith('fr')) {
      return ['🏆 Prix & Distinctions', '📜 Certifications', '🎗️ Bénévolat', '📚 Publications', '🎯 Centres d\\\'intérêt'];
    }
    if (lang.startsWith('es')) {
      return ['🏆 Premios y Logros', '📜 Certificaciones', '🎗️ Voluntariado', '📚 Publicaciones', '🎯 Hobbies e Intereses'];
    }
    if (lang.startsWith('pt')) {
      return ['🏆 Prêmios e Conquistas', '📜 Certificações', '🎗️ Voluntariado', '📚 Publicações', '🎯 Hobbies e Interesses'];
    }
    if (lang.startsWith('it')) {
      return ['🏆 Premi e Riconoscimenti', '📜 Certificazioni', '🎗️ Volontariato', '📚 Pubblicazioni', '🎯 Hobby e Interessi'];
    }
    if (lang.startsWith('nl')) {
      return ['🏆 Onderscheidingen & Prijzen', '📜 Certificaten', '🎗️ Vrijwilligerswerk', '📚 Publicaties', '🎯 Hobby\\\'s & Interesses'];
    }
    if (lang.startsWith('pl')) {
      return ['🏆 Nagrody i Wyróżnienia', '📜 Certyfikaty', '🎗️ Wolontariat', '📚 Publikacje', '🎯 Zainteresowania'];
    }
    if (lang.startsWith('ru')) {
      return ['🏆 Награды и Достижения', '📜 Сертификаты', '🎗️ Волонтерство', '📚 Публикации', '🎯 Хобби и Интересы'];
    }
    if (lang.startsWith('ar')) {
      return ['🏆 الجوائز والإنجازات', '📜 الشهادات المهنية', '🎗️ العمل التطوعي', '📚 المنشورات والأبحاث', '🎯 الهوايات والاهتمامات'];
    }
    if (lang.startsWith('hi')) {
      return ['🏆 पुरस्कार और सम्मान', '📜 प्रमाणपत्र', '🎗️ स्वयंसेवा', '📚 प्रकाशन', '🎯 रुचियां और शौक'];
    }
    if (lang.startsWith('zh')) {
      return ['🏆 荣誉与奖项', '📜 资格证书', '🎗️ 志愿服务', '📚 学术成果与出版物', '🎯 兴趣爱好'];
    }
    if (lang.startsWith('ja')) {
      return ['🏆 受賞歴・表彰', '📜 資格・認定証', '🎗️ ボランティア活動', '📚 執筆・論文', '🎯 趣味・特技'];
    }
    if (lang.startsWith('ko')) {
      return ['🏆 수상 경력 및 표창', '📜 자격증 및 수료증', '🎗️ 봉사 활동', '📚 연구 및 출판물', '🎯 취미 및 관심사'];
    }
    if (lang.startsWith('id')) {
      return ['🏆 Penghargaan & Prestasi', '📜 Sertifikasi', '🎗️ Sukarelawan', '📚 Publikasi', '🎯 Hobi & Minat'];
    }
    return ['🏆 Honors & Awards', '📜 Certifications', '🎗️ Volunteering', '📚 Publications', '🎯 Hobbies & Interests'];
  }'''

# 3. Update getThemePalettes to support ALL 15 languages
palettes_code = '''  static List<Map<String, dynamic>> getThemePalettes() {
    final lang = currentLocale.toLowerCase();
    if (lang.startsWith('tr')) {
      return [
        {'name': 'Safir Mavi', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'Zümrüt Yeşil', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'Asil Mürdüm', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'Yakut Kırmızı', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'Kehribar Altın', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'Obsidyen Siyah', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('de')) {
      return [
        {'name': 'Saphirblau', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'Smaragdgrün', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'Edles Violett', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'Rubinrot', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'Bernsteingold', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'Obsidianschwarz', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('fr')) {
      return [
        {'name': 'Bleu Saphir', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'Vert Émeraude', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'Violet Noble', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'Rouge Rubis', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'Or Ambré', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'Noir Obsidienne', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('es')) {
      return [
        {'name': 'Azul Zafiro', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'Verde Esmeralda', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'Púrpura Noble', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'Rojo Rubí', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'Oro Ámbar', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'Negro Obsidiana', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('pt')) {
      return [
        {'name': 'Azul Safira', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'Verde Esmeralda', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'Púrpura Nobre', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'Vermelho Rubi', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'Ouro Âmbar', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'Preto Obsidiana', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('it')) {
      return [
        {'name': 'Blu Zaffiro', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'Verde Smeraldo', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'Viola Nobile', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'Rosso Rubino', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'Oro Ambrato', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'Nero Ossidiana', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('nl')) {
      return [
        {'name': 'Saffierblauw', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'Smaragdgroen', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'Koninklijk Paars', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'Robijnrood', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'Barnsteengoud', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'Obsidiaanzwart', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('pl')) {
      return [
        {'name': 'Szafirowy Błękit', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'Szmaragdowa Zieleń', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'Szlachetny Fiolet', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'Rubinowa Czerwień', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'Bursztynowe Złoto', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'Obsydianowa Czerń', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('ru')) {
      return [
        {'name': 'Сапфировый синий', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'Изумрудный зеленый', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'Благородный фиолетовый', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'Рубиновый красный', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'Янтарное золото', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'Обсидиановый черный', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('ar')) {
      return [
        {'name': 'أزرق ياقوتي', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'أخضر زمردي', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'أرجواني ملكي', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'أحمر ياقوتي', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'ذهبي كهرماني', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'أسود سبجي', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('hi')) {
      return [
        {'name': 'नीलम नीला', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'पन्ना हरा', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'शाही बैंगनी', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'माणिक लाल', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'अम्बर स्वर्ण', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'काला ऑब्सिडियन', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('zh')) {
      return [
        {'name': '经典宝石蓝', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': '极光翡翠绿', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': '高贵紫罗兰', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': '热烈宝石红', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': '琥珀流金', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': '曜石深邃黑', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('ja')) {
      return [
        {'name': 'サファイアブルー', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'エメラルドグリーン', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'ノーブルパープル', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'ルビーレッド', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'アンバーゴールド', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'オブシディアンブラック', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('ko')) {
      return [
        {'name': '사파이어 블루', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': '에메랄드 그린', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': '노블 퍼플', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': '루비 레드', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': '앰버 골드', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': '옵시디언 블랙', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    if (lang.startsWith('id')) {
      return [
        {'name': 'Biru Safir', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
        {'name': 'Hijau Zamrud', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
        {'name': 'Ungu Elegan', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
        {'name': 'Merah Rubi', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
        {'name': 'Emas Amber', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
        {'name': 'Hitam Obsidian', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
      ];
    }
    return [
      {'name': 'Sapphire Blue', 'color': const Color(0xFF2563EB), 'hex': 0xFF2563EB},
      {'name': 'Emerald Green', 'color': const Color(0xFF10B981), 'hex': 0xFF10B981},
      {'name': 'Noble Purple', 'color': const Color(0xFF8B5CF6), 'hex': 0xFF8B5CF6},
      {'name': 'Ruby Red', 'color': const Color(0xFFEF4444), 'hex': 0xFFEF4444},
      {'name': 'Amber Gold', 'color': const Color(0xFFF59E0B), 'hex': 0xFFF59E0B},
      {'name': 'Obsidian Black', 'color': const Color(0xFF0F172A), 'hex': 0xFF0F172A},
    ];
  }'''

# Replace helper methods in localization_service.dart
# Match from `static List<String> getQuickTraits()` to end of `getThemePalettes()`
helper_pattern = re.compile(r'  static List<String> getQuickTraits\(\)\s*\{.*?return \[\s*\{\\\'name\\\': \\\'Sapphire Blue\\\'.*?\n  \}', re.DOTALL)
if not helper_pattern.search(text):
    # Try finding `static List<String> getQuickTraits()` until `static String _detectDeviceLocale()`
    start_traits = text.find('  static List<String> getQuickTraits() {')
    end_palettes = text.find('  static String _detectDeviceLocale()')
    if start_traits != -1 and end_palettes != -1:
        new_helpers = f"{traits_code}\n\n{titles_code}\n\n{palettes_code}\n\n"
        text = text[:start_traits] + new_helpers + text[end_palettes:]
        with open(loc_path, 'w', encoding='utf-8') as f:
            f.write(text)
        print("Replaced all helper methods with full 15-language support!")
    else:
        print("Could not find start/end of helpers")
else:
    print("Found exact helper pattern")

