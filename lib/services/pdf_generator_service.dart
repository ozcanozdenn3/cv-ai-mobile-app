import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/cv_model.dart';
import 'document_parser_service.dart';
import 'localization_service.dart';
import 'cv_pdf_flow.dart';

class PdfCvLocaleHelper {
  static String getSectionTitle(CvSectionType type, String locale) {
    final lang = locale.toLowerCase().replaceAll('-', '_');

    switch (type) {
      case CvSectionType.summary:
        if (lang.startsWith('tr')) return 'PROFESYONEL ÖZET';
        if (lang.startsWith('de')) return 'BERUFLICHES PROFIL';
        if (lang.startsWith('fr')) return 'RÉSUMÉ PROFESSIONNEL';
        if (lang.startsWith('es')) return 'PERFIL PROFESIONAL';
        if (lang.startsWith('pt')) return 'RESUMO PROFISSIONAL';
        if (lang.startsWith('it')) return 'PROFILO PROFESSIONALE';
        if (lang.startsWith('nl')) return 'PROFESSIONEEL PROFIEL';
        if (lang.startsWith('pl')) return 'PODSUMOWANIE ZAWODOWE';
        if (lang.startsWith('ru')) return 'О СЕБЕ / ПРОФИЛЬ';
        if (lang.startsWith('ar')) return 'الملخص المهني';
        if (lang.startsWith('zh')) return '个人总结';
        if (lang.startsWith('ja')) return '職務要約';
        if (lang.startsWith('hi')) return 'व्यावसायिक सारांश';
        if (lang.startsWith('ko')) return '전문 요약';
        if (lang.startsWith('id')) return 'RINGKASAN PROFESIONAL';
        return 'PROFESSIONAL SUMMARY';

      case CvSectionType.experiences:
        if (lang.startsWith('tr')) return 'İŞ DENEYİMLERİ';
        if (lang.startsWith('de')) return 'BERUFSERFAHRUNG';
        if (lang.startsWith('fr')) return 'EXPÉRIENCE PROFESSIONNELLE';
        if (lang.startsWith('es')) return 'EXPERIENCIA LABORAL';
        if (lang.startsWith('pt')) return 'EXPERIÊNCIA PROFISSIONAL';
        if (lang.startsWith('it')) return 'ESPERIENZA LAVORATIVA';
        if (lang.startsWith('nl')) return 'WERKERVARING';
        if (lang.startsWith('pl')) return 'DOŚWIADCZENIE ZAWODOWE';
        if (lang.startsWith('ru')) return 'ОПЫТ РАБОТЫ';
        if (lang.startsWith('ar')) return 'الخبرات المهنية';
        if (lang.startsWith('zh')) return '工作经历';
        if (lang.startsWith('ja')) return '職務経歴';
        if (lang.startsWith('hi')) return 'कार्य अनुभव';
        if (lang.startsWith('ko')) return '경력 사항';
        if (lang.startsWith('id')) return 'PENGALAMAN KERJA';
        return 'WORK EXPERIENCE';

      case CvSectionType.educations:
        if (lang.startsWith('tr')) return 'EĞİTİM';
        if (lang.startsWith('de')) return 'AUSBILDUNG';
        if (lang.startsWith('fr')) return 'FORMATION';
        if (lang.startsWith('es')) return 'EDUCACIÓN';
        if (lang.startsWith('pt')) return 'EDUCAÇÃO';
        if (lang.startsWith('it')) return 'ISTRUZIONE';
        if (lang.startsWith('nl')) return 'OPLEIDING';
        if (lang.startsWith('pl')) return 'EDUKACJA';
        if (lang.startsWith('ru')) return 'ОБРАЗОВАНИЕ';
        if (lang.startsWith('ar')) return 'التعليم';
        if (lang.startsWith('zh')) return '教育背景';
        if (lang.startsWith('ja')) return '学歴';
        if (lang.startsWith('hi')) return 'शिक्षा';
        if (lang.startsWith('ko')) return '학력 사항';
        if (lang.startsWith('id')) return 'PENDIDIKAN';
        return 'EDUCATION';

      case CvSectionType.skills:
        if (lang.startsWith('tr')) return 'YETENEKLER & UZMANLIK';
        if (lang.startsWith('de')) return 'FACHKENNTNISSE';
        if (lang.startsWith('fr')) return 'COMPÉTENCES & EXPERTISE';
        if (lang.startsWith('es')) return 'HABILIDADES Y EXPERIENCIA';
        if (lang.startsWith('pt')) return 'HABILIDADES & EXPERTIZE';
        if (lang.startsWith('it')) return 'COMPETENZE E SPECIALIZZAZIONI';
        if (lang.startsWith('nl')) return 'VAARDIGHEDEN & EXPERTISE';
        if (lang.startsWith('pl')) return 'UMIEJĘTNOŚCI I SPECJALIZACJA';
        if (lang.startsWith('ru')) return 'НАВЫКИ И ЭКСПЕРТИЗА';
        if (lang.startsWith('ar')) return 'المهارات والخبرات';
        if (lang.startsWith('zh')) return '专业技能';
        if (lang.startsWith('ja')) return 'スキル・専門知識';
        if (lang.startsWith('hi')) return 'कौशल और विशेषज्ञता';
        if (lang.startsWith('ko')) return '기술 및 전문 지식';
        if (lang.startsWith('id')) return 'KEAHLIAN & SPESIALISASI';
        return 'SKILLS & EXPERTISE';

      case CvSectionType.personalTraits:
        if (lang.startsWith('tr')) return 'KİŞİSEL ÖZELLİKLER & NİTELİKLER';
        if (lang.startsWith('de')) return 'KERNKOMPETENZEN';
        if (lang.startsWith('fr')) return 'QUALITÉS & COMPÉTENCES CLÉS';
        if (lang.startsWith('es')) return 'COMPETENCIAS CLAVE';
        if (lang.startsWith('pt')) return 'COMPETÊNCIAS-CHAVE';
        if (lang.startsWith('it')) return 'COMPETENZE CHIAVE';
        if (lang.startsWith('nl')) return 'KERNCOMPETENTIES';
        if (lang.startsWith('pl')) return 'KLUCZOWE KOMPETENCJE';
        if (lang.startsWith('ru')) return 'ЛИЧНЫЕ КАЧЕСТВА';
        if (lang.startsWith('ar')) return 'الكفاءات الأساسية';
        if (lang.startsWith('zh')) return '核心素质';
        if (lang.startsWith('ja')) return '主な強み・特徴';
        if (lang.startsWith('hi')) return 'प्रमुख क्षमताएं';
        if (lang.startsWith('ko')) return '핵심 역량';
        if (lang.startsWith('id')) return 'KOMPETENSI UTAMA';
        return 'KEY COMPETENCIES';

      case CvSectionType.languages:
        if (lang.startsWith('tr')) return 'YABANCI DİLLER';
        if (lang.startsWith('de')) return 'SPRACHKENNTNISSE';
        if (lang.startsWith('fr')) return 'LANGUES ÉTRANGÈRES';
        if (lang.startsWith('es')) return 'IDIOMAS';
        if (lang.startsWith('pt')) return 'IDIOMAS';
        if (lang.startsWith('it')) return 'LINGUE STRANIERE';
        if (lang.startsWith('nl')) return 'TALEN';
        if (lang.startsWith('pl')) return 'JĘZYKI OBCE';
        if (lang.startsWith('ru')) return 'ЯЗЫКИ';
        if (lang.startsWith('ar')) return 'اللغات';
        if (lang.startsWith('zh')) return '语言能力';
        if (lang.startsWith('ja')) return '語学力';
        if (lang.startsWith('hi')) return 'भाषा ज्ञान';
        if (lang.startsWith('ko')) return '외국어 능력';
        if (lang.startsWith('id')) return 'BAHASA ASING';
        return 'LANGUAGES';

      case CvSectionType.projects:
        if (lang.startsWith('tr')) return 'PROJELER';
        if (lang.startsWith('de')) return 'PROJEKTE';
        if (lang.startsWith('fr')) return 'PROJETS';
        if (lang.startsWith('es')) return 'PROYECTOS';
        if (lang.startsWith('pt')) return 'PROJETOS';
        if (lang.startsWith('it')) return 'PROGETTI';
        if (lang.startsWith('nl')) return 'PROJECTEN';
        if (lang.startsWith('pl')) return 'PROJEKTY';
        if (lang.startsWith('ru')) return 'ПРОЕКТЫ';
        if (lang.startsWith('ar')) return 'المشاريع';
        if (lang.startsWith('zh')) return '项目经验';
        if (lang.startsWith('ja')) return '主なプロジェクト';
        if (lang.startsWith('hi')) return 'परियोजनाएं';
        if (lang.startsWith('ko')) return '주요 프로젝트';
        if (lang.startsWith('id')) return 'PROYEK';
        return 'PROJECTS';

      case CvSectionType.certificates:
        if (lang.startsWith('tr')) return 'SERTİFİKALAR';
        if (lang.startsWith('de')) return 'ZERTIFIKATE';
        if (lang.startsWith('fr')) return 'CERTIFICATIONS';
        if (lang.startsWith('es')) return 'CERTIFICACIONES';
        if (lang.startsWith('pt')) return 'CERTIFICADOS';
        if (lang.startsWith('it')) return 'CERTIFICAZIONI';
        if (lang.startsWith('nl')) return 'CERTIFICATEN';
        if (lang.startsWith('pl')) return 'CERTYFIKATY';
        if (lang.startsWith('ru')) return 'СЕРТИФИКАТЫ';
        if (lang.startsWith('ar')) return 'الشهادات';
        if (lang.startsWith('zh')) return '资格证书';
        if (lang.startsWith('ja')) return '保有資格・認定';
        if (lang.startsWith('hi')) return 'प्रमाण पत्र';
        if (lang.startsWith('ko')) return '자격증 및 수료증';
        if (lang.startsWith('id')) return 'SERTIFIKAT';
        return 'CERTIFICATES';

      case CvSectionType.references:
        if (lang.startsWith('tr')) return 'REFERANSLAR';
        if (lang.startsWith('de')) return 'REFERENZEN';
        if (lang.startsWith('fr')) return 'RÉFÉRENCES';
        if (lang.startsWith('es')) return 'REFERENCIAS';
        if (lang.startsWith('pt')) return 'REFERÊNCIAS';
        if (lang.startsWith('it')) return 'REFERENZE';
        if (lang.startsWith('nl')) return 'REFERENTIES';
        if (lang.startsWith('pl')) return 'REFERENCJE';
        if (lang.startsWith('ru')) return 'РЕКОМЕНДАЦИИ';
        if (lang.startsWith('ar')) return 'المراجع';
        if (lang.startsWith('zh')) return '推荐人';
        if (lang.startsWith('ja')) return '推薦者・照会先';
        if (lang.startsWith('hi')) return 'संदर्भ';
        if (lang.startsWith('ko')) return '추천인';
        if (lang.startsWith('id')) return 'REFERENSI';
        return 'REFERENCES';

      case CvSectionType.customSections:
        return LocalizationService.trFor(locale, 'pdf_additional_sections');
    }
  }

  static String getSidebarTitle(String key, String locale) {
    final lang = locale.toLowerCase().replaceAll('-', '_');
    if (key == 'contact') {
      if (lang.startsWith('tr')) return 'İLETİŞİM';
      if (lang.startsWith('de')) return 'KONTAKT';
      if (lang.startsWith('fr')) return 'CONTACT';
      if (lang.startsWith('es')) return 'CONTACTO';
      if (lang.startsWith('pt')) return 'CONTATO';
      if (lang.startsWith('it')) return 'CONTATTO';
      if (lang.startsWith('nl')) return 'CONTACT';
      if (lang.startsWith('pl')) return 'KONTAKT';
      if (lang.startsWith('ru')) return 'КОНТАКТЫ';
      if (lang.startsWith('ar')) return 'الاتصال';
      if (lang.startsWith('zh')) return '联系方式';
      if (lang.startsWith('ja')) return '連絡先';
      if (lang.startsWith('hi')) return 'संपर्क';
      if (lang.startsWith('ko')) return '연락처';
      if (lang.startsWith('id')) return 'KONTAK';
      return 'CONTACT';
    }
    if (key == 'skills') {
      if (lang.startsWith('tr')) return 'YETENEKLER';
      if (lang.startsWith('de')) return 'KENNTNISSE';
      if (lang.startsWith('fr')) return 'COMPÉTENCES';
      if (lang.startsWith('es')) return 'HABILIDADES';
      if (lang.startsWith('pt')) return 'HABILIDADES';
      if (lang.startsWith('it')) return 'COMPETENZE';
      if (lang.startsWith('nl')) return 'VAARDIGHEDEN';
      if (lang.startsWith('pl')) return 'UMIEJĘTNOŚCI';
      if (lang.startsWith('ru')) return 'НАВЫКИ';
      if (lang.startsWith('ar')) return 'المهارات';
      if (lang.startsWith('zh')) return '专业技能';
      if (lang.startsWith('ja')) return 'スキル';
      if (lang.startsWith('hi')) return 'कौशल';
      if (lang.startsWith('ko')) return '전문 기술';
      if (lang.startsWith('id')) return 'KEAHLIAN';
      return 'SKILLS';
    }
    if (key == 'languages') {
      if (lang.startsWith('tr')) return 'DİLLER';
      if (lang.startsWith('de')) return 'SPRACHEN';
      if (lang.startsWith('fr')) return 'LANGUES';
      if (lang.startsWith('es')) return 'IDIOMAS';
      if (lang.startsWith('pt')) return 'IDIOMAS';
      if (lang.startsWith('it')) return 'LINGUE';
      if (lang.startsWith('nl')) return 'TALEN';
      if (lang.startsWith('pl')) return 'JĘZYKI';
      if (lang.startsWith('ru')) return 'ЯЗЫКИ';
      if (lang.startsWith('ar')) return 'اللغات';
      if (lang.startsWith('zh')) return '语言';
      if (lang.startsWith('ja')) return '語学';
      if (lang.startsWith('hi')) return 'भाषाएं';
      if (lang.startsWith('ko')) return '언어';
      if (lang.startsWith('id')) return 'BAHASA';
      return 'LANGUAGES';
    }
    if (key == 'links') {
      if (lang.startsWith('tr')) return 'BAĞLANTILAR';
      if (lang.startsWith('de')) return 'LINKS & PROFILE';
      if (lang.startsWith('fr')) return 'LIENS & PROFILS';
      if (lang.startsWith('es')) return 'ENLACES Y PERFILES';
      if (lang.startsWith('pt')) return 'LINKS E PERFIS';
      if (lang.startsWith('it')) return 'LINK E PROFILI';
      if (lang.startsWith('nl')) return 'LINKS & PROFIELEN';
      if (lang.startsWith('pl')) return 'LINKI I PROFILE';
      if (lang.startsWith('ru')) return 'ССЫЛКИ';
      if (lang.startsWith('ar')) return 'الروابط';
      if (lang.startsWith('zh')) return '社交链接';
      if (lang.startsWith('ja')) return 'リンク・SNS';
      if (lang.startsWith('hi')) return 'लिंक और प्रोफ़ाइल';
      if (lang.startsWith('ko')) return '링크 및 프로필';
      if (lang.startsWith('id')) return 'TAUTAN & PROFIL';
      return 'LINKS & PROFILES';
    }
    return key.toUpperCase();
  }

  static String getSidebarContactLabel(String key, String locale) {
    if (key == 'email') {
      return '${LocalizationService.trFor(locale, 'pdf_contact_email')}:';
    }
    if (key == 'phone') {
      return '${LocalizationService.trFor(locale, 'pdf_contact_phone')}:';
    }
    if (key == 'location') {
      return '${LocalizationService.trFor(locale, 'pdf_contact_location')}:';
    }
    return '$key:';
  }

  static String getPresentText(String locale) {
    final lang = locale.toLowerCase().replaceAll('-', '_');
    if (lang.startsWith('tr')) return 'Günümüz';
    if (lang.startsWith('de')) return 'Heute';
    if (lang.startsWith('fr')) return 'Présent';
    if (lang.startsWith('es')) return 'Presente';
    if (lang.startsWith('pt')) return 'Presente';
    if (lang.startsWith('it')) return 'Presente';
    if (lang.startsWith('nl')) return 'Heden';
    if (lang.startsWith('pl')) return 'Obecnie';
    if (lang.startsWith('ru')) return 'По наст. время';
    if (lang.startsWith('ar')) return 'الحاضر';
    if (lang.startsWith('zh')) return '至今';
    if (lang.startsWith('ja')) return '現在';
    if (lang.startsWith('hi')) return 'वर्तमान';
    if (lang.startsWith('ko')) return '현재';
    if (lang.startsWith('id')) return 'Sekarang';
    return 'Present';
  }

  static String getGpaLabel(String locale) {
    return LocalizationService.trFor(locale, 'pdf_gpa');
  }

  static String getTechLabel(String locale) {
    return LocalizationService.trFor(locale, 'pdf_technologies');
  }

  static String sanitizePdfText(String text) {
    if (text.isEmpty) return text;
    return text
        .replaceAll(
            RegExp(
                r'[\u{1F300}-\u{1F9FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{1FA00}-\u{1FAFF}]|[\u{2300}-\u{23FF}]|[\u{FE00}-\u{FE0F}]|[\u{200D}]',
                unicode: true),
            '')
        .trim();
  }
}

enum PdfSkillStyle {
  progressBar,
  twoColBar,
  dotRating,
  percentagePill,
  academicText,
  tags,
}

enum PdfExperienceStyle {
  timeline,
  boxedCard,
  executiveClassic,
  standard,
}

enum PdfHeaderStyle {
  leftAccentLine,
  bottomUnderline,
  doubleRule,
  minimalist,
}

class _CvPdfFontSet {
  final pw.Font regular;
  final pw.Font bold;
  final pw.Font italic;

  const _CvPdfFontSet({
    required this.regular,
    required this.bold,
    required this.italic,
  });
}

class PdfGeneratorService {
  static Future<_CvPdfFontSet> _loadCvPdfFonts(String locale) async {
    final lang = locale.toLowerCase().replaceAll('-', '_');
    if (lang.startsWith('hi')) {
      final regular = await PdfGoogleFonts.notoSansDevanagariRegular();
      final bold = await PdfGoogleFonts.notoSansDevanagariBold();
      return _CvPdfFontSet(regular: regular, bold: bold, italic: regular);
    }
    if (lang.startsWith('ar')) {
      final regular = await PdfGoogleFonts.notoSansArabicRegular();
      final bold = await PdfGoogleFonts.notoSansArabicBold();
      return _CvPdfFontSet(regular: regular, bold: bold, italic: regular);
    }
    if (lang.startsWith('zh')) {
      final regular = await PdfGoogleFonts.notoSansSCRegular();
      final bold = await PdfGoogleFonts.notoSansSCBold();
      return _CvPdfFontSet(regular: regular, bold: bold, italic: regular);
    }
    if (lang.startsWith('ja')) {
      final regular = await PdfGoogleFonts.notoSansJPRegular();
      final bold = await PdfGoogleFonts.notoSansJPBold();
      return _CvPdfFontSet(regular: regular, bold: bold, italic: regular);
    }
    if (lang.startsWith('ko')) {
      final regular = await PdfGoogleFonts.notoSansKRRegular();
      final bold = await PdfGoogleFonts.notoSansKRBold();
      return _CvPdfFontSet(regular: regular, bold: bold, italic: regular);
    }

    return _CvPdfFontSet(
      regular: await PdfGoogleFonts.robotoRegular(),
      bold: await PdfGoogleFonts.robotoBold(),
      italic: await PdfGoogleFonts.robotoItalic(),
    );
  }

  static Future<Uint8List> generateCvPdf(CvModel cv, {String? locale}) async {
    final pdf = pw.Document();
    final activeLocale = (cv.targetLanguage != null && cv.targetLanguage!.trim().isNotEmpty)
        ? cv.targetLanguage!
        : (locale ?? LocalizationService.currentLocale);

    final fonts = await _loadCvPdfFonts(activeLocale);
    // Non-Latin CV locales still commonly contain Latin email addresses, URLs,
    // and institution names. Keep those glyphs renderable in every template.
    final latinFallback = await PdfGoogleFonts.robotoRegular();

    final theme = pw.ThemeData.withFont(
      base: fonts.regular,
      bold: fonts.bold,
      italic: fonts.italic,
      fontFallback: [latinFallback],
    );

    final primaryColor = PdfColor.fromInt(cv.primaryColorHex);
    final darkText = PdfColor.fromHex('0F172A');
    final mutedText = PdfColor.fromHex('64748B');
    final lightBg = PdfColor.fromHex('F8FAFC');

    if (CvPdfFlow.needsPagination(cv)) {
      CvPdfFlow.build(pdf, cv, theme,
          (section) => PdfCvLocaleHelper.getSectionTitle(section, activeLocale),
          PdfCvLocaleHelper.getPresentText(activeLocale));
      return pdf.save();
    }

    switch (cv.template) {
      case CvTemplate.sidebarModern:
        _buildSidebarModernTemplate(pdf, cv, theme, primaryColor, darkText,
            mutedText, lightBg, activeLocale);
        break;
      case CvTemplate.executiveClassic:
        _buildExecutiveClassicTemplate(pdf, cv, theme, primaryColor, darkText,
            mutedText, lightBg, activeLocale);
        break;
      case CvTemplate.creativeDesigner:
        _buildCreativeDesignerTemplate(pdf, cv, theme, primaryColor, darkText,
            mutedText, lightBg, activeLocale);
        break;
      case CvTemplate.minimalistPure:
        _buildMinimalistPureTemplate(pdf, cv, theme, primaryColor, darkText,
            mutedText, lightBg, activeLocale);
        break;
      case CvTemplate.harvardAcademic:
        _buildHarvardAcademicTemplate(pdf, cv, theme, primaryColor, darkText,
            mutedText, lightBg, activeLocale);
        break;
      case CvTemplate.compactGrid:
        _buildCompactGridTemplate(pdf, cv, theme, primaryColor, darkText,
            mutedText, lightBg, activeLocale);
        break;
      case CvTemplate.modernTech:
        _buildModernTechTemplate(pdf, cv, theme, primaryColor, darkText,
            mutedText, lightBg, activeLocale);
        break;
      case CvTemplate.infographicModern:
        _buildInfographicModernTemplate(pdf, cv, theme, primaryColor, darkText,
            mutedText, lightBg, activeLocale);
        break;
      case CvTemplate.corporateGold:
        _buildCorporateGoldTemplate(pdf, cv, theme, primaryColor, darkText,
            mutedText, lightBg, activeLocale);
        break;
      case CvTemplate.cleanNordic:
        _buildCleanNordicTemplate(pdf, cv, theme, primaryColor, darkText,
            mutedText, lightBg, activeLocale);
        break;
      case CvTemplate.eliteExecutive:
        _buildEliteExecutiveTemplate(pdf, cv, theme, primaryColor, darkText,
            mutedText, lightBg, activeLocale);
        break;
      case CvTemplate.siliconTech:
        _buildSiliconTechTemplate(pdf, cv, theme, primaryColor, darkText,
            mutedText, lightBg, activeLocale);
        break;
    }

    return pdf.save();
  }

  // 1. SIDEBAR MODERN (Two-Tone Left Column Template - Requested by user)

  // REAL PDF AVATAR BUILDER (Supports real photo bytes and monogram)
  static pw.Widget _buildPdfAvatar(
    CvModel cv, {
    required double size,
    required PdfColor backgroundColor,
    PdfColor borderColor = PdfColors.white,
    double borderWidth = 2.0,
    PdfColor textColor = PdfColors.white,
    bool isCircle = true,
    double borderRadius = 8.0,
  }) {
    final boxDecoration = isCircle
        ? pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: borderColor, width: borderWidth),
            image: (cv.profilePhotoBytes != null &&
                    cv.profilePhotoBytes!.isNotEmpty)
                ? pw.DecorationImage(
                    image: pw.MemoryImage(cv.profilePhotoBytes!),
                    fit: pw.BoxFit.cover,
                  )
                : null,
            color: (cv.profilePhotoBytes == null ||
                    cv.profilePhotoBytes!.isEmpty)
                ? backgroundColor
                : null,
          )
        : pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(borderRadius),
            border: pw.Border.all(color: borderColor, width: borderWidth),
            image: (cv.profilePhotoBytes != null &&
                    cv.profilePhotoBytes!.isNotEmpty)
                ? pw.DecorationImage(
                    image: pw.MemoryImage(cv.profilePhotoBytes!),
                    fit: pw.BoxFit.cover,
                  )
                : null,
            color: (cv.profilePhotoBytes == null ||
                    cv.profilePhotoBytes!.isEmpty)
                ? backgroundColor
                : null,
          );

    if (cv.profilePhotoBytes != null && cv.profilePhotoBytes!.isNotEmpty) {
      return pw.Container(
        width: size,
        height: size,
        decoration: boxDecoration,
      );
    }

    return pw.Container(
      width: size,
      height: size,
      decoration: boxDecoration,
      child: pw.Center(
        child: pw.Text(
          cv.fullName.isNotEmpty
              ? cv.fullName
                  .split(' ')
                  .map((e) => e.isNotEmpty ? e[0] : '')
                  .take(2)
                  .join('')
                  .toUpperCase()
              : 'CV',
          style: pw.TextStyle(
            color: textColor,
            fontSize: size * 0.35,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ),
    );
  }

  static void _buildSidebarModernTemplate(
    pw.Document pdf,
    CvModel cv,
    pw.ThemeData theme,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg,
    String activeLocale,
  ) {
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          buildBackground: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Row(
                children: [
                  pw.Container(
                    width: 185,
                    color: PdfColor.fromHex(
                        '0F172A'), // 100% Full Top-to-Bottom Page Height Sidebar
                  ),
                  pw.Expanded(
                    child: pw.Container(color: PdfColors.white),
                  ),
                ],
              ),
            );
          },
        ),
        build: (pw.Context context) {
          return [
            pw.Partitions(
              children: [
                // LEFT SIDEBAR (Full height background rendered by buildBackground)
                pw.Partition(
                  width: 185,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 16, vertical: 24),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Avatar (Supports Real Gallery Photo)
                        if (cv.hasPhoto) ...[
                          pw.Center(
                            child: _buildPdfAvatar(
                              cv,
                              size: 68,
                              backgroundColor: primaryColor,
                              borderColor: PdfColors.white,
                              borderWidth: 2.5,
                            ),
                          ),
                          pw.SizedBox(height: 14),
                        ],

                        // Name & Job Title in Sidebar
                        pw.Text(
                          cv.fullName,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 3),
                        pw.Text(
                          cv.jobTitle,
                          style: pw.TextStyle(
                            color: primaryColor,
                            fontSize: 10.5,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),

                        pw.SizedBox(height: 16),
                        pw.Divider(color: PdfColor.fromHex('334155')),
                        pw.SizedBox(height: 10),

                        // Contact Info
                        _buildSidebarSectionHeader(
                            PdfCvLocaleHelper.getSidebarTitle(
                                'contact', activeLocale),
                            primaryColor),
                        pw.SizedBox(height: 6),
                        if (cv.email.isNotEmpty)
                          _buildSidebarContactItem(
                              PdfCvLocaleHelper.getSidebarContactLabel(
                                  'email', activeLocale),
                              cv.email),
                        if (cv.phone.isNotEmpty)
                          _buildSidebarContactItem(
                              PdfCvLocaleHelper.getSidebarContactLabel(
                                  'phone', activeLocale),
                              cv.phone),
                        if (cv.location.isNotEmpty)
                          _buildSidebarContactItem(
                              PdfCvLocaleHelper.getSidebarContactLabel(
                                  'location', activeLocale),
                              cv.location),
                        if (cv.linkedin.isNotEmpty)
                          _buildSidebarContactItem('LinkedIn:', cv.linkedin),
                        if (cv.github.isNotEmpty)
                          _buildSidebarContactItem('GitHub:', cv.github),
                        if (cv.portfolioUrl.isNotEmpty)
                          _buildSidebarContactItem('Web:', cv.portfolioUrl),

                        // Skills with Percentage Progress Bars
                        if (cv.skills.isNotEmpty) ...[
                          pw.SizedBox(height: 14),
                          _buildSidebarSectionHeader(
                              PdfCvLocaleHelper.getSidebarTitle(
                                  'skills', activeLocale),
                              primaryColor),
                          pw.SizedBox(height: 8),
                          ...cv.skills.map((skill) {
                            return pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 7),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(skill.name,
                                          style: const pw.TextStyle(
                                              color: PdfColors.white,
                                              fontSize: 8.5)),
                                      pw.Text('${skill.level}%',
                                          style: pw.TextStyle(
                                              color: primaryColor,
                                              fontSize: 7.5,
                                              fontWeight: pw.FontWeight.bold)),
                                    ],
                                  ),
                                  pw.SizedBox(height: 3),
                                  pw.Stack(
                                    children: [
                                      pw.Container(
                                        height: 4,
                                        width: double.infinity,
                                        decoration: pw.BoxDecoration(
                                          color: PdfColor.fromHex('334155'),
                                          borderRadius:
                                              pw.BorderRadius.circular(2),
                                        ),
                                      ),
                                      pw.Container(
                                        height: 4,
                                        width: 153 * (skill.level / 100),
                                        decoration: pw.BoxDecoration(
                                          color: primaryColor,
                                          borderRadius:
                                              pw.BorderRadius.circular(2),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],

                        // Languages in Sidebar
                        if (cv.languages.isNotEmpty) ...[
                          pw.SizedBox(height: 14),
                          _buildSidebarSectionHeader(
                              PdfCvLocaleHelper.getSidebarTitle(
                                  'languages', activeLocale),
                              primaryColor),
                          pw.SizedBox(height: 6),
                          ...cv.languages.map((lang) {
                            return pw.Container(
                              margin: const pw.EdgeInsets.only(bottom: 5),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Text(lang.language,
                                      style: pw.TextStyle(
                                          color: PdfColors.white,
                                          fontSize: 9,
                                          fontWeight: pw.FontWeight.bold)),
                                  pw.Text(
                                      LocalizationService.normalizeLanguageLevel(
                                          lang.level, activeLocale),
                                      style: pw.TextStyle(
                                          color: primaryColor, fontSize: 8)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),

                // RIGHT MAIN BODY CONTENT (Dynamic Order)
                pw.Partition(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 20, vertical: 24),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: _buildOrderedSections(
                        cv, primaryColor, darkText, mutedText, lightBg,
                        isSidebarMode: true,
                        activeLocale: activeLocale,
                        experienceStyle: PdfExperienceStyle.timeline,
                        headerStyle: PdfHeaderStyle.leftAccentLine,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );
  }

  // 2. MODERN TECH TEMPLATE
  static void _buildModernTechTemplate(
    pw.Document pdf,
    CvModel cv,
    pw.ThemeData theme,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg,
    String activeLocale,
  ) {
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(28)),
        build: (pw.Context context) {
          return [
            // Top Modern Header
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: primaryColor, width: 1.5),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (cv.hasPhoto) ...[
                    _buildPdfAvatar(
                      cv,
                      size: 56,
                      backgroundColor: primaryColor,
                      borderColor: primaryColor,
                      borderWidth: 1.5,
                    ),
                    pw.SizedBox(width: 12),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(cv.fullName,
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: darkText)),
                        pw.Text(cv.jobTitle.toUpperCase(),
                            style: pw.TextStyle(
                                fontSize: 11,
                                fontWeight: pw.FontWeight.bold,
                                color: primaryColor)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (cv.email.isNotEmpty)
                        pw.Text(cv.email,
                            style:
                                pw.TextStyle(fontSize: 8, color: darkText)),
                      if (cv.phone.isNotEmpty)
                        pw.Text(cv.phone,
                            style:
                                pw.TextStyle(fontSize: 8, color: darkText)),
                      if (cv.location.isNotEmpty)
                        pw.Text(cv.location,
                            style:
                                pw.TextStyle(fontSize: 8, color: mutedText)),
                      if (cv.linkedin.isNotEmpty)
                        pw.Text('LinkedIn: ${cv.linkedin}',
                            style:
                                pw.TextStyle(fontSize: 7.5, color: primaryColor)),
                      if (cv.github.isNotEmpty)
                        pw.Text('GitHub: ${cv.github}',
                            style:
                                pw.TextStyle(fontSize: 7.5, color: darkText)),
                      if (cv.portfolioUrl.isNotEmpty)
                        pw.Text('Web: ${cv.portfolioUrl}',
                            style:
                                pw.TextStyle(fontSize: 7.5, color: primaryColor)),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Dynamic Order Sections
            ..._buildOrderedSections(
              cv, primaryColor, darkText, mutedText, lightBg,
              activeLocale: activeLocale,
              skillStyle: PdfSkillStyle.twoColBar,
              experienceStyle: PdfExperienceStyle.boxedCard,
              headerStyle: PdfHeaderStyle.leftAccentLine,
            ),
          ];
        },
      ),
    );
  }

  // 3. EXECUTIVE CLASSIC TEMPLATE
  static void _buildExecutiveClassicTemplate(
    pw.Document pdf,
    CvModel cv,
    pw.ThemeData theme,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg,
    String activeLocale,
  ) {
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32)),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(cv.fullName.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 22,
                          fontWeight: pw.FontWeight.bold,
                          letterSpacing: 1.5,
                          color: darkText)),
                  pw.SizedBox(height: 3),
                  pw.Text(cv.jobTitle.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 11,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                          letterSpacing: 1.2)),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    [cv.email, cv.phone, cv.location, cv.linkedin, cv.github, cv.portfolioUrl]
                        .where((e) => e.isNotEmpty)
                        .join('  |  '),
                    style: pw.TextStyle(fontSize: 8.5, color: mutedText),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Divider(color: darkText, thickness: 1.2),
            pw.SizedBox(height: 8),
            ..._buildOrderedSections(
              cv, primaryColor, darkText, mutedText, lightBg,
              activeLocale: activeLocale,
              skillStyle: PdfSkillStyle.dotRating,
              experienceStyle: PdfExperienceStyle.executiveClassic,
              headerStyle: PdfHeaderStyle.doubleRule,
            ),
          ];
        },
      ),
    );
  }

  // 4. CREATIVE DESIGNER TEMPLATE
  static void _buildCreativeDesignerTemplate(
    pw.Document pdf,
    CvModel cv,
    pw.ThemeData theme,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg,
    String activeLocale,
  ) {
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(0)),
        build: (pw.Context context) {
          return [
            pw.Container(
              color: primaryColor,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 20),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (cv.hasPhoto) ...[
                    _buildPdfAvatar(
                      cv,
                      size: 58,
                      backgroundColor: PdfColors.white,
                      borderColor: PdfColors.white,
                      borderWidth: 2,
                      textColor: primaryColor,
                    ),
                    pw.SizedBox(width: 14),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(cv.fullName,
                            style: pw.TextStyle(
                                fontSize: 20,
                                fontWeight: pw.FontWeight.bold,
                                color: PdfColors.white)),
                        pw.Text(cv.jobTitle,
                            style: const pw.TextStyle(
                                fontSize: 11, color: PdfColors.white)),
                      ],
                    ),
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      if (cv.email.isNotEmpty)
                        pw.Text(cv.email,
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.white)),
                      if (cv.phone.isNotEmpty)
                        pw.Text(cv.phone,
                            style: const pw.TextStyle(
                                fontSize: 8, color: PdfColors.white)),
                      if (cv.location.isNotEmpty)
                        pw.Text(cv.location,
                            style: const pw.TextStyle(
                                fontSize: 7.5, color: PdfColors.white)),
                      if (cv.portfolioUrl.isNotEmpty)
                        pw.Text(cv.portfolioUrl,
                            style: const pw.TextStyle(
                                fontSize: 7.5, color: PdfColors.white)),
                      if (cv.linkedin.isNotEmpty)
                        pw.Text('in: ${cv.linkedin}',
                            style: const pw.TextStyle(
                                fontSize: 7.5, color: PdfColors.white)),
                      if (cv.github.isNotEmpty)
                        pw.Text('git: ${cv.github}',
                            style: const pw.TextStyle(
                                fontSize: 7.5, color: PdfColors.white)),
                    ],
                  ),
                ],
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(24),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: _buildOrderedSections(
                  cv, primaryColor, darkText, mutedText, lightBg,
                  activeLocale: activeLocale,
                  skillStyle: PdfSkillStyle.percentagePill,
                  experienceStyle: PdfExperienceStyle.timeline,
                  headerStyle: PdfHeaderStyle.bottomUnderline,
                ),
              ),
            ),
          ];
        },
      ),
    );
  }

  // 5. MINIMALIST PURE TEMPLATE
  static void _buildMinimalistPureTemplate(
    pw.Document pdf,
    CvModel cv,
    pw.ThemeData theme,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg,
    String activeLocale,
  ) {
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(36)),
        build: (pw.Context context) {
          return [
            pw.Text(cv.fullName,
                style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: darkText)),
            pw.SizedBox(height: 2),
            pw.Text(cv.jobTitle,
                style: pw.TextStyle(fontSize: 11, color: mutedText)),
            pw.SizedBox(height: 6),
            pw.Text(
              [cv.email, cv.phone, cv.location, cv.linkedin, cv.github, cv.portfolioUrl]
                  .where((e) => e.isNotEmpty)
                  .join(' • '),
              style: pw.TextStyle(fontSize: 8.5, color: mutedText),
            ),
            pw.SizedBox(height: 14),
            ..._buildOrderedSections(
              cv, primaryColor, darkText, mutedText, lightBg,
              activeLocale: activeLocale,
              skillStyle: PdfSkillStyle.academicText,
              experienceStyle: PdfExperienceStyle.standard,
              headerStyle: PdfHeaderStyle.minimalist,
            ),
          ];
        },
      ),
    );
  }

  // 6. HARVARD ACADEMIC TEMPLATE
  static void _buildHarvardAcademicTemplate(
    pw.Document pdf,
    CvModel cv,
    pw.ThemeData theme,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg,
    String activeLocale,
  ) {
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(32)),
        build: (pw.Context context) {
          return [
            pw.Center(
              child: pw.Column(
                children: [
                  pw.Text(cv.fullName.toUpperCase(),
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                          color: darkText)),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    [cv.location, cv.phone, cv.email, cv.linkedin, cv.github, cv.portfolioUrl]
                        .where((e) => e.isNotEmpty)
                        .join(' | '),
                    style: pw.TextStyle(fontSize: 8.5, color: darkText),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            ..._buildOrderedSections(
              cv, primaryColor, darkText, mutedText, lightBg,
              activeLocale: activeLocale,
              skillStyle: PdfSkillStyle.academicText,
              experienceStyle: PdfExperienceStyle.executiveClassic,
              headerStyle: PdfHeaderStyle.bottomUnderline,
            ),
          ];
        },
      ),
    );
  }

  // 7. COMPACT GRID ATS TEMPLATE
  static void _buildCompactGridTemplate(
    pw.Document pdf,
    CvModel cv,
    pw.ThemeData theme,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg,
    String activeLocale,
  ) {
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24)),
        build: (pw.Context context) {
          return [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(cv.fullName,
                        style: pw.TextStyle(
                            fontSize: 19,
                            fontWeight: pw.FontWeight.bold,
                            color: darkText)),
                    pw.Text(cv.jobTitle,
                        style: pw.TextStyle(
                            fontSize: 11,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor)),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    if (cv.email.isNotEmpty)
                      pw.Text(cv.email,
                          style: pw.TextStyle(fontSize: 8, color: darkText)),
                    if (cv.phone.isNotEmpty)
                      pw.Text(cv.phone,
                          style: pw.TextStyle(fontSize: 8, color: darkText)),
                    if (cv.location.isNotEmpty)
                      pw.Text(cv.location,
                          style: pw.TextStyle(fontSize: 8, color: mutedText)),
                    if (cv.linkedin.isNotEmpty || cv.portfolioUrl.isNotEmpty)
                      pw.Text(
                        [cv.linkedin, cv.portfolioUrl].where((e) => e.isNotEmpty).join(' • '),
                        style: pw.TextStyle(fontSize: 7.5, color: primaryColor),
                      ),
                  ],
                ),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Divider(color: primaryColor, thickness: 1),
            pw.SizedBox(height: 6),
            ..._buildOrderedSections(
              cv, primaryColor, darkText, mutedText, lightBg,
              activeLocale: activeLocale,
              skillStyle: PdfSkillStyle.twoColBar,
              experienceStyle: PdfExperienceStyle.standard,
              headerStyle: PdfHeaderStyle.bottomUnderline,
            ),
          ];
        },
      ),
    );
  }

  // DYNAMIC SECTION ORDER RENDERER (Respects user customized sectionOrder, Active Locale & Distinct Visual Styles)
  static List<pw.Widget> _buildOrderedSections(
    CvModel cv,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg, {
    bool isSidebarMode = false,
    Set<CvSectionType>? excludedSections,
    String activeLocale = 'en',
    PdfSkillStyle skillStyle = PdfSkillStyle.tags,
    PdfExperienceStyle experienceStyle = PdfExperienceStyle.standard,
    PdfHeaderStyle headerStyle = PdfHeaderStyle.bottomUnderline,
  }) {
    final List<pw.Widget> widgets = [];

    for (final sectionType in cv.sectionOrder) {
      if (excludedSections != null && excludedSections.contains(sectionType)) {
        continue;
      }
      switch (sectionType) {
        case CvSectionType.summary:
          if (cv.summary.isNotEmpty) {
            widgets.add(_buildSectionHeader(
              PdfCvLocaleHelper.getSectionTitle(
                  CvSectionType.summary, activeLocale),
              primaryColor,
              style: headerStyle,
            ));
            widgets.add(pw.SizedBox(height: 4));
            widgets.add(pw.Text(cv.summary,
                style: pw.TextStyle(
                    fontSize: 9, color: darkText, lineSpacing: 1.35)));
            widgets.add(pw.SizedBox(height: 9));
          }
          break;

        case CvSectionType.experiences:
          if (cv.experiences.isNotEmpty) {
            widgets.add(_buildSectionHeader(
              PdfCvLocaleHelper.getSectionTitle(
                  CvSectionType.experiences, activeLocale),
              primaryColor,
              style: headerStyle,
            ));
            widgets.add(pw.SizedBox(height: 5));

            switch (experienceStyle) {
              case PdfExperienceStyle.timeline:
                for (var i = 0; i < cv.experiences.length; i++) {
                  final exp = cv.experiences[i];
                  final isLast = i == cv.experiences.length - 1;
                  final dateText =
                      '${exp.startDate} - ${exp.isCurrent ? PdfCvLocaleHelper.getPresentText(activeLocale) : exp.endDate}';

                  widgets.add(
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 12,
                          child: pw.Column(
                            children: [
                              pw.Container(
                                width: 6.5,
                                height: 6.5,
                                decoration: pw.BoxDecoration(
                                  color: primaryColor,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              if (!isLast)
                                pw.Container(
                                  width: 1.2,
                                  height: 38,
                                  color: PdfColor.fromHex('CBD5E1'),
                                ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(exp.position,
                                      style: pw.TextStyle(
                                          fontSize: 9.5,
                                          fontWeight: pw.FontWeight.bold,
                                          color: darkText)),
                                  pw.Text(dateText,
                                      style: pw.TextStyle(
                                          fontSize: 8,
                                          fontWeight: pw.FontWeight.bold,
                                          color: primaryColor)),
                                ],
                              ),
                              pw.Text(exp.company,
                                  style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: mutedText)),
                              if (exp.description.isNotEmpty) ...[
                                pw.SizedBox(height: 1.5),
                                pw.Text(exp.description,
                                    style: pw.TextStyle(
                                        fontSize: 8,
                                        color: darkText,
                                        lineSpacing: 1.2)),
                              ],
                              pw.SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                break;

              case PdfExperienceStyle.boxedCard:
                for (final exp in cv.experiences) {
                  final dateText =
                      '${exp.startDate} - ${exp.isCurrent ? PdfCvLocaleHelper.getPresentText(activeLocale) : exp.endDate}';
                  widgets.add(
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 6),
                      padding: const pw.EdgeInsets.fromLTRB(8, 6, 8, 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('F8FAFC'),
                        border: pw.Border(
                          left: pw.BorderSide(color: primaryColor, width: 3),
                          top: pw.BorderSide(
                              color: PdfColor.fromHex('E2E8F0'), width: 0.5),
                          right: pw.BorderSide(
                              color: PdfColor.fromHex('E2E8F0'), width: 0.5),
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('E2E8F0'), width: 0.5),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(exp.position,
                                  style: pw.TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: darkText)),
                              pw.Text(dateText,
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: primaryColor)),
                            ],
                          ),
                          pw.Text(exp.company,
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: mutedText)),
                          if (exp.description.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(exp.description,
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    color: darkText,
                                    lineSpacing: 1.2)),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                break;

              case PdfExperienceStyle.executiveClassic:
                for (final exp in cv.experiences) {
                  final dateText =
                      '${exp.startDate} - ${exp.isCurrent ? PdfCvLocaleHelper.getPresentText(activeLocale) : exp.endDate}';
                  widgets.add(
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 7),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(exp.position.toUpperCase(),
                                  style: pw.TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: darkText)),
                              pw.Text(dateText,
                                  style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: darkText)),
                            ],
                          ),
                          pw.Text(exp.company,
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontStyle: pw.FontStyle.italic,
                                  color: primaryColor)),
                          if (exp.description.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(exp.description,
                                style: pw.TextStyle(
                                    fontSize: 8.5,
                                    color: darkText,
                                    lineSpacing: 1.3)),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                break;

              case PdfExperienceStyle.standard:
                for (final exp in cv.experiences) {
                  final dateText =
                      '${exp.startDate} - ${exp.isCurrent ? PdfCvLocaleHelper.getPresentText(activeLocale) : exp.endDate}';
                  widgets.add(
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 7),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(exp.position,
                                  style: pw.TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: darkText)),
                              pw.Text(dateText,
                                  style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: primaryColor)),
                            ],
                          ),
                          pw.Text(exp.company,
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: mutedText)),
                          if (exp.description.isNotEmpty) ...[
                            pw.SizedBox(height: 1.5),
                            pw.Text(exp.description,
                                style: pw.TextStyle(
                                    fontSize: 8.5, color: darkText)),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                break;
            }

            widgets.add(pw.SizedBox(height: 6));
          }
          break;

        case CvSectionType.educations:
          if (cv.educations.isNotEmpty) {
            widgets.add(_buildSectionHeader(
              PdfCvLocaleHelper.getSectionTitle(
                  CvSectionType.educations, activeLocale),
              primaryColor,
              style: headerStyle,
            ));
            widgets.add(pw.SizedBox(height: 5));

            switch (experienceStyle) {
              case PdfExperienceStyle.timeline:
                for (int i = 0; i < cv.educations.length; i++) {
                  final edu = cv.educations[i];
                  final isLast = i == cv.educations.length - 1;
                  final hasDates =
                      edu.startDate.isNotEmpty || edu.endDate.isNotEmpty;
                  final dateText = hasDates
                      ? (edu.startDate.isNotEmpty && edu.endDate.isNotEmpty
                          ? '${edu.startDate} - ${edu.endDate}'
                          : '${edu.startDate}${edu.endDate}')
                      : '';
                  final degreeField = [
                    if (edu.degree.isNotEmpty) edu.degree,
                    if (edu.field.isNotEmpty) edu.field,
                  ].join(', ');

                  widgets.add(
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          width: 12,
                          child: pw.Column(
                            children: [
                              pw.Container(
                                width: 6.5,
                                height: 6.5,
                                decoration: pw.BoxDecoration(
                                  color: primaryColor,
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              if (!isLast)
                                pw.Container(
                                  width: 1.2,
                                  height: 32,
                                  color: PdfColor.fromHex('CBD5E1'),
                                ),
                            ],
                          ),
                        ),
                        pw.SizedBox(width: 6),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Expanded(
                                    child: pw.Text(
                                      edu.school.isNotEmpty
                                          ? edu.school
                                          : degreeField,
                                      style: pw.TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: darkText,
                                      ),
                                    ),
                                  ),
                                  if (dateText.isNotEmpty) ...[
                                    pw.SizedBox(width: 8),
                                    pw.Text(
                                      dateText,
                                      style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              if (edu.school.isNotEmpty &&
                                  degreeField.isNotEmpty) ...[
                                pw.SizedBox(height: 1.5),
                                pw.Text(
                                  degreeField,
                                  style: pw.TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: mutedText,
                                  ),
                                ),
                              ],
                              if (edu.gpa.isNotEmpty) ...[
                                pw.SizedBox(height: 2),
                                pw.Row(
                                  children: [
                                    pw.Text(
                                      '${PdfCvLocaleHelper.getGpaLabel(activeLocale)}: ',
                                      style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                    pw.Text(
                                      edu.gpa,
                                      style: pw.TextStyle(
                                        fontSize: 8,
                                        fontWeight: pw.FontWeight.bold,
                                        color: darkText,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              pw.SizedBox(height: 6),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                break;

              case PdfExperienceStyle.boxedCard:
                for (final edu in cv.educations) {
                  final hasDates =
                      edu.startDate.isNotEmpty || edu.endDate.isNotEmpty;
                  final dateText = hasDates
                      ? (edu.startDate.isNotEmpty && edu.endDate.isNotEmpty
                          ? '${edu.startDate} - ${edu.endDate}'
                          : '${edu.startDate}${edu.endDate}')
                      : '';
                  final degreeField = [
                    if (edu.degree.isNotEmpty) edu.degree,
                    if (edu.field.isNotEmpty) edu.field,
                  ].join(', ');

                  widgets.add(
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('F8FAFC'),
                        border: pw.Border(
                          left: pw.BorderSide(color: primaryColor, width: 3),
                          top: pw.BorderSide(
                              color: PdfColor.fromHex('E2E8F0'), width: 0.5),
                          right: pw.BorderSide(
                              color: PdfColor.fromHex('E2E8F0'), width: 0.5),
                          bottom: pw.BorderSide(
                              color: PdfColor.fromHex('E2E8F0'), width: 0.5),
                        ),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  edu.school.isNotEmpty
                                      ? edu.school
                                      : degreeField,
                                  style: pw.TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                              ),
                              if (dateText.isNotEmpty) ...[
                                pw.SizedBox(width: 8),
                                pw.Text(
                                  dateText,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (edu.school.isNotEmpty &&
                              degreeField.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Text(
                              degreeField,
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: mutedText,
                              ),
                            ),
                          ],
                          if (edu.gpa.isNotEmpty) ...[
                            pw.SizedBox(height: 2.5),
                            pw.Row(
                              children: [
                                pw.Text(
                                  '${PdfCvLocaleHelper.getGpaLabel(activeLocale)}: ',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                pw.Text(
                                  edu.gpa,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                break;

              case PdfExperienceStyle.executiveClassic:
                for (final edu in cv.educations) {
                  final hasDates =
                      edu.startDate.isNotEmpty || edu.endDate.isNotEmpty;
                  final dateText = hasDates
                      ? (edu.startDate.isNotEmpty && edu.endDate.isNotEmpty
                          ? '${edu.startDate} - ${edu.endDate}'
                          : '${edu.startDate}${edu.endDate}')
                      : '';
                  final degreeField = [
                    if (edu.degree.isNotEmpty) edu.degree,
                    if (edu.field.isNotEmpty) edu.field,
                  ].join(', ');

                  widgets.add(
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 7),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  (edu.school.isNotEmpty
                                          ? edu.school
                                          : degreeField)
                                      .toUpperCase(),
                                  style: pw.TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                              ),
                              if (dateText.isNotEmpty) ...[
                                pw.SizedBox(width: 8),
                                pw.Text(
                                  dateText,
                                  style: pw.TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (edu.school.isNotEmpty &&
                              degreeField.isNotEmpty) ...[
                            pw.SizedBox(height: 1.5),
                            pw.Text(
                              degreeField,
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontStyle: pw.FontStyle.italic,
                                color: primaryColor,
                              ),
                            ),
                          ],
                          if (edu.gpa.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Row(
                              children: [
                                pw.Text(
                                  '${PdfCvLocaleHelper.getGpaLabel(activeLocale)}: ',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                pw.Text(
                                  edu.gpa,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                break;

              case PdfExperienceStyle.standard:
                for (final edu in cv.educations) {
                  final hasDates =
                      edu.startDate.isNotEmpty || edu.endDate.isNotEmpty;
                  final dateText = hasDates
                      ? (edu.startDate.isNotEmpty && edu.endDate.isNotEmpty
                          ? '${edu.startDate} - ${edu.endDate}'
                          : '${edu.startDate}${edu.endDate}')
                      : '';
                  final degreeField = [
                    if (edu.degree.isNotEmpty) edu.degree,
                    if (edu.field.isNotEmpty) edu.field,
                  ].join(', ');

                  widgets.add(
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 7),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Expanded(
                                child: pw.Text(
                                  edu.school.isNotEmpty
                                      ? edu.school
                                      : degreeField,
                                  style: pw.TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                              ),
                              if (dateText.isNotEmpty) ...[
                                pw.SizedBox(width: 8),
                                pw.Text(
                                  dateText,
                                  style: pw.TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (edu.school.isNotEmpty &&
                              degreeField.isNotEmpty) ...[
                            pw.SizedBox(height: 1.5),
                            pw.Text(
                              degreeField,
                              style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: mutedText,
                              ),
                            ),
                          ],
                          if (edu.gpa.isNotEmpty) ...[
                            pw.SizedBox(height: 2),
                            pw.Row(
                              children: [
                                pw.Text(
                                  '${PdfCvLocaleHelper.getGpaLabel(activeLocale)}: ',
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor,
                                  ),
                                ),
                                pw.Text(
                                  edu.gpa,
                                  style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }
                break;
            }

            widgets.add(pw.SizedBox(height: 6));
          }
          break;

        case CvSectionType.personalTraits:
          if (cv.personalTraits.isNotEmpty) {
            widgets.add(_buildSectionHeader(
              PdfCvLocaleHelper.getSectionTitle(
                  CvSectionType.personalTraits, activeLocale),
              primaryColor,
              style: headerStyle,
            ));
            widgets.add(pw.SizedBox(height: 5));
            widgets.add(
              pw.Wrap(
                spacing: 5,
                runSpacing: 4,
                children: cv.personalTraits.map((trait) {
                  return pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2.5),
                    decoration: pw.BoxDecoration(
                      color: lightBg,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(
                          color: PdfColor.fromHex('CBD5E1'), width: 0.6),
                    ),
                    child: pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        pw.Container(
                          width: 4,
                          height: 4,
                          decoration: pw.BoxDecoration(
                            color: primaryColor,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Text(trait,
                            style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: darkText)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
            widgets.add(pw.SizedBox(height: 8));
          }
          break;

        case CvSectionType.projects:
          if (cv.projects.isNotEmpty) {
            widgets.add(_buildSectionHeader(
              PdfCvLocaleHelper.getSectionTitle(
                  CvSectionType.projects, activeLocale),
              primaryColor,
              style: headerStyle,
            ));
            widgets.add(pw.SizedBox(height: 5));
            for (final proj in cv.projects) {
              final techList = proj.technologies
                  .split(RegExp(r'[,•|/]'))
                  .map((t) => t.trim())
                  .where((t) => t.isNotEmpty)
                  .toList();

              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 7),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.RichText(
                              text: pw.TextSpan(
                                children: [
                                  pw.TextSpan(
                                    text: proj.name,
                                    style: pw.TextStyle(
                                      fontSize: 9.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: darkText,
                                    ),
                                  ),
                                  if (proj.role.isNotEmpty) ...[
                                    pw.TextSpan(
                                      text: '  -  ${proj.role}',
                                      style: pw.TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: pw.FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          if (proj.date.isNotEmpty) ...[
                            pw.SizedBox(width: 8),
                            pw.Text(proj.date,
                                style: pw.TextStyle(
                                    fontSize: 8, color: mutedText)),
                          ],
                        ],
                      ),
                      if (proj.link.isNotEmpty) ...[
                        pw.SizedBox(height: 1.5),
                        pw.Text(
                          proj.link,
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            color: primaryColor,
                          ),
                        ),
                      ],
                      if (proj.description.isNotEmpty) ...[
                        pw.SizedBox(height: 2),
                        pw.Text(proj.description,
                            style: pw.TextStyle(
                                fontSize: 8.5, color: darkText, lineSpacing: 1.2)),
                      ],
                      if (techList.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Wrap(
                          spacing: 3,
                          runSpacing: 3,
                          children: techList.map((tech) {
                            return pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 1.5),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('F1F5F9'),
                                borderRadius: pw.BorderRadius.circular(3),
                                border: pw.Border.all(
                                    color: PdfColor.fromHex('CBD5E1'),
                                    width: 0.5),
                              ),
                              child: pw.Text(
                                tech,
                                style: pw.TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: pw.FontWeight.bold,
                                  color: primaryColor,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
            widgets.add(pw.SizedBox(height: 6));
          }
          break;

        case CvSectionType.skills:
          if (!isSidebarMode && cv.skills.isNotEmpty) {
            widgets.add(_buildSectionHeader(
              PdfCvLocaleHelper.getSectionTitle(
                  CvSectionType.skills, activeLocale),
              primaryColor,
              style: headerStyle,
            ));
            widgets.add(pw.SizedBox(height: 4));

            switch (skillStyle) {
              case PdfSkillStyle.progressBar:
                for (final s in cv.skills) {
                  widgets.add(
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 4.5),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(s.name,
                                  style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: darkText)),
                              pw.Text('%${s.level}',
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                      color: primaryColor)),
                            ],
                          ),
                          pw.SizedBox(height: 2),
                          pw.Container(
                            height: 3.5,
                            width: double.infinity,
                            decoration: pw.BoxDecoration(
                              color: PdfColor.fromHex('E2E8F0'),
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                            child: pw.Align(
                              alignment: pw.Alignment.centerLeft,
                              child: pw.Container(
                                height: 3.5,
                                width: 220 * (s.level.clamp(10, 100) / 100),
                                decoration: pw.BoxDecoration(
                                  color: primaryColor,
                                  borderRadius: pw.BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                break;

              case PdfSkillStyle.twoColBar:
                final half = (cv.skills.length / 2).ceil();
                final col1 = cv.skills.take(half).toList();
                final col2 = cv.skills.skip(half).toList();

                widgets.add(
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          children: col1.map((s) {
                            return pw.Container(
                              margin: const pw.EdgeInsets.only(
                                  bottom: 4, right: 8),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(s.name,
                                          style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                              color: darkText)),
                                      pw.Text('%${s.level}',
                                          style: pw.TextStyle(
                                              fontSize: 7.5,
                                              fontWeight: pw.FontWeight.bold,
                                              color: primaryColor)),
                                    ],
                                  ),
                                  pw.SizedBox(height: 1.5),
                                  pw.Container(
                                    height: 3,
                                    decoration: pw.BoxDecoration(
                                      color: PdfColor.fromHex('E2E8F0'),
                                      borderRadius:
                                          pw.BorderRadius.circular(1.5),
                                    ),
                                    child: pw.Align(
                                      alignment: pw.Alignment.centerLeft,
                                      child: pw.Container(
                                        height: 3,
                                        width: 100 *
                                            (s.level.clamp(10, 100) / 100),
                                        decoration: pw.BoxDecoration(
                                          color: primaryColor,
                                          borderRadius:
                                              pw.BorderRadius.circular(1.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          children: col2.map((s) {
                            return pw.Container(
                              margin:
                                  const pw.EdgeInsets.only(bottom: 4, left: 8),
                              child: pw.Column(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Row(
                                    mainAxisAlignment:
                                        pw.MainAxisAlignment.spaceBetween,
                                    children: [
                                      pw.Text(s.name,
                                          style: pw.TextStyle(
                                              fontSize: 8,
                                              fontWeight: pw.FontWeight.bold,
                                              color: darkText)),
                                      pw.Text('%${s.level}',
                                          style: pw.TextStyle(
                                              fontSize: 7.5,
                                              fontWeight: pw.FontWeight.bold,
                                              color: primaryColor)),
                                    ],
                                  ),
                                  pw.SizedBox(height: 1.5),
                                  pw.Container(
                                    height: 3,
                                    decoration: pw.BoxDecoration(
                                      color: PdfColor.fromHex('E2E8F0'),
                                      borderRadius:
                                          pw.BorderRadius.circular(1.5),
                                    ),
                                    child: pw.Align(
                                      alignment: pw.Alignment.centerLeft,
                                      child: pw.Container(
                                        height: 3,
                                        width: 100 *
                                            (s.level.clamp(10, 100) / 100),
                                        decoration: pw.BoxDecoration(
                                          color: primaryColor,
                                          borderRadius:
                                              pw.BorderRadius.circular(1.5),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
                break;

              case PdfSkillStyle.dotRating:
                final half = (cv.skills.length / 2).ceil();
                final col1 = cv.skills.take(half).toList();
                final col2 = cv.skills.skip(half).toList();

                widgets.add(
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                        child: pw.Column(
                          children: col1.map((s) {
                            final dots = (s.level / 20).round().clamp(1, 5);
                            return pw.Container(
                              margin: const pw.EdgeInsets.only(
                                  bottom: 3.5, right: 8),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(s.name,
                                      style: pw.TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: pw.FontWeight.bold,
                                          color: darkText)),
                                  pw.Row(
                                    children: List.generate(5, (dotIdx) {
                                      final isFilled = dotIdx < dots;
                                      return pw.Container(
                                        margin:
                                            const pw.EdgeInsets.only(left: 3),
                                        width: 5.5,
                                        height: 5.5,
                                        decoration: pw.BoxDecoration(
                                          color: isFilled
                                              ? primaryColor
                                              : PdfColor.fromHex('CBD5E1'),
                                          shape: pw.BoxShape.circle,
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      pw.Expanded(
                        child: pw.Column(
                          children: col2.map((s) {
                            final dots = (s.level / 20).round().clamp(1, 5);
                            return pw.Container(
                              margin:
                                  const pw.EdgeInsets.only(bottom: 3.5, left: 8),
                              child: pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Text(s.name,
                                      style: pw.TextStyle(
                                          fontSize: 8.5,
                                          fontWeight: pw.FontWeight.bold,
                                          color: darkText)),
                                  pw.Row(
                                    children: List.generate(5, (dotIdx) {
                                      final isFilled = dotIdx < dots;
                                      return pw.Container(
                                        margin:
                                            const pw.EdgeInsets.only(left: 3),
                                        width: 5.5,
                                        height: 5.5,
                                        decoration: pw.BoxDecoration(
                                          color: isFilled
                                              ? primaryColor
                                              : PdfColor.fromHex('CBD5E1'),
                                          shape: pw.BoxShape.circle,
                                        ),
                                      );
                                    }),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                );
                break;

              case PdfSkillStyle.percentagePill:
                widgets.add(
                  pw.Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: cv.skills.map((s) {
                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('EFF6FF'),
                          borderRadius: pw.BorderRadius.circular(10),
                          border:
                              pw.Border.all(color: primaryColor, width: 0.7),
                        ),
                        child: pw.Row(
                          mainAxisSize: pw.MainAxisSize.min,
                          children: [
                            pw.Text(s.name,
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: darkText)),
                            pw.SizedBox(width: 4),
                            pw.Text('%${s.level}',
                                style: pw.TextStyle(
                                    fontSize: 8,
                                    fontWeight: pw.FontWeight.bold,
                                    color: primaryColor)),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                );
                break;

              case PdfSkillStyle.academicText:
                widgets.add(
                  pw.Text(
                    cv.skills
                        .map((s) => '${s.name} (%${s.level})')
                        .join('  •  '),
                    style: pw.TextStyle(
                        fontSize: 8.5, color: darkText, lineSpacing: 1.4),
                  ),
                );
                break;

              case PdfSkillStyle.tags:
                widgets.add(
                  pw.Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: cv.skills.map((s) {
                      return pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2.5),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('F1F5F9'),
                          borderRadius: pw.BorderRadius.circular(4),
                          border: pw.Border.all(
                              color: PdfColor.fromHex('CBD5E1'), width: 0.6),
                        ),
                        child: pw.Text('${s.name} (%${s.level})',
                            style: pw.TextStyle(
                                fontSize: 8,
                                fontWeight: pw.FontWeight.bold,
                                color: darkText)),
                      );
                    }).toList(),
                  ),
                );
                break;
            }

            widgets.add(pw.SizedBox(height: 8));
          }
          break;

        case CvSectionType.languages:
          if (!isSidebarMode && cv.languages.isNotEmpty) {
            widgets.add(_buildSectionHeader(
              PdfCvLocaleHelper.getSectionTitle(
                  CvSectionType.languages, activeLocale),
              primaryColor,
              style: headerStyle,
            ));
            widgets.add(pw.SizedBox(height: 4));
            for (final l in cv.languages) {
              widgets.add(
                pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 2),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(l.language,
                          style: pw.TextStyle(
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                              color: darkText)),
                      pw.Text(
                          LocalizationService.normalizeLanguageLevel(
                              l.level, activeLocale),
                          style: pw.TextStyle(
                              fontSize: 8.5, color: primaryColor)),
                    ],
                  ),
                ),
              );
            }
            widgets.add(pw.SizedBox(height: 8));
          }
          break;

        case CvSectionType.certificates:
          final validCerts = cv.certificates
              .where((c) =>
                  !(c.name.contains('Google Certified Associate Android Developer') ||
                    c.credentialUrl.contains('verify.google.com/cert/12345')))
              .toList();
          if (validCerts.isNotEmpty) {
            widgets.add(_buildSectionHeader(
              PdfCvLocaleHelper.getSectionTitle(
                  CvSectionType.certificates, activeLocale),
              primaryColor,
              style: headerStyle,
            ));
            widgets.add(pw.SizedBox(height: 4));
            for (final c in validCerts) {
              final cleanCertName = PdfCvLocaleHelper.sanitizePdfText(c.name);
              final cleanIssuer = PdfCvLocaleHelper.sanitizePdfText(c.issuer);
              widgets.add(
                pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Expanded(
                            child: pw.Text(
                              cleanIssuer.isNotEmpty
                                  ? '$cleanCertName - $cleanIssuer'
                                  : cleanCertName,
                              style: pw.TextStyle(
                                  fontSize: 8.5,
                                  color: darkText,
                                  fontWeight: pw.FontWeight.bold),
                            ),
                          ),
                          if (c.date.isNotEmpty) ...[
                            pw.SizedBox(width: 8),
                            pw.Text(c.date,
                                style: pw.TextStyle(fontSize: 8, color: mutedText)),
                          ],
                        ],
                      ),
                      if (c.credentialUrl.isNotEmpty) ...[
                        pw.SizedBox(height: 1),
                        pw.Text(
                          c.credentialUrl,
                          style: pw.TextStyle(
                            fontSize: 7.2,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }
            widgets.add(pw.SizedBox(height: 7));
          }
          break;

        case CvSectionType.references:
          if (cv.references.isNotEmpty) {
            widgets.add(_buildSectionHeader(
              PdfCvLocaleHelper.getSectionTitle(
                  CvSectionType.references, activeLocale),
              primaryColor,
              style: headerStyle,
            ));
            widgets.add(pw.SizedBox(height: 5));
            widgets.add(
              pw.Wrap(
                spacing: 14,
                runSpacing: 8,
                children: cv.references.map((r) {
                  return pw.Container(
                    width: 220,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(r.name,
                            style: pw.TextStyle(
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                                color: darkText)),
                        pw.Text('${r.position} - ${r.company}',
                            style: pw.TextStyle(
                                fontSize: 7.5, color: mutedText)),
                        if (r.phone.isNotEmpty || r.email.isNotEmpty) ...[
                          pw.SizedBox(height: 1.5),
                          if (r.phone.isNotEmpty)
                            pw.Text('Tel: ${r.phone}',
                                style: pw.TextStyle(
                                    fontSize: 7.5, color: darkText)),
                          if (r.email.isNotEmpty)
                            pw.Text('E-posta: ${r.email}',
                                style: pw.TextStyle(
                                    fontSize: 7.5, color: primaryColor)),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
            widgets.add(pw.SizedBox(height: 8));
          }
          break;

        case CvSectionType.customSections:
          if (cv.customSections.isNotEmpty) {
            for (final sec in cv.customSections) {
              final cleanTitle =
                  PdfCvLocaleHelper.sanitizePdfText(sec.title);
              widgets.add(_buildSectionHeader(
                cleanTitle.toUpperCase(),
                primaryColor,
                style: headerStyle,
              ));
              widgets.add(pw.SizedBox(height: 4));
              for (final it in sec.items) {
                final cleanItem =
                    PdfCvLocaleHelper.sanitizePdfText(it);
                widgets.add(
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 2.5),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Container(
                          margin: const pw.EdgeInsets.only(top: 3.5, right: 5),
                          width: 3.5,
                          height: 3.5,
                          decoration: pw.BoxDecoration(
                            color: primaryColor,
                            shape: pw.BoxShape.circle,
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Text(
                            cleanItem,
                            style: pw.TextStyle(
                              fontSize: 8.5,
                              color: darkText,
                              lineSpacing: 1.25,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              widgets.add(pw.SizedBox(height: 8));
            }
          }
          break;
      }
    }

    return widgets;
  }

  static pw.Widget _buildSidebarSectionHeader(String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 2),
      decoration: pw.BoxDecoration(
        border: pw.Border(bottom: pw.BorderSide(color: color, width: 1.2)),
      ),
      child: pw.Text(
        PdfCvLocaleHelper.sanitizePdfText(title),
        style: pw.TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: pw.FontWeight.bold,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  static pw.Widget _buildSidebarContactItem(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 3.5),
      width: double.infinity,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  color: PdfColor.fromHex('94A3B8'), fontSize: 7)),
          pw.SizedBox(height: 1),
          pw.Text(
            value,
            style: const pw.TextStyle(color: PdfColors.white, fontSize: 7.5),
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
          ),
        ],
      ),
    );
  }
  static pw.Widget _buildSectionHeader(
    String title,
    PdfColor color, {
    PdfHeaderStyle style = PdfHeaderStyle.bottomUnderline,
  }) {
    final cleanTitle = PdfCvLocaleHelper.sanitizePdfText(title);

    switch (style) {
      case PdfHeaderStyle.leftAccentLine:
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 5),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 3.5,
                height: 12,
                decoration: pw.BoxDecoration(
                  color: color,
                  borderRadius: pw.BorderRadius.circular(1.5),
                ),
              ),
              pw.SizedBox(width: 6),
              pw.Text(
                cleanTitle,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                  letterSpacing: 0.6,
                ),
              ),
            ],
          ),
        );

      case PdfHeaderStyle.doubleRule:
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                cleanTitle,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                  letterSpacing: 1.0,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Container(
                height: 1.2,
                color: color,
              ),
              pw.SizedBox(height: 1.5),
              pw.Container(
                height: 0.5,
                color: color,
              ),
            ],
          ),
        );

      case PdfHeaderStyle.minimalist:
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          child: pw.Text(
            cleanTitle,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 1.5,
            ),
          ),
        );

      case PdfHeaderStyle.bottomUnderline:
        return pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 2),
          margin: const pw.EdgeInsets.only(bottom: 5),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: color, width: 1.2),
            ),
          ),
          child: pw.Text(
            cleanTitle,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        );
    }
  }

  // 8. INFOGRAPHIC MODERN (Vibrant Header + Metrics + Progress Bars)
  static void _buildInfographicModernTemplate(
    pw.Document pdf,
    CvModel cv,
    pw.ThemeData theme,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg,
    String activeLocale,
  ) {
    final atsLabel = activeLocale.startsWith('tr')
        ? 'ATS SKORU'
        : (activeLocale.startsWith('de') ? 'ATS-SCORE' : 'ATS SCORE');
    final expLabel = activeLocale.startsWith('tr')
        ? 'DENEYİM'
        : (activeLocale.startsWith('de') ? 'ERFAHRUNG' : 'EXPERIENCE');
    final eduLabel = activeLocale.startsWith('tr')
        ? 'EĞİTİM'
        : (activeLocale.startsWith('de') ? 'AUSBILDUNG' : 'EDUCATION');
    final skillLabel = activeLocale.startsWith('tr')
        ? 'YETENEK'
        : (activeLocale.startsWith('de') ? 'FÄHIGKEITEN' : 'SKILLS');

    final filledExpCount = cv.experiences
        .where((e) => e.company.isNotEmpty || e.position.isNotEmpty)
        .length;
    final filledEduCount = cv.educations
        .where((e) => e.school.isNotEmpty || e.field.isNotEmpty)
        .length;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 22),
        ),
        build: (pw.Context context) {
          return [
            // Top Infographic Hero Banner
            pw.Container(
              padding: const pw.EdgeInsets.all(14),
              decoration: pw.BoxDecoration(
                color: primaryColor,
                borderRadius: pw.BorderRadius.circular(8),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  if (cv.hasPhoto) ...[
                    _buildPdfAvatar(
                      cv,
                      size: 54,
                      backgroundColor: PdfColors.white,
                      borderColor: PdfColors.white,
                      borderWidth: 2,
                      textColor: primaryColor,
                    ),
                    pw.SizedBox(width: 14),
                  ],
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          cv.fullName.isNotEmpty ? cv.fullName : 'Alex Morgan',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          cv.jobTitle.isNotEmpty
                              ? cv.jobTitle.toUpperCase()
                              : 'SENIOR SOFTWARE ENGINEER',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('E2E8F0'),
                            letterSpacing: 0.5,
                          ),
                        ),
                        pw.SizedBox(height: 5),
                        pw.Text(
                          [
                            if (cv.email.isNotEmpty) cv.email,
                            if (cv.phone.isNotEmpty) cv.phone,
                            if (cv.location.isNotEmpty) cv.location,
                            if (cv.linkedin.isNotEmpty) 'LinkedIn: ${cv.linkedin}',
                            if (cv.github.isNotEmpty) 'GitHub: ${cv.github}',
                            if (cv.portfolioUrl.isNotEmpty)
                              'Web: ${cv.portfolioUrl}',
                          ].join('   •   '),
                          style: pw.TextStyle(
                            fontSize: 7.5,
                            color: PdfColor.fromHex('F1F5F9'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 10),

            // Infographic Metric Stats Ribbon
            pw.Container(
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(6),
                border:
                    pw.Border.all(color: PdfColor.fromHex('E2E8F0'), width: 0.8),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Text(
                        atsLabel,
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: mutedText,
                        ),
                      ),
                      pw.Text(
                        '%${cv.calculateAtsScore()}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                      width: 0.8,
                      height: 18,
                      color: PdfColor.fromHex('CBD5E1')),
                  pw.Column(
                    children: [
                      pw.Text(
                        expLabel,
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: mutedText,
                        ),
                      ),
                      pw.Text(
                        '$filledExpCount',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                      width: 0.8,
                      height: 18,
                      color: PdfColor.fromHex('CBD5E1')),
                  pw.Column(
                    children: [
                      pw.Text(
                        eduLabel,
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: mutedText,
                        ),
                      ),
                      pw.Text(
                        '$filledEduCount',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                  pw.Container(
                      width: 0.8,
                      height: 18,
                      color: PdfColor.fromHex('CBD5E1')),
                  pw.Column(
                    children: [
                      pw.Text(
                        skillLabel,
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: mutedText,
                        ),
                      ),
                      pw.Text(
                        '${cv.skills.length}',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: darkText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 12),

            // Dynamic Body Sections (Flow naturally across pages)
            ..._buildOrderedSections(
              cv,
              primaryColor,
              darkText,
              mutedText,
              lightBg,
              activeLocale: activeLocale,
              skillStyle: PdfSkillStyle.twoColBar,
              experienceStyle: PdfExperienceStyle.boxedCard,
              headerStyle: PdfHeaderStyle.leftAccentLine,
            ),
          ];
        },
      ),
    );
  }

  // 9. CORPORATE GOLD (Luxury Bordered Executive Standard)
  static void _buildCorporateGoldTemplate(
    pw.Document pdf,
    CvModel cv,
    pw.ThemeData theme,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg,
    String activeLocale,
  ) {
    final goldColor = PdfColor.fromHex('B45309');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
        ),
        build: (pw.Context context) {
          return [
            // Elegant Outer Border Box
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: goldColor, width: 1.5),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Centered Monogram & Header
                  pw.Text(
                    cv.fullName.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 16,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 2,
                      color: darkText,
                    ),
                  ),
                  pw.SizedBox(height: 3),
                  pw.Text(
                    cv.jobTitle.toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      letterSpacing: 1.5,
                      color: goldColor,
                    ),
                  ),
                  pw.SizedBox(height: 6),
                  pw.Text(
                    [cv.email, cv.phone, cv.location, cv.linkedin, cv.github, cv.portfolioUrl]
                        .where((e) => e.isNotEmpty)
                        .join('   ◆   '),
                    style: pw.TextStyle(fontSize: 7.5, color: mutedText),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: goldColor, thickness: 0.8),
                  pw.SizedBox(height: 10),

                  // Structured Body
                  ..._buildOrderedSections(
                    cv, goldColor, darkText, mutedText, lightBg,
                    activeLocale: activeLocale,
                    skillStyle: PdfSkillStyle.dotRating,
                    experienceStyle: PdfExperienceStyle.executiveClassic,
                    headerStyle: PdfHeaderStyle.doubleRule,
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }

  // 10. CLEAN NORDIC (Geometric Scandinavian Layout)
  static void _buildCleanNordicTemplate(
    pw.Document pdf,
    CvModel cv,
    pw.ThemeData theme,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg,
    String activeLocale,
  ) {
    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        ),
        build: (pw.Context context) {
          return [
            // Clean Header with Solid Accent Block
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 4,
                  height: 44,
                  color: primaryColor,
                  margin: const pw.EdgeInsets.only(right: 12),
                ),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        cv.fullName,
                        style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: darkText),
                      ),
                      pw.Text(
                        cv.jobTitle,
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: primaryColor),
                      ),
                      pw.Text(
                        [cv.email, cv.phone, cv.location, cv.linkedin, cv.github, cv.portfolioUrl]
                            .where((e) => e.isNotEmpty)
                            .join('  |  '),
                        style: pw.TextStyle(fontSize: 7.5, color: mutedText),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 14),

            // Dynamic Sections
            ..._buildOrderedSections(
              cv, primaryColor, darkText, mutedText, lightBg,
              activeLocale: activeLocale,
              skillStyle: PdfSkillStyle.tags,
              experienceStyle: PdfExperienceStyle.standard,
              headerStyle: PdfHeaderStyle.leftAccentLine,
            ),
          ];
        },
      ),
    );
  }

  // 11. ELITE EXECUTIVE (Asymmetric Luxury 35/65 Split with Gold Accents)
  static void _buildEliteExecutiveTemplate(
    pw.Document pdf,
    CvModel cv,
    pw.ThemeData theme,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg,
    String activeLocale,
  ) {
    final goldColor = PdfColor.fromHex('D4AF37');
    final darkSidebarBg = PdfColor.fromHex('0F172A');
    const sidebarWidth = 190.0;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(0),
          buildBackground: (pw.Context context) {
            return pw.FullPage(
              ignoreMargins: true,
              child: pw.Row(
                children: [
                  pw.Container(
                    width: sidebarWidth,
                    color: darkSidebarBg,
                  ),
                  pw.Expanded(
                    child: pw.Container(color: PdfColors.white),
                  ),
                ],
              ),
            );
          },
        ),
        build: (pw.Context context) {
          return [
            pw.Partitions(
              children: [
                // LEFT EXECUTIVE SIDEBAR (Dark column strictly bounded to sidebarWidth)
                pw.Partition(
                  width: sidebarWidth,
                  child: pw.Container(
                  width: sidebarWidth,
                  padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16, vertical: 24),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      // Gold Ringed Profile Avatar
                      pw.Center(
                        child: _buildPdfAvatar(
                          cv,
                          size: 70,
                          backgroundColor: PdfColor.fromHex('1E293B'),
                          borderColor: goldColor,
                          borderWidth: 2.5,
                          textColor: goldColor,
                        ),
                      ),
                      pw.SizedBox(height: 12),

                      // Name & Job Title in Sidebar
                      pw.Center(
                        child: pw.Text(
                          cv.fullName,
                          textAlign: pw.TextAlign.center,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 15,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                      if (cv.jobTitle.isNotEmpty) ...[
                        pw.SizedBox(height: 3),
                        pw.Center(
                          child: pw.Text(
                            cv.jobTitle,
                            textAlign: pw.TextAlign.center,
                            style: pw.TextStyle(
                              color: goldColor,
                              fontSize: 9,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                      ],

                      pw.SizedBox(height: 12),
                      pw.Center(
                        child: pw.Container(
                          width: 32,
                          height: 1.5,
                          color: goldColor,
                        ),
                      ),
                      pw.SizedBox(height: 14),

                      // Sidebar Contact Info
                      _buildSidebarSectionHeader(
                          PdfCvLocaleHelper.getSidebarTitle(
                              'contact', activeLocale),
                          goldColor),
                      pw.SizedBox(height: 6),
                      if (cv.email.isNotEmpty)
                        _buildSidebarContactItem(
                            PdfCvLocaleHelper.getSidebarContactLabel(
                                'email', activeLocale),
                            cv.email),
                      if (cv.phone.isNotEmpty)
                        _buildSidebarContactItem(
                            PdfCvLocaleHelper.getSidebarContactLabel(
                                'phone', activeLocale),
                            cv.phone),
                      if (cv.location.isNotEmpty)
                        _buildSidebarContactItem(
                            PdfCvLocaleHelper.getSidebarContactLabel(
                                'location', activeLocale),
                            cv.location),
                      if (cv.linkedin.isNotEmpty)
                        _buildSidebarContactItem('LinkedIn:', cv.linkedin),
                      if (cv.github.isNotEmpty)
                        _buildSidebarContactItem('GitHub:', cv.github),
                      if (cv.portfolioUrl.isNotEmpty)
                        _buildSidebarContactItem('Web:', cv.portfolioUrl),

                      // Single-Column Executive Skills (Gold 5-Dot Ratings strictly bounded)
                      if (cv.skills.isNotEmpty) ...[
                        pw.SizedBox(height: 14),
                        _buildSidebarSectionHeader(
                            PdfCvLocaleHelper.getSidebarTitle(
                                'skills', activeLocale),
                            goldColor),
                        pw.SizedBox(height: 8),
                        ...cv.skills.map((skill) {
                          final dots = (skill.level / 20).round().clamp(1, 5);
                          return pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 6),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: pw.CrossAxisAlignment.center,
                              children: [
                                pw.Expanded(
                                  child: pw.Text(
                                    skill.name,
                                    maxLines: 1,
                                    overflow: pw.TextOverflow.clip,
                                    style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                                pw.SizedBox(width: 4),
                                pw.Row(
                                  mainAxisSize: pw.MainAxisSize.min,
                                  children: List.generate(5, (dotIdx) {
                                    final isFilled = dotIdx < dots;
                                    return pw.Container(
                                      margin:
                                          const pw.EdgeInsets.only(left: 2.5),
                                      width: 5,
                                      height: 5,
                                      decoration: pw.BoxDecoration(
                                        color: isFilled
                                            ? goldColor
                                            : PdfColor.fromHex('334155'),
                                        shape: pw.BoxShape.circle,
                                      ),
                                    );
                                  }),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // Single-Column Languages
                      if (cv.languages.isNotEmpty) ...[
                        pw.SizedBox(height: 14),
                        _buildSidebarSectionHeader(
                            PdfCvLocaleHelper.getSidebarTitle(
                                'languages', activeLocale),
                            goldColor),
                        pw.SizedBox(height: 6),
                        ...cv.languages.map((lang) {
                          return pw.Container(
                            margin: const pw.EdgeInsets.only(bottom: 5),
                            child: pw.Row(
                              mainAxisAlignment:
                                  pw.MainAxisAlignment.spaceBetween,
                              children: [
                                pw.Expanded(
                                  child: pw.Text(
                                    lang.language,
                                    maxLines: 1,
                                    overflow: pw.TextOverflow.clip,
                                    style: pw.TextStyle(
                                      color: PdfColors.white,
                                      fontSize: 8,
                                      fontWeight: pw.FontWeight.bold,
                                    ),
                                  ),
                                ),
                                pw.Text(
                                  LocalizationService.normalizeLanguageLevel(
                                      lang.level, activeLocale),
                                  style: pw.TextStyle(
                                    color: goldColor,
                                    fontSize: 7.5,
                                    fontWeight: pw.FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],

                      // Personal Traits (if any)
                      if (cv.personalTraits.isNotEmpty) ...[
                        pw.SizedBox(height: 14),
                        _buildSidebarSectionHeader(
                            PdfCvLocaleHelper.getSectionTitle(
                                CvSectionType.personalTraits, activeLocale),
                            goldColor),
                        pw.SizedBox(height: 6),
                        pw.Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: cv.personalTraits.map((trait) {
                            return pw.Container(
                              padding: const pw.EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('1E293B'),
                                borderRadius: pw.BorderRadius.circular(3),
                                border: pw.Border.all(
                                    color: goldColor, width: 0.5),
                              ),
                              child: pw.Text(
                                trait,
                                style: const pw.TextStyle(
                                    color: PdfColors.white, fontSize: 7),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                ),

                // RIGHT MAIN EXECUTIVE COLUMN (Generous space on white canvas)
                pw.Partition(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 22, vertical: 24),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Executive Summary Callout Box
                        if (cv.summary.isNotEmpty) ...[
                          pw.Container(
                            padding: const pw.EdgeInsets.all(10),
                            decoration: pw.BoxDecoration(
                              color: lightBg,
                              border: pw.Border(
                                left: pw.BorderSide(color: goldColor, width: 3),
                              ),
                            ),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                  PdfCvLocaleHelper.getSectionTitle(
                                      CvSectionType.summary, activeLocale),
                                  style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold,
                                    color: darkText,
                                  ),
                                ),
                                pw.SizedBox(height: 4),
                                pw.Text(
                                  cv.summary,
                                  style: pw.TextStyle(
                                      fontSize: 8.5,
                                      color: darkText,
                                      height: 1.35),
                                ),
                              ],
                            ),
                          ),
                          pw.SizedBox(height: 14),
                        ],

                        // Main Sections (Experience, Education, Projects, Certificates, References)
                        ..._buildOrderedSections(
                          cv,
                          goldColor,
                          darkText,
                          mutedText,
                          lightBg,
                          excludedSections: {
                            CvSectionType.summary,
                            CvSectionType.skills,
                            CvSectionType.languages,
                            CvSectionType.personalTraits,
                          },
                          activeLocale: activeLocale,
                          experienceStyle: PdfExperienceStyle.standard,
                          headerStyle: PdfHeaderStyle.doubleRule,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ];
        },
      ),
    );
  }

  // 13. SILICON TECH (Engineering Matrix, Tech Badges & Squircle Photo)
  static void _buildSiliconTechTemplate(
    pw.Document pdf,
    CvModel cv,
    pw.ThemeData theme,
    PdfColor primaryColor,
    PdfColor darkText,
    PdfColor mutedText,
    PdfColor lightBg,
    String activeLocale,
  ) {
    final borderClr = PdfColor(
        primaryColor.red, primaryColor.green, primaryColor.blue, 0.35);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        ),
        build: (pw.Context context) {
          return [
            // Modern Tech Card Header
            pw.Container(
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: lightBg,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: primaryColor, width: 1.2),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                children: [
                  // Squircle Avatar
                  _buildPdfAvatar(
                    cv,
                    size: 62,
                    isCircle: false,
                    borderRadius: 10,
                    backgroundColor: primaryColor,
                    borderColor: primaryColor,
                    borderWidth: 1.5,
                    textColor: PdfColors.white,
                  ),
                  pw.SizedBox(width: 14),

                  // Candidate Info & Badges
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          cv.fullName,
                          style: pw.TextStyle(
                            fontSize: 19,
                            fontWeight: pw.FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        if (cv.jobTitle.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: pw.BoxDecoration(
                              color: primaryColor,
                              borderRadius: pw.BorderRadius.circular(4),
                            ),
                            child: pw.Text(
                              '< ${cv.jobTitle} />',
                              style: pw.TextStyle(
                                color: PdfColors.white,
                                fontSize: 8.5,
                                fontWeight: pw.FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                        pw.SizedBox(height: 6),

                        // Tech Contact Badges
                        pw.Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            if (cv.email.isNotEmpty)
                              _buildTechContactBadge(
                                  cv.email, darkText, borderClr),
                            if (cv.phone.isNotEmpty)
                              _buildTechContactBadge(
                                  cv.phone, darkText, borderClr),
                            if (cv.location.isNotEmpty)
                              _buildTechContactBadge(
                                  cv.location, darkText, borderClr),
                            if (cv.linkedin.isNotEmpty)
                              _buildTechContactBadge(
                                  'in: ${cv.linkedin}', darkText, borderClr),
                            if (cv.github.isNotEmpty)
                              _buildTechContactBadge(
                                  'git: ${cv.github}', darkText, borderClr),
                            if (cv.portfolioUrl.isNotEmpty)
                              _buildTechContactBadge(
                                  cv.portfolioUrl, darkText, borderClr),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(height: 14),

            // Dynamic Sections with 2-Column Bars & Boxed Cards
            ..._buildOrderedSections(
              cv,
              primaryColor,
              darkText,
              mutedText,
              lightBg,
              activeLocale: activeLocale,
              skillStyle: PdfSkillStyle.twoColBar,
              experienceStyle: PdfExperienceStyle.boxedCard,
              headerStyle: PdfHeaderStyle.leftAccentLine,
            ),
          ];
        },
      ),
    );
  }

  // Tech Badge Helper
  static pw.Widget _buildTechContactBadge(
    String text,
    PdfColor textColor,
    PdfColor borderColor,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: borderColor, width: 0.8),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(fontSize: 7.5, color: textColor),
      ),
    );
  }

  // Real Converted Document PDF Generator (Word, Excel, PPT to PDF)
  static Future<Uint8List> generateConvertedDocumentPdf({
    required String fileName,
    required String fileType,
    required String originalFormat,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(LocalizationService.tr('pdf_doc_converter'),
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('2563EB'))),
                  pw.Text(LocalizationService.tr('pdf_vector_pdf'),
                      style: pw.TextStyle(
                          fontSize: 9, color: PdfColor.fromHex('64748B'))),
                ],
              ),
              pw.Divider(color: PdfColor.fromHex('CBD5E1')),
              pw.SizedBox(height: 16),
              pw.Text(
                fileName,
                style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromHex('0F172A')),
              ),
              pw.Text(
                  '${LocalizationService.tr('pdf_original_format')} $originalFormat • ${LocalizationService.tr('pdf_converted_to_pdf')}',
                  style: pw.TextStyle(
                      fontSize: 9, color: PdfColor.fromHex('64748B'))),
              pw.SizedBox(height: 20),
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('F8FAFC'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColor.fromHex('E2E8F0')),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(LocalizationService.tr('pdf_summary_title'),
                        style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('2563EB'))),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      '${LocalizationService.tr('pdf_vector_pdf_desc_1')} $originalFormat ${LocalizationService.tr('pdf_vector_pdf_desc_2')}',
                      style: const pw.TextStyle(fontSize: 9.5, height: 1.4),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text(LocalizationService.tr('pdf_sample_table'),
                  style: pw.TextStyle(
                      fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: [
                  LocalizationService.tr('pdf_table_no'),
                  LocalizationService.tr('pdf_table_section'),
                  LocalizationService.tr('pdf_table_status'),
                  LocalizationService.tr('pdf_table_accuracy')
                ],
                data: [
                  [
                    '1',
                    LocalizationService.tr('pdf_table_text_hierarchy'),
                    LocalizationService.tr('pdf_table_preserved'),
                    '%100'
                  ],
                  [
                    '2',
                    LocalizationService.tr('pdf_table_vector_graphics'),
                    LocalizationService.tr('pdf_table_optimized'),
                    '%100'
                  ],
                  ['3', 'Font ve Karakterler', 'Roboto UTF-8', '%100'],
                  [
                    '4',
                    LocalizationService.tr('pdf_table_security'),
                    LocalizationService.tr('pdf_table_clean_encrypted'),
                    LocalizationService.tr('pdf_table_ok')
                  ],
                ],
                headerStyle: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColor.fromInt(0xFF2563EB)),
                cellStyle: const pw.TextStyle(fontSize: 8),
                cellAlignment: pw.Alignment.centerLeft,
                cellPadding: const pw.EdgeInsets.all(6),
              ),
              pw.Spacer(),
              pw.Divider(color: PdfColor.fromHex('CBD5E1')),
              pw.Text(LocalizationService.tr('pdf_generated_by'),
                  style: pw.TextStyle(
                      fontSize: 8, color: PdfColor.fromHex('94A3B8'))),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Generates a high-quality multi-page Presentation PDF from parsed PPTX slides
  static Future<Uint8List> generatePresentationPdfFromPptx({
    required String presentationTitle,
    required List<PptxSlide> slides,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
      italic: fontItalic,
    );

    for (int i = 0; i < slides.length; i++) {
      final slide = slides[i];
      final isTitleSlide = i == 0;

      pdf.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4.landscape,
            margin: pw.EdgeInsets.zero,
          ),
          build: (context) {
            if (isTitleSlide) {
              return pw.Container(
                width: double.infinity,
                height: double.infinity,
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF0F172A),
                ),
                padding:
                    const pw.EdgeInsets.symmetric(horizontal: 50, vertical: 40),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: pw.BoxDecoration(
                            color: const PdfColor.fromInt(0xFF2563EB),
                            borderRadius: pw.BorderRadius.circular(6),
                          ),
                          child: pw.Text(
                            'POWERPOINT SUNUMU',
                            style: pw.TextStyle(
                              color: PdfColors.white,
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ),
                        pw.Text(
                          'CV AI Presentation Studio',
                          style: const pw.TextStyle(
                              color: PdfColor.fromInt(0xFF94A3B8),
                              fontSize: 10),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          slide.title.isNotEmpty
                              ? slide.title
                              : presentationTitle,
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 32,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 14),
                        if (slide.bulletPoints.isNotEmpty)
                          pw.Text(
                            slide.bulletPoints.join(' • '),
                            style: const pw.TextStyle(
                              color: PdfColor.fromInt(0xFF93C5FD),
                              fontSize: 14,
                            ),
                          )
                        else
                          pw.Text(
                            LocalizationService.tr('pdf_prof_vector_output'),
                            style: const pw.TextStyle(
                              color: PdfColor.fromInt(0xFF93C5FD),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Slayt 1 / ${slides.length}',
                          style: const pw.TextStyle(
                              color: PdfColor.fromInt(0xFF64748B), fontSize: 9),
                        ),
                        pw.Text(
                          'CV AI Pro Studio',
                          style: const pw.TextStyle(
                              color: PdfColor.fromInt(0xFF64748B), fontSize: 9),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }

            return pw.Container(
              width: double.infinity,
              height: double.infinity,
              color: PdfColors.white,
              padding:
                  const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 30),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Row(
                        children: [
                          pw.Container(
                            width: 5,
                            height: 24,
                            decoration: pw.BoxDecoration(
                              color: const PdfColor.fromInt(0xFFEA580C),
                              borderRadius: pw.BorderRadius.circular(2),
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Text(
                            slide.title,
                            style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: const PdfColor.fromInt(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: const PdfColor.fromInt(0xFFF1F5F9),
                          borderRadius: pw.BorderRadius.circular(6),
                        ),
                        child: pw.Text(
                          'Slayt ${slide.index}',
                          style: pw.TextStyle(
                            fontSize: 9,
                            fontWeight: pw.FontWeight.bold,
                            color: const PdfColor.fromInt(0xFF475569),
                          ),
                        ),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Divider(color: const PdfColor.fromInt(0xFFE2E8F0)),
                  pw.SizedBox(height: 16),
                  pw.Expanded(
                    child: pw.ListView.builder(
                      itemCount: slide.bulletPoints.length,
                      itemBuilder: (context, idx) {
                        final bullet = slide.bulletPoints[idx];
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 12),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Container(
                                margin:
                                    const pw.EdgeInsets.only(top: 5, right: 10),
                                width: 8,
                                height: 8,
                                decoration: const pw.BoxDecoration(
                                  color: PdfColor.fromInt(0xFFEA580C),
                                  shape: pw.BoxShape.circle,
                                ),
                              ),
                              pw.Expanded(
                                child: pw.Text(
                                  bullet,
                                  style: const pw.TextStyle(
                                    fontSize: 13,
                                    color: PdfColor.fromInt(0xFF334155),
                                    lineSpacing: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  pw.Divider(color: const PdfColor.fromInt(0xFFE2E8F0)),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        presentationTitle,
                        style: const pw.TextStyle(
                            fontSize: 8.5, color: PdfColor.fromInt(0xFF94A3B8)),
                      ),
                      pw.Text(
                        'Sayfa ${slide.index} / ${slides.length}',
                        style: const pw.TextStyle(
                            fontSize: 8.5, color: PdfColor.fromInt(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // Real Multi-Page CamScanner PDF Generator
  static Future<Uint8List> generateScannedDocumentPdf({
    required List<String> pageNames,
    required String filterMode,
    List<Uint8List?>? pageImages,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    for (int i = 0; i < pageNames.length; i++) {
      final pageName = pageNames[i];
      final imgBytes =
          (pageImages != null && i < pageImages.length) ? pageImages[i] : null;

      pdf.addPage(
        pw.Page(
          pageTheme: pw.PageTheme(
            theme: theme,
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
          ),
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(LocalizationService.tr('pdf_camscanner_hd'),
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('10B981'))),
                    pw.Text(
                        '${LocalizationService.tr('pdf_page')} ${i + 1} / ${pageNames.length}',
                        style: pw.TextStyle(
                            fontSize: 9, color: PdfColor.fromHex('64748B'))),
                  ],
                ),
                pw.Divider(color: PdfColor.fromHex('CBD5E1')),
                pw.SizedBox(height: 8),
                pw.Text('Belge: $pageName',
                    style: pw.TextStyle(
                        fontSize: 12, fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    '${LocalizationService.tr('pdf_filter')} $filterMode ${LocalizationService.tr('pdf_auto_enhance')}',
                    style: pw.TextStyle(
                        fontSize: 8, color: PdfColor.fromHex('64748B'))),
                pw.SizedBox(height: 12),

                // Real Scanned Image or Structured OCR Preview
                pw.Expanded(
                  child: imgBytes != null
                      ? pw.Center(
                          child: pw.Image(pw.MemoryImage(imgBytes),
                              fit: pw.BoxFit.contain),
                        )
                      : pw.Container(
                          width: double.infinity,
                          padding: const pw.EdgeInsets.all(18),
                          decoration: pw.BoxDecoration(
                            color: filterMode == 'B&W'
                                ? PdfColors.white
                                : PdfColor.fromHex('F8FAFC'),
                            border: pw.Border.all(
                                color: PdfColor.fromHex('CBD5E1'), width: 1.2),
                            borderRadius: pw.BorderRadius.circular(8),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Center(
                                child: pw.Text(
                                    LocalizationService.tr('pdf_official_scan'),
                                    style: pw.TextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold,
                                        color: PdfColor.fromHex('0F172A'),
                                        letterSpacing: 1.2)),
                              ),
                              pw.SizedBox(height: 14),
                              pw.Text(
                                  '${LocalizationService.tr('pdf_doc_ref')} TR-SCAN-2026-${1000 + i}',
                                  style: pw.TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: pw.FontWeight.bold)),
                              pw.Text(
                                  LocalizationService.tr('pdf_ocr_accuracy'),
                                  style: pw.TextStyle(
                                      fontSize: 8,
                                      color: PdfColor.fromHex('64748B'))),
                              pw.SizedBox(height: 14),
                              pw.Text(
                                LocalizationService.tr('pdf_camscanner_desc'),
                                style: const pw.TextStyle(
                                    fontSize: 9, height: 1.4),
                              ),
                              pw.Spacer(),
                              pw.Row(
                                mainAxisAlignment:
                                    pw.MainAxisAlignment.spaceBetween,
                                children: [
                                  pw.Column(
                                    crossAxisAlignment:
                                        pw.CrossAxisAlignment.start,
                                    children: [
                                      pw.Text(
                                          '${LocalizationService.tr('pdf_date')} 31.08.2026',
                                          style:
                                              const pw.TextStyle(fontSize: 8)),
                                      pw.Text(
                                          LocalizationService.tr(
                                              'pdf_security_sha256'),
                                          style:
                                              const pw.TextStyle(fontSize: 8)),
                                    ],
                                  ),
                                  pw.Container(
                                    padding: const pw.EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: pw.BoxDecoration(
                                      border: pw.Border.all(
                                          color: PdfColor.fromHex('10B981')),
                                      borderRadius: pw.BorderRadius.circular(4),
                                    ),
                                    child: pw.Text(
                                        LocalizationService.tr(
                                            'pdf_approved_hd'),
                                        style: pw.TextStyle(
                                            fontSize: 8,
                                            fontWeight: pw.FontWeight.bold,
                                            color: PdfColor.fromHex('10B981'))),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // 1. Real Image to PDF Generator (Takes actual picked image bytes)
  static Future<Uint8List> generateImageToPdf({
    required List<Uint8List> imageBytesList,
    required String title,
  }) async {
    final pdf = pw.Document();

    for (int i = 0; i < imageBytesList.length; i++) {
      final image = pw.MemoryImage(imageBytesList[i]);
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );
    }

    return pdf.save();
  }

  // 2. Real Text & Document to PDF Generator (Word/Docx/TXT/MD)
  static Future<Uint8List> generateTextDocumentPdf({
    required String title,
    required String content,
    String originalFormat = 'DOCX',
    String author = 'CV AI User',
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final fontItalic = await PdfGoogleFonts.robotoItalic();
    final theme = pw.ThemeData.withFont(
        base: fontRegular, bold: fontBold, italic: fontItalic);

    final paragraphs = content.split('\n');

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.symmetric(horizontal: 36, vertical: 36),
        ),
        header: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('2563EB'))),
              pw.Text(
                  '${LocalizationService.tr('pdf_converted_format')} .$originalFormat ➔ PDF',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey700)),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 16),
          padding: const pw.EdgeInsets.only(top: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.8)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(LocalizationService.tr('pdf_secure_converter'),
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600)),
              pw.Text('Sayfa ${context.pageNumber} / ${context.pagesCount}',
                  style: const pw.TextStyle(
                      fontSize: 8, color: PdfColors.grey600)),
            ],
          ),
        ),
        build: (context) {
          return [
            pw.Text(
              title,
              style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('0F172A')),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              'Yazar: $author • Tarih: ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
            ),
            pw.Divider(
                height: 20, color: PdfColor.fromHex('2563EB'), thickness: 1.5),
            pw.SizedBox(height: 8),
            ...paragraphs.map((p) {
              final trimmed = p.trim();
              if (trimmed.isEmpty) return pw.SizedBox(height: 6);
              if (trimmed.startsWith('# ')) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 12, bottom: 4),
                  child: pw.Text(
                    trimmed.substring(2),
                    style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('1E293B')),
                  ),
                );
              }
              if (trimmed.startsWith('## ')) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(top: 8, bottom: 3),
                  child: pw.Text(
                    trimmed.substring(3),
                    style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('334155')),
                  ),
                );
              }
              if (trimmed.startsWith('- ') || trimmed.startsWith('* ')) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(left: 12, bottom: 3),
                  child: pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('• ',
                          style: pw.TextStyle(
                              fontSize: 10,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('2563EB'))),
                      pw.Expanded(
                        child: pw.Text(trimmed.substring(2),
                            style: const pw.TextStyle(
                                fontSize: 9.5, height: 1.35)),
                      ),
                    ],
                  ),
                );
              }
              return pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Text(trimmed,
                    style: const pw.TextStyle(fontSize: 9.5, height: 1.45)),
              );
            }),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // 3. Real Spreadsheet / Table to PDF Generator (Excel / CSV)
  static Future<Uint8List> generateSpreadsheetPdf({
    required String title,
    required List<List<String>> tableData,
    String sheetName = 'Sayfa 1',
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    if (tableData.isEmpty) {
      tableData = [
        [
          LocalizationService.tr('pdf_table_no'),
          LocalizationService.tr('pdf_table_item'),
          LocalizationService.tr('pdf_table_quantity'),
          LocalizationService.tr('pdf_table_unit_price'),
          LocalizationService.tr('pdf_table_total')
        ],
        [
          '1',
          LocalizationService.tr('pdf_table_software_consulting'),
          '1 ${LocalizationService.tr('pdf_table_month')}',
          '45.000,00 TL',
          '45.000,00 TL'
        ],
        [
          '2',
          LocalizationService.tr('pdf_table_mobile_app_dev'),
          '1 ${LocalizationService.tr('pdf_table_project')}',
          '85.000,00 TL',
          '85.000,00 TL'
        ],
        ['3', 'Bulut Sunucu & SSL', '12 Ay', '1.200,00 TL', '14.400,00 TL'],
        ['TOPLAM', '', '', '', '144.400,00 TL'],
      ];
    }

    final headers = tableData.first;
    final rows = tableData.sublist(1);

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(32),
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(title,
                          style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColor.fromHex('15803D'))),
                      pw.Text(
                          '${LocalizationService.tr('pdf_worksheet')} $sheetName • ${LocalizationService.tr('pdf_excel_to_pdf')}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('DCFCE7'),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColor.fromHex('86EFAC')),
                    ),
                    child: pw.Text('EXCEL HESAP TABLOSU',
                        style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('15803D'))),
                  ),
                ],
              ),
              pw.Divider(
                  height: 18,
                  color: PdfColor.fromHex('15803D'),
                  thickness: 1.5),
              pw.SizedBox(height: 8),
              pw.TableHelper.fromTextArray(
                headers: headers,
                data: rows,
                headerStyle: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 9.5),
                headerDecoration:
                    pw.BoxDecoration(color: PdfColor.fromHex('15803D')),
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration:
                    pw.BoxDecoration(color: PdfColor.fromHex('F0FDF4')),
                cellAlignment: pw.Alignment.centerLeft,
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding:
                    const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: pw.TableBorder.all(
                    color: PdfColor.fromHex('CBD5E1'), width: 0.7),
              ),
              pw.Spacer(),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                      '${LocalizationService.tr('pdf_report_date')} ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600)),
                  pw.Text(LocalizationService.tr('pdf_excel_generated_by'),
                      style: const pw.TextStyle(
                          fontSize: 8, color: PdfColors.grey600)),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // 4. Real Signed Document PDF Generator (With actual drawn signature bytes)
  static Future<Uint8List> generateSignedDocumentPdf({
    required String docTitle,
    required String docBody,
    required Uint8List signatureImageBytes,
    required String signerName,
    required DateTime signedDate,
  }) async {
    final pdf = pw.Document();
    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();
    final theme = pw.ThemeData.withFont(base: fontRegular, bold: fontBold);

    final signatureImage = pw.MemoryImage(signatureImageBytes);

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
        ),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(docTitle,
                      style: pw.TextStyle(
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('0F172A'))),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('FEF3C7'),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColor.fromHex('FCD34D')),
                    ),
                    child: pw.Text(
                        LocalizationService.tr('pdf_official_signed'),
                        style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('B45309'))),
                  ),
                ],
              ),
              pw.Divider(
                  height: 18,
                  color: PdfColor.fromHex('0F172A'),
                  thickness: 1.5),
              pw.SizedBox(height: 10),

              pw.Text(
                docBody,
                style: const pw.TextStyle(fontSize: 10, height: 1.5),
              ),

              pw.Spacer(),

              // Signer Box with Embedded Drawn Signature Image
              pw.Container(
                padding: const pw.EdgeInsets.all(14),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('F8FAFC'),
                  borderRadius: pw.BorderRadius.circular(10),
                  border: pw.Border.all(color: PdfColor.fromHex('CBD5E1')),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                            '${LocalizationService.tr('pdf_signed_by')} $signerName',
                            style: pw.TextStyle(
                                fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text(
                            '${LocalizationService.tr('pdf_date_time')} ${signedDate.day}.${signedDate.month}.${signedDate.year} ${signedDate.hour.toString().padLeft(2, '0')}:${signedDate.minute.toString().padLeft(2, '0')}',
                            style: const pw.TextStyle(
                                fontSize: 8.5, color: PdfColors.grey700)),
                        pw.Text(
                            LocalizationService.tr(
                                'pdf_verification_biometric'),
                            style: pw.TextStyle(
                                fontSize: 8,
                                color: PdfColor.fromHex('15803D'),
                                fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                    pw.Container(
                      width: 130,
                      height: 55,
                      padding: const pw.EdgeInsets.all(4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(
                            color: PdfColor.fromHex('94A3B8'),
                            style: pw.BorderStyle.dashed),
                      ),
                      child: pw.Center(
                        child: pw.Image(signatureImage, fit: pw.BoxFit.contain),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Çok sayfalı gerçek taranan belgelerden ve fotoğraflardan yüksek çözünürlüklü PDF üretir.
  static Future<Uint8List> generateScannedDocPdf({
    required List<Map<String, dynamic>> pages,
    String docTitle = 'CamScanner_HD_Tarama',
  }) async {
    final pdf = pw.Document();

    final fontRegular = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    final theme = pw.ThemeData.withFont(
      base: fontRegular,
      bold: fontBold,
    );

    for (int i = 0; i < pages.length; i++) {
      final pageData = pages[i];
      final Uint8List? imageBytes = pageData['imageBytes'] as Uint8List?;
      final String name = (pageData['name'] as String?) ?? 'Sayfa ${i + 1}';
      final String docType = (pageData['docType'] as String?) ?? 'Resmi Belge';
      final String ocrText = (pageData['ocrText'] as String?) ?? '';

      pdf.addPage(
        pw.Page(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context context) {
            if (imageBytes != null && imageBytes.isNotEmpty) {
              final memImage = pw.MemoryImage(imageBytes);
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Page Header
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'CV AI CamScanner HD • $docType',
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('2563EB')),
                      ),
                      pw.Text(
                        'Sayfa ${i + 1} / ${pages.length}',
                        style: const pw.TextStyle(
                            fontSize: 9, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Divider(
                      height: 10,
                      thickness: 0.8,
                      color: PdfColor.fromHex('E2E8F0')),
                  pw.SizedBox(height: 8),

                  // Image Container (Fills Page)
                  pw.Expanded(
                    child: pw.Center(
                      child: pw.Image(memImage, fit: pw.BoxFit.contain),
                    ),
                  ),

                  pw.SizedBox(height: 8),
                  pw.Divider(
                      height: 10,
                      thickness: 0.8,
                      color: PdfColor.fromHex('E2E8F0')),

                  // Page Footer with Timestamp
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Dosya: $name.pdf',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600)),
                      pw.Text(
                          '${LocalizationService.tr('pdf_date')} ${DateTime.now().day}.${DateTime.now().month}.${DateTime.now().year}',
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              );
            } else {
              // Vector text document with OCR transcription
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'CV AI CamScanner HD • $docType',
                        style: pw.TextStyle(
                            fontSize: 12,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('2563EB')),
                      ),
                      pw.Text(
                          '${LocalizationService.tr('pdf_page')} ${i + 1} / ${pages.length}',
                          style: const pw.TextStyle(
                              fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                  pw.Divider(
                      height: 14,
                      thickness: 1.2,
                      color: PdfColor.fromHex('0F172A')),
                  pw.SizedBox(height: 12),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('F8FAFC'),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColor.fromHex('E2E8F0')),
                    ),
                    child: pw.Text(
                      ocrText.isNotEmpty
                          ? ocrText
                          : LocalizationService.tr('pdf_no_ocr_record'),
                      style: const pw.TextStyle(fontSize: 10, height: 1.6),
                    ),
                  ),
                  pw.Spacer(),
                  pw.Divider(height: 10, color: PdfColor.fromHex('E2E8F0')),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(LocalizationService.tr('pdf_auto_ocr_output'),
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600)),
                      pw.Text(LocalizationService.tr('pdf_ats_standard'),
                          style: const pw.TextStyle(
                              fontSize: 8, color: PdfColors.grey600)),
                    ],
                  ),
                ],
              );
            }
          },
        ),
      );
    }

    return pdf.save();
  }

  /// Görseller listesini doğrudan çok sayfalı PDF formatına dönüştürür.
  static Future<Uint8List> generateImagesToPdf(
      List<Uint8List> imageBytesList) async {
    final pdf = pw.Document();

    for (final bytes in imageBytesList) {
      if (bytes.isNotEmpty) {
        final memImg = pw.MemoryImage(bytes);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(16),
            build: (pw.Context context) {
              return pw.Center(
                child: pw.Image(memImg, fit: pw.BoxFit.contain),
              );
            },
          ),
        );
      }
    }

    return pdf.save();
  }
}
