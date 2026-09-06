import 'dart:typed_data';

class WorkExperience {
  String company;
  String position;
  String startDate;
  String endDate;
  bool isCurrent;
  String description;

  WorkExperience({
    required this.company,
    required this.position,
    required this.startDate,
    required this.endDate,
    this.isCurrent = false,
    required this.description,
  });
}

class Education {
  String school;
  String degree;
  String field;
  String startDate;
  String endDate;
  String gpa; // Not Ortalaması / GNO / GPA (Örn: 3.84 / 4.00, %88)

  Education({
    required this.school,
    required this.degree,
    required this.field,
    required this.startDate,
    required this.endDate,
    this.gpa = '',
  });
}

class SkillItem {
  String name;
  int level; // 20 to 100
  String levelLabel; // Uzman, İleri, Orta, Temel

  SkillItem({
    required this.name,
    this.level = 80,
    this.levelLabel = 'İleri Düzey',
  });
}

class LanguageItem {
  String language;
  String level; // Ana Dil, C2 - Uzman, C1 - İleri, B2 - Orta-İleri, B1 - Orta, A2, A1

  LanguageItem({
    required this.language,
    required this.level,
  });
}

class ReferenceItem {
  String name;
  String position;
  String company;
  String phone;
  String email;

  ReferenceItem({
    required this.name,
    required this.position,
    required this.company,
    this.phone = '',
    this.email = '',
  });
}

class ProjectItem {
  String name;
  String role;
  String link;
  String date;
  String description;
  String technologies;

  ProjectItem({
    required this.name,
    this.role = '',
    this.link = '',
    this.date = '',
    required this.description,
    this.technologies = '',
  });
}

class CertificateItem {
  String name;
  String issuer;
  String date;
  String credentialUrl;

  CertificateItem({
    required this.name,
    required this.issuer,
    this.date = '',
    this.credentialUrl = '',
  });
}

class CustomCvSection {
  String id;
  String title;
  List<String> items;

  CustomCvSection({
    required this.id,
    required this.title,
    required this.items,
  });
}

enum CvTemplate {
  sidebarModern,   // Sol Sütunlu İki Renkli Modern (İstenen sol taraflı şablon)
  modernTech,      // Modern ATS İki Sütunlu
  executiveClassic,// Stanford & Klasik ATS Tek Sütunlu
  creativeDesigner,// Görsel Renkli Başlık & Portfolyo Odaklı
  minimalistPure,  // Sade İskandinav & Şık
  harvardAcademic, // Harvard & Oxford Akademik
  compactGrid,     // Kompakt ATS Çift Kolonlu
  infographicModern,// İnfografik Modern & Metrik Odaklı
  corporateGold,   // Kurumsal Lüks Gold & Çerçeveli Yönetici
  cleanNordic,     // Nordik Minimalist & Geometrik Başlıklı
  eliteExecutive,  // Elit Yönetici & Asimetrik Prestij Bölünmüş
  siliconTech,     // Silikon Vadisi & Modern Tech Mühendis
}

enum CvSectionType {
  summary,
  experiences,
  educations,
  skills,
  personalTraits, // Kişisel Özellikler / Nitelikler
  languages,
  projects,
  certificates,
  references,
  customSections,
}

class CvModel {
  String id;
  String fullName;
  String jobTitle;
  String email;
  String phone;
  String location;
  String summary;
  String linkedin;
  String github;
  String portfolioUrl;
  String? profilePhoto;
  Uint8List? profilePhotoBytes;
  bool hasPhoto;

  List<WorkExperience> experiences;
  List<Education> educations;
  List<SkillItem> skills;
  List<String> personalTraits; // Kişisel Özellikler / Yetkinlikler
  List<LanguageItem> languages;
  List<ReferenceItem> references;
  List<ProjectItem> projects;
  List<CertificateItem> certificates;
  List<CustomCvSection> customSections;
  List<CvSectionType> sectionOrder;

  CvTemplate template;
  int primaryColorHex;
  String? targetLanguage;

  CvModel({
    required this.id,
    required this.fullName,
    required this.jobTitle,
    required this.email,
    required this.phone,
    required this.location,
    required this.summary,
    this.linkedin = '',
    this.github = '',
    this.portfolioUrl = '',
    this.profilePhoto,
    this.profilePhotoBytes,
    this.hasPhoto = true,
    required this.experiences,
    required this.educations,
    required this.skills,
    List<String>? personalTraits,
    required this.languages,
    List<ReferenceItem>? references,
    List<ProjectItem>? projects,
    List<CertificateItem>? certificates,
    List<CustomCvSection>? customSections,
    List<CvSectionType>? sectionOrder,
    this.template = CvTemplate.sidebarModern,
    this.primaryColorHex = 0xFF2563EB,
    this.targetLanguage,
  })  : personalTraits = personalTraits ?? [],
        references = references ?? [],
        projects = projects ?? [],
        certificates = certificates ?? [],
        customSections = customSections ?? [],
        sectionOrder = sectionOrder ?? [
          CvSectionType.summary,
          CvSectionType.experiences,
          CvSectionType.educations,
          CvSectionType.projects,
          CvSectionType.skills,
          CvSectionType.personalTraits,
          CvSectionType.languages,
          CvSectionType.certificates,
          CvSectionType.references,
          CvSectionType.customSections,
        ];

  bool get isSample {
    final name = fullName.toLowerCase().trim();
    final isSampleName = name == 'canberk yılmaz' ||
        name == 'alex morgan' ||
        name == 'max mustermann' ||
        name == 'jean dupont' ||
        name == 'carlos garcía' ||
        name == 'алексей смирнов' ||
        name == 'li wei' ||
        name == 'alexander müller';
    return isSampleName ||
        (name.isEmpty &&
            experiences.any((e) => e.company.contains('TechVentures Global')));
  }

  /// Calculates realistic ATS compatibility score (0-100%) based on actually filled content
  int calculateAtsScore() {
    int score = 0;

    // 1. Identity & Contact Information (Max 25 pts)
    if (fullName.trim().isNotEmpty) score += 5;
    if (jobTitle.trim().isNotEmpty) score += 5;
    if (email.trim().isNotEmpty) score += 5;
    if (phone.trim().isNotEmpty) score += 5;
    if (location.trim().isNotEmpty) score += 5;

    // 2. Executive Professional Summary (Max 15 pts)
    final summaryTrim = summary.trim();
    if (summaryTrim.length >= 20) score += 10;
    if (summaryTrim.length >= 80) score += 5;

    // 3. Work Experiences (Max 25 pts)
    final filledExperiences = experiences.where(
      (e) => e.company.trim().isNotEmpty || e.position.trim().isNotEmpty,
    ).toList();
    if (filledExperiences.isNotEmpty) score += 15;
    if (filledExperiences.any((e) => e.description.trim().length >= 25)) {
      score += 5;
    }
    if (filledExperiences.length >= 2) score += 5;

    // 4. Educations (Max 15 pts)
    final filledEducations = educations.where(
      (e) => e.school.trim().isNotEmpty || e.field.trim().isNotEmpty,
    ).toList();
    if (filledEducations.isNotEmpty) score += 15;

    // 5. Skills (Max 10 pts)
    final filledSkills = skills.where((s) => s.name.trim().isNotEmpty).toList();
    if (filledSkills.isNotEmpty) score += 3;
    if (filledSkills.length >= 3) score += 4;
    if (filledSkills.length >= 5) score += 3;

    // 6. Additional Sections / Boosters (Max 10 pts)
    final filledLanguages =
        languages.where((l) => l.language.trim().isNotEmpty).toList();
    if (filledLanguages.isNotEmpty) score += 5;

    final filledCerts =
        certificates.where((c) => c.name.trim().isNotEmpty).toList();
    final filledProjects =
        projects.where((p) => p.name.trim().isNotEmpty).toList();
    if (filledCerts.isNotEmpty || filledProjects.isNotEmpty) score += 5;

    return score.clamp(0, 100);
  }

  /// Creates a clean, empty CV with exactly 1 empty card in each dynamic section
  static CvModel createEmpty([String? locale]) {
    return CvModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      fullName: '',
      jobTitle: '',
      email: '',
      phone: '',
      location: '',
      summary: '',
      linkedin: '',
      github: '',
      portfolioUrl: '',
      hasPhoto: true,
      profilePhoto: null,
      profilePhotoBytes: null,
      experiences: [
        WorkExperience(
          company: '',
          position: '',
          startDate: '',
          endDate: '',
          isCurrent: false,
          description: '',
        ),
      ],
      educations: [
        Education(
          school: '',
          degree: '',
          field: '',
          startDate: '',
          endDate: '',
          gpa: '',
        ),
      ],
      skills: [],
      personalTraits: [],
      languages: [
        LanguageItem(
          language: '',
          level: '',
        ),
      ],
      references: [
        ReferenceItem(
          name: '',
          position: '',
          company: '',
          phone: '',
          email: '',
        ),
      ],
      projects: [
        ProjectItem(
          name: '',
          role: '',
          link: '',
          date: '',
          description: '',
          technologies: '',
        ),
      ],
      certificates: [
        CertificateItem(
          name: '',
          issuer: '',
          date: '',
          credentialUrl: '',
        ),
      ],
      customSections: [],
      targetLanguage: locale,
    );
  }

  static CvModel createSample([String? locale]) {
    final lang = (locale ?? 'en').toLowerCase().replaceAll('-', '_');

    // 1. TÜRKÇE
    if (lang.startsWith('tr')) {
      return CvModel(
        id: '1',
        fullName: 'Canberk Yılmaz',
        jobTitle: 'Kıdemli Mobil Yazılım Uzmanı',
        email: 'canberk.yilmaz@email.com',
        phone: '+90 (555) 012 34 56',
        location: 'İstanbul, Türkiye',
        summary:
            '6+ yıllık mobil uygulama geliştirme tecrübesine sahip, Flutter ve Swift mimarilerinde uzmanlaşmış, yüksek performanslı ve kullanıcı odaklı küresel projeler üretmiş yazılım mühendisi.',
        linkedin: 'linkedin.com/in/canberkyilmaz',
        github: 'github.com/canberk',
        portfolioUrl: 'canberkyilmaz.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global',
            position: 'Lead Mobile Developer',
            startDate: '2022',
            endDate: 'Günümüz',
            isCurrent: true,
            description:
                'Milyonlarca aktif kullanıcısı olan e-ticaret ve finans mobil uygulamasının mimarisini yönetti. Uygulama açılış süresini %40 hızlandırdı.',
          ),
          WorkExperience(
            company: 'SoftStudio Inc.',
            position: 'Mobile Developer',
            startDate: '2019',
            endDate: '2022',
            description:
                '10+ kurumsal iOS ve Android uygulamasını sıfırdan geliştirip App Store & Google Play mağazalarında yayınladı.',
          ),
        ],
        educations: [
          Education(
            school: 'İstanbul Teknik Üniversitesi (İTÜ)',
            degree: 'Lisans',
            field: 'Bilgisayar Mühendisliği',
            startDate: '2015',
            endDate: '2019',
            gpa: '3.84 / 4.00',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'Uzman (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'İleri (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'İleri (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'Uzman (%90)'),
          SkillItem(name: 'CI/CD & App Store', level: 85, levelLabel: 'İleri (%85)'),
          SkillItem(name: 'UI/UX Design', level: 75, levelLabel: 'Orta-İleri (%75)'),
        ],
        personalTraits: [
          'Analitik Düşünme & Problem Çözme',
          'Takım Çalışması & Çevik Liderlik',
          'Hızlı Öğrenme & Yüksek Adaptasyon',
          'Zaman & Öncelik Yönetimi',
          'Yenilikçi & Çözüm Odaklı Yaklaşım',
          'Etkili İletişim & Sunum Becerisi',
        ],
        languages: [
          LanguageItem(language: 'Türkçe', level: 'Ana Dil'),
          LanguageItem(language: 'İngilizce', level: 'C1 - İleri Düzey'),
          LanguageItem(language: 'Almanca', level: 'B1 - Orta Düzey'),
        ],
        references: [
          ReferenceItem(
            name: 'Prof. Dr. Ahmet Demir',
            position: 'Bölüm Başkanı',
            company: 'İTÜ Bilgisayar Mühendisliği',
            phone: '+90 (212) 285 00 00',
            email: 'ademir@itu.edu.tr',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'Baş Mimar',
            link: 'github.com/canberk/cv-ai',
            date: '2025 - 2026',
            description: 'Yapay zeka destekli yerel PDF motoru ve akıllı CV oluşturma uygulaması.',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: 'Ödüller & Başarılar',
            items: [
              '1.lik Ödülü - Ulusal Yazılım İnovasyon Yarışması (2019)',
              'En İyi UI/UX Tasarım Ödülü - Hackathon İstanbul (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 2. DEUTSCH (ALMANCA)
    if (lang.startsWith('de')) {
      return CvModel(
        id: '1',
        fullName: 'Max Mustermann',
        jobTitle: 'Senior Mobile Software-Entwickler',
        email: 'max.mustermann@email.de',
        phone: '+49 170 1234567',
        location: 'München, Deutschland',
        summary:
            'Erfahrener Mobile-Entwickler mit über 6 Jahren Erfahrung in der Entwicklung skalierbarer und performanter Apps mit Flutter, iOS (Swift) und Android (Kotlin). Fokus auf moderne Architekturen und exzellente UI/UX.',
        linkedin: 'linkedin.com/in/maxmustermann',
        github: 'github.com/maxmustermann',
        portfolioUrl: 'maxmustermann.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global GmbH',
            position: 'Lead Mobile Developer',
            startDate: '2022',
            endDate: 'Aktuell',
            isCurrent: true,
            description:
                'Leitung des Mobile-Teams für Fintech-Anwendungen mit über 3 Millionen aktiven Nutzern. Reduzierung der Ladezeiten um 40%.',
          ),
          WorkExperience(
            company: 'SoftStudio GmbH',
            position: 'Mobile Developer',
            startDate: '2019',
            endDate: '2022',
            description:
                'Entwicklung und Veröffentlichung von über 10 nativen und plattformübergreifenden Apps im App Store und Google Play.',
          ),
        ],
        educations: [
          Education(
            school: 'Technische Universität München (TUM)',
            degree: 'Master of Science',
            field: 'Informatik',
            startDate: '2015',
            endDate: '2019',
            gpa: '1.3 (Sehr Gut)',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'Experte (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'Fortgeschritten (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'Fortgeschritten (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'Experte (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: 'Fortgeschritten (%85)'),
          SkillItem(name: 'UI/UX Design', level: 75, levelLabel: 'Gut (%75)'),
        ],
        personalTraits: [
          'Analytisches Denken & Problemlösung',
          'Teamarbeit & Agile Führung',
          'Schnelle Auffassungsgabe',
          'Zeit- & Prioritätenmanagement',
          'Innovations- & Lösungsorientiert',
          'Effektive Kommunikation & Präsentation',
        ],
        languages: [
          LanguageItem(language: 'Deutsch', level: 'Muttersprache'),
          LanguageItem(language: 'Englisch', level: 'C1 - Verhandlungssicher'),
          LanguageItem(language: 'Französisch', level: 'B1 - Mittelstufe'),
        ],
        references: [
          ReferenceItem(
            name: 'Prof. Dr. Klaus Weber',
            position: 'Lehrstuhlinhaber',
            company: 'TUM Informatik',
            phone: '+49 89 289 01',
            email: 'weber@in.tum.de',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'Lead Architect',
            link: 'github.com/max/cv-ai',
            date: '2025 - 2026',
            description: 'On-Device PDF-Engine und KI-gestützte Lebenslauf-Erstellungs-App.',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: 'Auszeichnungen & Erfolge',
            items: [
              '1. Platz - Deutscher Innovationspreis für Softwareentwicklung (2019)',
              'Bester UI/UX Design Award - European Mobile Hackathon (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 3. FRANÇAIS (FRANSIZCA)
    if (lang.startsWith('fr')) {
      return CvModel(
        id: '1',
        fullName: 'Julien Dubois',
        jobTitle: 'Ingénieur Logiciel Mobile Senior',
        email: 'julien.dubois@email.fr',
        phone: '+33 6 12 34 56 78',
        location: 'Paris, France',
        summary:
            'Ingénieur logiciel avec plus de 6 ans d\'expérience dans le développement d\'applications mobiles performantes (Flutter, iOS, Android). Passionné par l\'architecture propre et l\'expérience utilisateur.',
        linkedin: 'linkedin.com/in/juliendubois',
        github: 'github.com/juliendubois',
        portfolioUrl: 'juliendubois.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global SAS',
            position: 'Lead Développeur Mobile',
            startDate: '2022',
            endDate: 'Présent',
            isCurrent: true,
            description:
                'Direction technique d\'une application mobile comptant plus de 3 millions d\'utilisateurs actifs. Optimisation des performances et réduction du temps de démarrage de 40%.',
          ),
          WorkExperience(
            company: 'SoftStudio Paris',
            position: 'Développeur Mobile',
            startDate: '2019',
            endDate: '2022',
            description:
                'Développement et publication de plus de 10 applications iOS et Android sur l\'App Store et Google Play.',
          ),
        ],
        educations: [
          Education(
            school: 'École Polytechnique / Sorbonne Université',
            degree: 'Diplôme d\'Ingénieur (Master)',
            field: 'Informatique & Génie Logiciel',
            startDate: '2015',
            endDate: '2019',
            gpa: 'Mention Très Bien',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'Expert (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'Avancé (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'Avancé (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'Expert (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: 'Avancé (%85)'),
          SkillItem(name: 'Design UI/UX', level: 75, levelLabel: 'Compétent (%75)'),
        ],
        personalTraits: [
          'Résolution de problèmes & Analyse',
          'Travail d\'équipe & Leadership agile',
          'Adaptabilité rapide & Curiosité',
          'Gestion du temps & Priorités',
          'Esprit d\'innovation & Solutions',
          'Communication claire & Présentation',
        ],
        languages: [
          LanguageItem(language: 'Français', level: 'Langue maternelle'),
          LanguageItem(language: 'Anglais', level: 'C1 - Courant / Professionnel'),
          LanguageItem(language: 'Espagnol', level: 'B1 - Intermédiaire'),
        ],
        references: [
          ReferenceItem(
            name: 'Prof. Jean-Pierre Laurent',
            position: 'Directeur de Département',
            company: 'Sorbonne Informatique',
            phone: '+33 1 44 27 44 27',
            email: 'laurent@sorbonne.fr',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'Architecte Principal',
            link: 'github.com/julien/cv-ai',
            date: '2025 - 2026',
            description: 'Moteur PDF autonome et générateur de CV intelligent avec IA locale.',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: 'Prix & Récompenses',
            items: [
              '1er Prix - Concours National de l\'Innovation Logicielle (2019)',
              'Meilleur Design UI/UX - Hackathon Européen Mobile (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 4. ESPAÑOL (İSPANYOLCA)
    if (lang.startsWith('es')) {
      return CvModel(
        id: '1',
        fullName: 'Carlos Rodríguez',
        jobTitle: 'Ingeniero de Software Móvil Senior',
        email: 'carlos.rodriguez@email.es',
        phone: '+34 612 345 678',
        location: 'Madrid, España',
        summary:
            'Ingeniero de software con más de 6 años de experiencia creando aplicaciones móviles de alto rendimiento y arquitectura escalable con Flutter, Swift y Kotlin.',
        linkedin: 'linkedin.com/in/carlosrodriguez',
        github: 'github.com/carlosrodriguez',
        portfolioUrl: 'carlosrodriguez.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global SL',
            position: 'Líder de Desarrollo Móvil',
            startDate: '2022',
            endDate: 'Actualidad',
            isCurrent: true,
            description:
                'Liderazgo del equipo de ingeniería móvil para aplicaciones financieras y e-commerce con más de 3 millones de usuarios activos. Reducción del tiempo de inicio en un 40%.',
          ),
          WorkExperience(
            company: 'SoftStudio Madrid',
            position: 'Desarrollador Móvil',
            startDate: '2019',
            endDate: '2022',
            description:
                'Desarrollo y publicación de más de 10 aplicaciones en App Store y Google Play con integración de autenticación biométrica y APIs RESTful.',
          ),
        ],
        educations: [
          Education(
            school: 'Universidad Politécnica de Madrid (UPM)',
            degree: 'Grado en Ingeniería Informática',
            field: 'Ingeniería del Software',
            startDate: '2015',
            endDate: '2019',
            gpa: '9.2 / 10',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'Experto (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'Avanzado (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'Avanzado (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'Experto (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: 'Avanzado (%85)'),
          SkillItem(name: 'Diseño UI/UX', level: 75, levelLabel: 'Competente (%75)'),
        ],
        personalTraits: [
          'Resolución de problemas & Análisis',
          'Liderazgo y trabajo en equipo ágil',
          'Adaptabilidad y aprendizaje rápido',
          'Gestión del tiempo y prioridades',
          'Orientación a resultados e innovación',
          'Comunicación efectiva y asertiva',
        ],
        languages: [
          LanguageItem(language: 'Español', level: 'Nativo'),
          LanguageItem(language: 'Inglés', level: 'C1 - Avanzado / Profesional'),
          LanguageItem(language: 'Francés', level: 'B1 - Intermedio'),
        ],
        references: [
          ReferenceItem(
            name: 'Prof. Dr. Manuel Gómez',
            position: 'Catedrático de Informática',
            company: 'UPM Madrid',
            phone: '+34 91 336 60 00',
            email: 'mgomez@fi.upm.es',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'Arquitecto Principal',
            link: 'github.com/carlos/cv-ai',
            date: '2025 - 2026',
            description: 'Motor PDF offline y aplicación generadora de currículums con IA en el dispositivo.',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: 'Premios y Logros',
            items: [
              '1er Lugar - Concurso Nacional de Innovación en Software (2019)',
              'Premio Mejor Diseño UI/UX - Hackathon Móvil Europeo (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 5. PORTUGUÊS (PORTEKİZCE - BR & PT)
    if (lang.startsWith('pt')) {
      return CvModel(
        id: '1',
        fullName: 'Lucas Silva',
        jobTitle: 'Engenheiro de Software Mobile Sênior',
        email: 'lucas.silva@email.com.br',
        phone: '+55 (11) 98765-4321',
        location: 'São Paulo, Brasil',
        summary:
            'Engenheiro de software com mais de 6 anos de experiência no desenvolvimento de aplicativos móveis corporativos de alta performance com Flutter, Swift e Kotlin. Especialista em arquitetura escalável e UI/UX.',
        linkedin: 'linkedin.com/in/lucassilva',
        github: 'github.com/lucassilva',
        portfolioUrl: 'lucassilva.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global Ltda',
            position: 'Líder Técnico Mobile',
            startDate: '2022',
            endDate: 'Atual',
            isCurrent: true,
            description:
                'Liderança técnica em app fintech com mais de 3 milhões de usuários ativos. Otimização de tempo de inicialização em 40% e implantação de CI/CD.',
          ),
          WorkExperience(
            company: 'SoftStudio Brasil',
            position: 'Desenvolvedor Mobile',
            startDate: '2019',
            endDate: '2022',
            description:
                'Construção e publicação de mais de 10 aplicativos no App Store e Google Play com integração de APIs REST e autenticação biométrica.',
          ),
        ],
        educations: [
          Education(
            school: 'Universidade de São Paulo (USP)',
            degree: 'Bacharelado em Ciência da Computação',
            field: 'Engenharia de Software',
            startDate: '2015',
            endDate: '2019',
            gpa: '8.9 / 10',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'Especialista (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'Avançado (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'Avançado (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'Especialista (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: 'Avançado (%85)'),
          SkillItem(name: 'Design UI/UX', level: 75, levelLabel: 'Competente (%75)'),
        ],
        personalTraits: [
          'Resolução de Problemas & Análise',
          'Trabalho em Equipe & Liderança Ágil',
          'Aprendizado Rápido & Adaptação',
          'Gestão de Tempo & Prioridades',
          'Foco em Resultados & Inovação',
          'Comunicação Clara & Apresentação',
        ],
        languages: [
          LanguageItem(language: 'Português', level: 'Nativo'),
          LanguageItem(language: 'Inglês', level: 'C1 - Avançado / Fluente'),
          LanguageItem(language: 'Espanhol', level: 'B1 - Intermediário'),
        ],
        references: [
          ReferenceItem(
            name: 'Prof. Dr. Roberto Almeida',
            position: 'Coordenador de Computação',
            company: 'USP São Paulo',
            phone: '+55 11 3091-3116',
            email: 'almeida@ime.usp.br',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'Arquiteto Principal',
            link: 'github.com/lucas/cv-ai',
            date: '2025 - 2026',
            description: 'Motor PDF offline e criador inteligente de currículos com IA no dispositivo.',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: 'Prêmios & Conquistas',
            items: [
              '1º Lugar - Desafio Nacional de Inovação em Software (2019)',
              'Melhor Design UI/UX - Hackathon Mobile Brasil (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 6. ITALIANO (İTALYANCA)
    if (lang.startsWith('it')) {
      return CvModel(
        id: '1',
        fullName: 'Marco Rossi',
        jobTitle: 'Ingegnere del Software Mobile Senior',
        email: 'marco.rossi@email.it',
        phone: '+39 02 1234567',
        location: 'Milano, Italia',
        summary:
            'Ingegnere del software con oltre 6 anni di esperienza nello sviluppo di app mobili scalabili e ad alte prestazioni con Flutter, Swift e Kotlin. Forte orientamento all\'architettura pulita e al design.',
        linkedin: 'linkedin.com/in/marcorossi',
        github: 'github.com/marcorossi',
        portfolioUrl: 'marcorossi.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global Srl',
            position: 'Lead Mobile Developer',
            startDate: '2022',
            endDate: 'Presente',
            isCurrent: true,
            description:
                'Guida tecnica per app fintech ed e-commerce con oltre 3 milioni di utenti attivi. Riduzione del 40% dei tempi di avvio e pipeline CI/CD.',
          ),
          WorkExperience(
            company: 'SoftStudio Milano',
            position: 'Sviluppatore Mobile',
            startDate: '2019',
            endDate: '2022',
            description:
                'Sviluppo e rilascio di oltre 10 applicazioni native e cross-platform su App Store e Google Play Store.',
          ),
        ],
        educations: [
          Education(
            school: 'Politecnico di Milano',
            degree: 'Laurea Magistrale',
            field: 'Ingegneria Informatica',
            startDate: '2015',
            endDate: '2019',
            gpa: '110/110 con Lode',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'Esperto (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'Avanzato (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'Avanzato (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'Esperto (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: 'Avanzato (%85)'),
          SkillItem(name: 'Design UI/UX', level: 75, levelLabel: 'Competente (%75)'),
        ],
        personalTraits: [
          'Problem Solving & Pensiero Analitico',
          'Lavoro di Squadra & Leadership Agile',
          'Apprendimento Rapido & Adattabilità',
          'Gestione del Tempo & Priorità',
          'Orientamento ai Risultati & Innovazione',
          'Comunicazione Efficace & Presentazione',
        ],
        languages: [
          LanguageItem(language: 'Italiano', level: 'Madrelingua'),
          LanguageItem(language: 'Inglese', level: 'C1 - Fluente / Professionale'),
          LanguageItem(language: 'Francese', level: 'B1 - Intermedio'),
        ],
        references: [
          ReferenceItem(
            name: 'Prof. Giuseppe Conti',
            position: 'Direttore di Dipartimento',
            company: 'Politecnico di Milano',
            phone: '+39 02 2399 1',
            email: 'conti@polimi.it',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'Architetto Principale',
            link: 'github.com/marco/cv-ai',
            date: '2025 - 2026',
            description: 'Motore PDF offline e generatore di curriculum con IA on-device.',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: 'Premi & Riconoscimenti',
            items: [
              '1° Posto - Premio Nazionale per l\'Innovazione Software (2019)',
              'Miglior UI/UX Design - Hackathon Mobile Italiano (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 7. NEDERLANDS (FELEMENKÇE)
    if (lang.startsWith('nl')) {
      return CvModel(
        id: '1',
        fullName: 'Daan van Dijk',
        jobTitle: 'Senior Mobiele Softwareontwikkelaar',
        email: 'daan.vandijk@email.nl',
        phone: '+31 20 123 4567',
        location: 'Amsterdam, Nederland',
        summary:
            'Gepassioneerde Senior Mobile Engineer met 6+ jaar ervaring in het ontwikkelen van hoogwaardige apps met Flutter, Swift en Kotlin. Bewezen staat van dienst in schaalbare architectuur.',
        linkedin: 'linkedin.com/in/daanvandijk',
        github: 'github.com/daanvandijk',
        portfolioUrl: 'daanvandijk.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global BV',
            position: 'Lead Mobile Developer',
            startDate: '2022',
            endDate: 'Heden',
            isCurrent: true,
            description:
                'Leiding aan het mobiele ontwikkelteam voor apps met 3M+ gebruikers. Opstarttijd met 40% geoptimaliseerd.',
          ),
          WorkExperience(
            company: 'SoftStudio Amsterdam',
            position: 'Mobiel Ontwikkelaar',
            startDate: '2019',
            endDate: '2022',
            description:
                '10+ apps gebouwd en gepubliceerd in de App Store en Google Play met biometrische beveiliging.',
          ),
        ],
        educations: [
          Education(
            school: 'Universiteit van Amsterdam (UvA)',
            degree: 'Master of Science',
            field: 'Informatica & Software Engineering',
            startDate: '2015',
            endDate: '2019',
            gpa: '8.7 / 10 (Cum Laude)',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'Expert (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'Gevorderd (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'Gevorderd (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'Expert (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: 'Gevorderd (%85)'),
          SkillItem(name: 'UI/UX Design', level: 75, levelLabel: 'Vaardig (%75)'),
        ],
        personalTraits: [
          'Probleemoplossend Vermogen & Analyse',
          'Teamwerk & Agile Leiderschap',
          'Snel Lerend & Hoge Aanpasbaarheid',
          'Tijd- en Prioriteitenbeheer',
          'Resultaatgericht & Innovatief',
          'Effectieve Communicatie & Presentatie',
        ],
        languages: [
          LanguageItem(language: 'Nederlands', level: 'Moedertaal'),
          LanguageItem(language: 'Engels', level: 'C1 - Vloeiend / Professioneel'),
          LanguageItem(language: 'Duits', level: 'B2 - Goed'),
        ],
        references: [
          ReferenceItem(
            name: 'Prof. Dr. Jan de Vries',
            position: 'Hoogleraar Informatica',
            company: 'Universiteit van Amsterdam',
            phone: '+31 20 525 9111',
            email: 'j.devries@uva.nl',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'Hoofdarchitect',
            link: 'github.com/daan/cv-ai',
            date: '2025 - 2026',
            description: 'On-device PDF engine en AI-gedreven CV maker app.',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: 'Onderscheidingen & Prijzen',
            items: [
              '1e Prijs - Nationale Software Innovatie Award (2019)',
              'Beste UI/UX Design - Dutch Mobile Hackathon (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 8. POLSKI (LEHÇE)
    if (lang.startsWith('pl')) {
      return CvModel(
        id: '1',
        fullName: 'Jakub Kowalski',
        jobTitle: 'Starszy Programista Aplikacji Mobilnych',
        email: 'jakub.kowalski@email.pl',
        phone: '+48 22 123 45 67',
        location: 'Warszawa, Polska',
        summary:
            'Doświadczony inżynier oprogramowania mobilnego z ponad 6-letnim stażem w tworzeniu aplikacji Flutter, Swift i Kotlin. Ekspert w dziedzinie czystej architektury i optymalizacji.',
        linkedin: 'linkedin.com/in/jakubkowalski',
        github: 'github.com/jakubkowalski',
        portfolioUrl: 'jakubkowalski.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global Sp. z o.o.',
            position: 'Główny Programista Mobile',
            startDate: '2022',
            endDate: 'Obecnie',
            isCurrent: true,
            description:
                'Kierowanie zespołem mobile dla aplikacji fintech z ponad 3 mln aktywnych użytkowników. Skrócenie czasu uruchamiania o 40%.',
          ),
          WorkExperience(
            company: 'SoftStudio Warszawa',
            position: 'Programista Aplikacji Mobilnych',
            startDate: '2019',
            endDate: '2022',
            description:
                'Stworzenie i publikacja ponad 10 aplikacji w App Store i Google Play z integracją REST API i biometrii.',
          ),
        ],
        educations: [
          Education(
            school: 'Politechnika Warszawska',
            degree: 'Magister Inżynier',
            field: 'Informatyka',
            startDate: '2015',
            endDate: '2019',
            gpa: '4.9 / 5.0 (Bardzo Dobry)',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'Ekspert (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'Zaawansowany (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'Zaawansowany (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'Ekspert (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: 'Zaawansowany (%85)'),
          SkillItem(name: 'Projektowanie UI/UX', level: 75, levelLabel: 'Średnio-zaawansowany (%75)'),
        ],
        personalTraits: [
          'Rozwiązywanie Problemów & Analityka',
          'Praca Zespołowa & Zwinne Przywództwo',
          'Szybka Nauka & Wysoka Adaptacja',
          'Zarządzanie Czasem & Priorytetami',
          'Innowacyjność & Orientacja na Cel',
          'Efektywna Komunikacja & Prezentacja',
        ],
        languages: [
          LanguageItem(language: 'Polski', level: 'Ojczysty'),
          LanguageItem(language: 'Angielski', level: 'C1 - Zaawansowany / Płynny'),
          LanguageItem(language: 'Niemiecki', level: 'B1 - Średniozaawansowany'),
        ],
        references: [
          ReferenceItem(
            name: 'Prof. dr hab. inż. Piotr Wiśniewski',
            position: 'Dziekan Wydziału Informatyki',
            company: 'Politechnika Warszawska',
            phone: '+48 22 234 72 00',
            email: 'p.wisniewski@pw.edu.pl',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'Główny Architekt',
            link: 'github.com/jakub/cv-ai',
            date: '2025 - 2026',
            description: 'Lokalny silnik PDF i inteligentny kreator CV z wbudowaną sztuczną inteligencją.',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: 'Nagrody i Wyróżnienia',
            items: [
              '1. Miejsce - Ogólnopolski Konkurs Innowacji w Oprogramowaniu (2019)',
              'Najlepszy Design UI/UX - Hackathon Mobile Poland (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 9. РУССКИЙ (RUSÇA)
    if (lang.startsWith('ru')) {
      return CvModel(
        id: '1',
        fullName: 'Александр Смирнов',
        jobTitle: 'Ведущий разработчик мобильных приложений',
        email: 'alexander.smirnov@email.ru',
        phone: '+7 (495) 123-45-67',
        location: 'Москва, Россия',
        summary:
            'Опытный Senior Mobile Engineer с более чем 6-летним стажем разработки высоконагруженных мобильных приложений на Flutter, Swift и Kotlin. Эксперт в масштабируемой архитектуре и UI/UX.',
        linkedin: 'linkedin.com/in/alexandersmirnov',
        github: 'github.com/alexandersmirnov',
        portfolioUrl: 'alexandersmirnov.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global',
            position: 'Lead Mobile Developer',
            startDate: '2022',
            endDate: 'По наст. время',
            isCurrent: true,
            description:
                'Руководство разработкой финтех и e-commerce приложений с более чем 3 млн активных пользователей. Ускорение холодного старта на 40%.',
          ),
          WorkExperience(
            company: 'SoftStudio',
            position: 'Mobile Developer',
            startDate: '2019',
            endDate: '2022',
            description:
                'Разработка и выпуск более 10 кроссплатформенных и нативных приложений в App Store и Google Play с интеграцией биометрии.',
          ),
        ],
        educations: [
          Education(
            school: 'МГУ им. М.В. Ломоносова',
            degree: 'Магистр',
            field: 'Фундаментальная информатика и ИТ',
            startDate: '2015',
            endDate: '2019',
            gpa: '4.95 / 5.0 (Диплом с отличием)',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'Эксперт (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'Продвинутый (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'Продвинутый (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'Эксперт (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: 'Продвинутый (%85)'),
          SkillItem(name: 'UI/UX Дизайн', level: 75, levelLabel: 'Хороший (%75)'),
        ],
        personalTraits: [
          'Аналитическое мышление и решение задач',
          'Командная работа и Agile-лидерство',
          'Быстрая обучаемость и адаптивность',
          'Управление временем и приоритетами',
          'Ориентация на результат и инновации',
          'Эффективная коммуникация и презентации',
        ],
        languages: [
          LanguageItem(language: 'Русский', level: 'Родной язык'),
          LanguageItem(language: 'Английский', level: 'C1 - Свободный / Профессиональный'),
          LanguageItem(language: 'Немецкий', level: 'B1 - Средний'),
        ],
        references: [
          ReferenceItem(
            name: 'Проф. Д.Н. Иванов',
            position: 'Заведующий кафедрой ВМК',
            company: 'МГУ им. М.В. Ломоносова',
            phone: '+7 (495) 939-10-00',
            email: 'ivanov@cs.msu.ru',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'Главный архитектор',
            link: 'github.com/alex/cv-ai',
            date: '2025 - 2026',
            description: 'Автономный генератор резюме и локальный PDF-движок со встроенным искусственным интеллектом.',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: 'Награды и достижения',
            items: [
              '1 место - Всероссийский конкурс инноваций в ПО (2019)',
              'Лучший UI/UX дизайн - Международный мобильный хакатон (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 10. العربية (ARAPÇA)
    if (lang.startsWith('ar')) {
      return CvModel(
        id: '1',
        fullName: 'أحمد المنصوري',
        jobTitle: 'مهندس برمجيات وتطبيقات الهاتف الأول',
        email: 'ahmed.almansoori@email.ae',
        phone: '+971 50 123 4567',
        location: 'دبي، الإمارات العربية المتحدة',
        summary:
            'مهندس برمجيات خبير يتمتع بخبرة تزيد عن 6 سنوات في تطوير تطبيقات الهواتف الذكية عالية الأداء باستخدام Flutter و Swift و Kotlin. سجل حافل بالبنية المعمارية القابلة للتوسع.',
        linkedin: 'linkedin.com/in/ahmedalmansoori',
        github: 'github.com/ahmed',
        portfolioUrl: 'ahmed.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global',
            position: 'قائد فريق تطوير الهواتف المحمولة',
            startDate: '2022',
            endDate: 'حتى الآن',
            isCurrent: true,
            description:
                'قيادة الهندسة المعمارية لتطبيقات التكنولوجيا المالية والتجارة الإلكترونية مع أكثر من 3 ملايين مستخدم نشط.',
          ),
          WorkExperience(
            company: 'SoftStudio Dubai',
            position: 'مطور تطبيقات الهواتف المحمولة',
            startDate: '2019',
            endDate: '2022',
            description:
                'تطوير ونشر أكثر من 10 تطبيقات على App Store و Google Play مع دمج المصادقة البيومترية وواجهات برمجة التطبيقات.',
          ),
        ],
        educations: [
          Education(
            school: 'جامعة خليفة للعلوم والتكنولوجيا',
            degree: 'بكالوريوس العلوم',
            field: 'هندسة الحاسوب والبرمجيات',
            startDate: '2015',
            endDate: '2019',
            gpa: '3.92 / 4.00 (امتياز مع مرتبة الشرف)',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'خبير (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'متقدم (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'متقدم (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'خبير (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: 'متقدم (%85)'),
          SkillItem(name: 'تصميم UI/UX', level: 75, levelLabel: 'كفء (%75)'),
        ],
        personalTraits: [
          'حل المشكلات والتفكير التحليلي',
          'العمل الجماعي والقيادة المرنة (Agile)',
          'سرعة التعلم والقدرة العالية على التكيف',
          'إدارة الوقت والأولويات بكفاءة',
          'الابتكار والتركيز على النتائج',
          'التواصل الفعال ومهارات العرض',
        ],
        languages: [
          LanguageItem(language: 'العربية', level: 'اللغة الأم'),
          LanguageItem(language: 'الإنجليزية', level: 'C1 - طلاقة واحترافية'),
          LanguageItem(language: 'الفرنسية', level: 'B1 - متوسط'),
        ],
        references: [
          ReferenceItem(
            name: 'د. خالد القاسمي',
            position: 'رئيس قسم هندسة الحاسوب',
            company: 'جامعة خليفة',
            phone: '+971 2 404 0000',
            email: 'k.alQasimi@ku.ac.ae',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'كبير المهندسين المعماريين',
            link: 'github.com/ahmed/cv-ai',
            date: '2025 - 2026',
            description: 'محرك PDF وتطبيق ذكي لإنشاء السير الذاتية بالذكاء الاصطناعي على الجهاز.',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: 'الجوائز والإنجازات',
            items: [
              'المركز الأول - مسابقة الابتكار في البرمجيات (2019)',
              'جائزة أفضل تصميم UI/UX - هاكاثون الشرق الأوسط للتطبيقات (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 11. हिन्दी (HİNTÇE)
    if (lang.startsWith('hi')) {
      return CvModel(
        id: '1',
        fullName: 'राहुल शर्मा',
        jobTitle: 'सीनियर मोबाइल सॉफ्टवेयर इंजीनियर',
        email: 'rahul.sharma@email.in',
        phone: '+91 98765 43210',
        location: 'बेंगलुरु, भारत',
        summary:
            'Flutter, Swift और Kotlin के साथ उच्च-प्रदर्शन मोबाइल एप्लिकेशन बनाने में 6+ वर्षों के अनुभव वाले अनुभवी सॉफ्टवेयर इंजीनियर। मापनीय आर्किटेक्चर और आधुनिक UI/UX में विशेषज्ञ।',
        linkedin: 'linkedin.com/in/rahulsharma',
        github: 'github.com/rahulsharma',
        portfolioUrl: 'rahulsharma.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global India',
            position: 'लीड मोबाइल डेवलपर',
            startDate: '2022',
            endDate: 'वर्तमान',
            isCurrent: true,
            description:
                '30 लाख से अधिक सक्रिय उपयोगकर्ताओं वाले फिनटेक ऐप की मोबाइल इंजीनियरिंग का नेतृत्व किया। ऐप लॉन्च समय को 40% कम किया।',
          ),
          WorkExperience(
            company: 'SoftStudio Bengaluru',
            position: 'मोबाइल एप्लिकेशन डेवलपर',
            startDate: '2019',
            endDate: '2022',
            description:
                'App Store और Google Play पर बायोमेट्रिक प्रमाणीकरण के साथ 10+ सफल एप्लिकेशन प्रकाशित किए।',
          ),
        ],
        educations: [
          Education(
            school: 'आईआईटी दिल्ली (IIT Delhi)',
            degree: 'बैचलर ऑफ टेक्नोलॉजी (B.Tech)',
            field: 'कंप्यूटर साइंस एंड इंजीनियरिंग',
            startDate: '2015',
            endDate: '2019',
            gpa: '9.4 / 10',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'विशेषज्ञ (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'उन्नत (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'उन्नत (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'विशेषज्ञ (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: 'उन्नत (%85)'),
          SkillItem(name: 'UI/UX Design', level: 75, levelLabel: 'कुशल (%75)'),
        ],
        personalTraits: [
          'समस्या समाधान और विश्लेषणात्मक सोच',
          'टीमवर्क और एजाइल (Agile) नेतृत्व',
          'त्वरित सीखना और उच्च अनुकूलनशीलता',
          'समय और प्राथमिकता प्रबंधन',
          'नवाचार और परिणाम-उन्मुख दृष्टिकोण',
          'प्रभावी संचार और प्रस्तुति कौशल',
        ],
        languages: [
          LanguageItem(language: 'हिन्दी', level: 'मातृभाषा'),
          LanguageItem(language: 'अंग्रेजी', level: 'C1 - धाराप्रवाह / व्यावसायिक'),
          LanguageItem(language: 'जर्मन', level: 'B1 - मध्यम'),
        ],
        references: [
          ReferenceItem(
            name: 'प्रो. राजेश वर्मा',
            position: 'विभागाध्यक्ष, कंप्यूटर साइंस',
            company: 'IIT Delhi',
            phone: '+91 11 2659 1000',
            email: 'rverma@cse.iitd.ac.in',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'प्रमुख आर्किटेक्ट',
            link: 'github.com/rahul/cv-ai',
            date: '2025 - 2026',
            description: 'डिवाइस पर आधारित पीडीएफ इंजन और एआई संचालित सीवी जनरेटर ऐप।',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: 'सम्मान और पुरस्कार',
            items: [
              'प्रथम स्थान - राष्ट्रीय सॉफ्टवेयर इनोवेशन चैलेंज (2019)',
              'सर्वश्रेष्ठ UI/UX डिज़ाइन - इंडिया मोबाइल हैकथॉन (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 12. 简体中文 (ÇİNCE)
    if (lang.startsWith('zh')) {
      return CvModel(
        id: '1',
        fullName: '张伟',
        jobTitle: '高级移动端软件开发工程师',
        email: 'zhang.wei@email.cn',
        phone: '+86 138 0013 8000',
        location: '上海，中国',
        summary:
            '拥有6年以上大型移动应用架构与开发经验的资深工程师，精通Flutter、Swift及Kotlin，擅长高性能系统调优、模块化架构与现代化UI/UX构建。',
        linkedin: 'linkedin.com/in/zhangwei',
        github: 'github.com/zhangwei',
        portfolioUrl: 'zhangwei.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global 中国',
            position: '移动端技术负责人 (Lead Developer)',
            startDate: '2022',
            endDate: '至今',
            isCurrent: true,
            description:
                '主导服务超过300万活跃用户的金融与电商移动架构，优化冷启动时间达40%，搭建完善的自动化CI/CD流程。',
          ),
          WorkExperience(
            company: 'SoftStudio 上海',
            position: '移动端开发工程师',
            startDate: '2019',
            endDate: '2022',
            description:
                '在App Store与Google Play上线10余款企业级应用，集成生物识别、离线安全加密与REST/GraphQL API。',
          ),
        ],
        educations: [
          Education(
            school: '上海交通大学',
            degree: '工学学士',
            field: '计算机科学与技术',
            startDate: '2015',
            endDate: '2019',
            gpa: '3.89 / 4.00 (优秀毕业生)',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: '精通 (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: '高级 (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: '高级 (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: '精通 (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: '高级 (%85)'),
          SkillItem(name: 'UI/UX 设计', level: 75, levelLabel: '熟练 (%75)'),
        ],
        personalTraits: [
          '逻辑严谨与卓越的问题解决能力',
          '团队协作与敏捷 (Agile) 领导力',
          '快速学习与高环境适应力',
          '高效的时间与优先级管理',
          '创新思维与结果导向',
          '出色的跨部门沟通与汇报能力',
        ],
        languages: [
          LanguageItem(language: '中文 (普通话)', level: '母语'),
          LanguageItem(language: '英语', level: 'C1 - 流利 / 商务工作语言'),
          LanguageItem(language: '日语', level: 'N2 - 熟练'),
        ],
        references: [
          ReferenceItem(
            name: '李明 教授',
            position: '计算机系系主任',
            company: '上海交通大学',
            phone: '+86 21 3420 0000',
            email: 'ming.li@sjtu.edu.cn',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: '首席架构师',
            link: 'github.com/zhangwei/cv-ai',
            date: '2025 - 2026',
            description: '基于端侧AI的智能简历生成器与高性能离线PDF排版引擎。',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: '荣誉与奖项',
            items: [
              '全国高校软件创新大赛一等奖 (2019)',
              '国际移动开发者黑客松最佳UI/UX设计奖 (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 13. 日本語 (JAPONCA)
    if (lang.startsWith('ja')) {
      return CvModel(
        id: '1',
        fullName: '佐藤 健',
        jobTitle: 'シニアモバイルソフトウェアエンジニア',
        email: 'ken.sato@email.jp',
        phone: '+81 90 1234 5678',
        location: '東京都、日本',
        summary:
            'Flutter、Swift、Kotlinを用いたエンタープライズ規模のモバイルアプリ開発において6年以上の実績を持つシニアエンジニア。高いパフォーマンスと美しいUI/UXの設計に強み。',
        linkedin: 'linkedin.com/in/kensato',
        github: 'github.com/kensato',
        portfolioUrl: 'kensato.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global Japan',
            position: 'リードモバイルエンジニア',
            startDate: '2022',
            endDate: '現在',
            isCurrent: true,
            description:
                '月間300万人以上のアクティブユーザーを誇るフィンテックアプリの開発をリード。起動時間を40%短縮しCI/CDを整備。',
          ),
          WorkExperience(
            company: 'SoftStudio 東京',
            position: 'モバイルアプリエンジニア',
            startDate: '2019',
            endDate: '2022',
            description:
                'App StoreおよびGoogle Playにて10件以上の高品質ネイティブ・クロスプラットフォームアプリをリリース。',
          ),
        ],
        educations: [
          Education(
            school: '東京大学',
            degree: '学士（工学）',
            field: '情報理工学',
            startDate: '2015',
            endDate: '2019',
            gpa: '3.86 / 4.00',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'エキスパート (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: '上級 (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: '上級 (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'エキスパート (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: '上級 (%85)'),
          SkillItem(name: 'UI/UX デザイン', level: 75, levelLabel: '実務レベル (%75)'),
        ],
        personalTraits: [
          '問題解決力・論理的思考力',
          'チームワークとアジャイルリーダーシップ',
          '高い学習速度と柔軟な適応力',
          '時間管理と優先順位の最適化',
          '成果重視とイノベーション志向',
          '円滑なコミュニケーションと発表能力',
        ],
        languages: [
          LanguageItem(language: '日本語', level: '母国語'),
          LanguageItem(language: '英語', level: 'C1 - ビジネス流暢レベル'),
          LanguageItem(language: '中国語', level: '日常会話レベル'),
        ],
        references: [
          ReferenceItem(
            name: '田中 健一 教授',
            position: '情報工学専攻 教授',
            company: '東京大学 大学院',
            phone: '+81 3 5841 6000',
            email: 'tanaka@is.u-tokyo.ac.jp',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'リードアーキテクト',
            link: 'github.com/ken/cv-ai',
            date: '2025 - 2026',
            description: 'オンデバイスAIによるスマート履歴書作成アプリおよびPDF描画エンジン。',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: '受賞歴・実績',
            items: [
              '全国ソフトウェア開発イノベーション大賞 第1位 (2019)',
              '最優秀UI/UXデザイン賞 - 国際モバイルハッカソン (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 14. 한국어 (KORECE)
    if (lang.startsWith('ko')) {
      return CvModel(
        id: '1',
        fullName: '김민수',
        jobTitle: '수석 모바일 소프트웨어 엔지니어',
        email: 'minsu.kim@email.kr',
        phone: '+82 10-1234-5678',
        location: '서울특별시, 대한민국',
        summary:
            'Flutter, Swift, Kotlin 기반의 대규모 엔터프라이즈 모바일 서비스 구축에 6년 이상의 경력을 보유한 수석 엔지니어입니다. 고성능 아키텍처 및 직관적인 UI/UX 설계에 전문성이 있습니다.',
        linkedin: 'linkedin.com/in/minsukim',
        github: 'github.com/minsukim',
        portfolioUrl: 'minsukim.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global Korea',
            position: '모바일 리드 개발자',
            startDate: '2022',
            endDate: '현재',
            isCurrent: true,
            description:
                '300만 이상의 활성 사용자를 보유한 핀테크 및 이커머스 모바일 아키텍처 총괄. 앱 초기 구동 속도 40% 개선 및 CI/CD 구축.',
          ),
          WorkExperience(
            company: 'SoftStudio 서울',
            position: '모바일 개발자',
            startDate: '2019',
            endDate: '2022',
            description:
                'App Store 및 Google Play에 10개 이상의 고품질 크로스플랫폼/네이티브 앱 출시 및 생체 인증 연동.',
          ),
        ],
        educations: [
          Education(
            school: '서울대학교 (SNU)',
            degree: '공학사',
            field: '컴퓨터공학부',
            startDate: '2015',
            endDate: '2019',
            gpa: '3.91 / 4.30 (우등 졸업)',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: '전문가 (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: '고급 (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: '고급 (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: '전문가 (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: '고급 (%85)'),
          SkillItem(name: 'UI/UX 디자인', level: 75, levelLabel: '능숙 (%75)'),
        ],
        personalTraits: [
          '분석적 사고 및 뛰어난 문제 해결력',
          '팀워크 및 애자일(Agile) 리더십',
          '빠른 학습 능력과 뛰어난 적응력',
          '시간 및 우선순위 관리 능력',
          '혁신 지향 및 결과 중심 태도',
          '효과적인 커뮤니케이션과 발표력',
        ],
        languages: [
          LanguageItem(language: '한국어', level: '모국어'),
          LanguageItem(language: '영어', level: 'C1 - 유창함 / 비즈니스 수준'),
          LanguageItem(language: '일본어', level: 'B1 - 중급 회화'),
        ],
        references: [
          ReferenceItem(
            name: '박성호 교수',
            position: '컴퓨터공학부 학과장',
            company: '서울대학교',
            phone: '+82 2-880-1234',
            email: 'shpark@snu.ac.kr',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: '수석 아키텍트',
            link: 'github.com/minsu/cv-ai',
            date: '2025 - 2026',
            description: '온디바이스 AI 기반 이력서 생성 및 고성능 PDF 렌더링 엔진 개발.',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: '수상 및 성과',
            items: [
              '전국 소프트웨어 혁신 챌린지 대상 (2019)',
              '최우수 UI/UX 디자인상 - 인터내셔널 모바일 해커톤 (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 15. BAHASA INDONESIA (ENDONEZCE)
    if (lang.startsWith('id')) {
      return CvModel(
        id: '1',
        fullName: 'Budi Santoso',
        jobTitle: 'Senior Mobile Software Engineer',
        email: 'budi.santoso@email.co.id',
        phone: '+62 812 3456 7890',
        location: 'Jakarta, Indonesia',
        summary:
            'Software engineer berpengalaman lebih dari 6 tahun dalam membangun aplikasi mobile berskala besar dengan Flutter, Swift, dan Kotlin. Berpengalaman tinggi dalam arsitektur sistem dan optimasi performa.',
        linkedin: 'linkedin.com/in/budisantoso',
        github: 'github.com/budisantoso',
        portfolioUrl: 'budisantoso.dev',
        hasPhoto: true,
        profilePhoto: 'avatar_1',
        experiences: [
          WorkExperience(
            company: 'TechVentures Global Indonesia',
            position: 'Lead Mobile Developer',
            startDate: '2022',
            endDate: 'Sekarang',
            isCurrent: true,
            description:
                'Memimpin pengembangan aplikasi fintech dan e-commerce dengan 3 juta lebih pengguna aktif. Mengoptimalkan waktu startup sebesar 40%.',
          ),
          WorkExperience(
            company: 'SoftStudio Jakarta',
            position: 'Mobile Developer',
            startDate: '2019',
            endDate: '2022',
            description:
                'Membangun dan merilis 10+ aplikasi di App Store dan Google Play dengan autentikasi biometrik dan REST API.',
          ),
        ],
        educations: [
          Education(
            school: 'Universitas Indonesia (UI)',
            degree: 'Sarjana Ilmu Komputer (S.Kom)',
            field: 'Teknik Informatika',
            startDate: '2015',
            endDate: '2019',
            gpa: '3.88 / 4.00 (Cum Laude)',
          ),
        ],
        skills: [
          SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'Pakar (%95)'),
          SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'Tingkat Lanjut (%85)'),
          SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'Tingkat Lanjut (%80)'),
          SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'Pakar (%90)'),
          SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: 'Tingkat Lanjut (%85)'),
          SkillItem(name: 'Desain UI/UX', level: 75, levelLabel: 'Terampil (%75)'),
        ],
        personalTraits: [
          'Pemecahan Masalah & Berpikir Analitis',
          'Kerja Sama Tim & Kepemimpinan Agile',
          'Cepat Belajar & Adaptasi Tinggi',
          'Manajemen Waktu & Prioritas',
          'Berorientasi Hasil & Inovatif',
          'Komunikasi Efektif & Presentasi',
        ],
        languages: [
          LanguageItem(language: 'Bahasa Indonesia', level: 'Bahasa Ibu'),
          LanguageItem(language: 'Bahasa Inggris', level: 'C1 - Fasih / Profesional'),
          LanguageItem(language: 'Bahasa Mandarin', level: 'B1 - Menengah'),
        ],
        references: [
          ReferenceItem(
            name: 'Prof. Dr. Hendra Gunawan',
            position: 'Ketua Departemen Ilmu Komputer',
            company: 'Universitas Indonesia',
            phone: '+62 21 786 3419',
            email: 'hgunawan@cs.ui.ac.id',
          ),
        ],
        projects: [
          ProjectItem(
            name: 'CV AI Pro Suite',
            role: 'Lead Architect',
            link: 'github.com/budi/cv-ai',
            date: '2025 - 2026',
            description: 'Mesin PDF mandiri dan pembuat CV cerdas berbasis AI pada perangkat.',
            technologies: 'Flutter, Dart, CorePDF, On-Device AI',
          ),
        ],
        certificates: [],
        customSections: [
          CustomCvSection(
            id: 'awards',
            title: 'Penghargaan & Prestasi',
            items: [
              'Juara 1 - Kompetisi Inovasi Perangkat Lunak Nasional (2019)',
              'Desain UI/UX Terbaik - Hackathon Mobile Regional (2022)',
            ],
          ),
        ],
        template: CvTemplate.sidebarModern,
        primaryColorHex: 0xFF2563EB,
      );
    }

    // 16. DEFAULT: ENGLISH (US / UK / GLOBAL)
    return CvModel(
      id: '1',
      fullName: 'Alex Morgan',
      jobTitle: 'Senior Mobile Software Engineer',
      email: 'alex.morgan@email.com',
      phone: '+1 (415) 555-0192',
      location: 'San Francisco, CA, USA',
      summary:
          'Passionate Senior Mobile Software Engineer with 6+ years of expertise in building enterprise-grade, high-performance mobile applications with Flutter, Swift, and Kotlin. Proven track record in optimizing system performance and delivering scalable architecture.',
      linkedin: 'linkedin.com/in/alexmorgan',
      github: 'github.com/alexmorgan',
      portfolioUrl: 'alexmorgan.dev',
      hasPhoto: true,
      profilePhoto: 'avatar_1',
      experiences: [
        WorkExperience(
          company: 'TechVentures Global Inc.',
          position: 'Lead Mobile Developer',
          startDate: '2022',
          endDate: 'Present',
          isCurrent: true,
          description:
              'Architected and led mobile engineering for flagship fintech & e-commerce applications serving 3M+ active users. Improved cold startup time by 42% and introduced robust CI/CD pipelines.',
        ),
        WorkExperience(
          company: 'SoftStudio Inc.',
          position: 'Mobile Application Developer',
          startDate: '2019',
          endDate: '2022',
          description:
              'Built and published 10+ cross-platform and native client applications on the App Store and Google Play. Integrated secure biometric authentication and RESTful APIs.',
        ),
      ],
      educations: [
        Education(
          school: 'Stanford University',
          degree: 'Bachelor of Science',
          field: 'Computer Science',
          startDate: '2015',
          endDate: '2019',
          gpa: '3.88 / 4.00',
        ),
      ],
      skills: [
        SkillItem(name: 'Flutter & Dart', level: 95, levelLabel: 'Expert (%95)'),
        SkillItem(name: 'iOS & Swift', level: 85, levelLabel: 'Advanced (%85)'),
        SkillItem(name: 'Android & Kotlin', level: 80, levelLabel: 'Advanced (%80)'),
        SkillItem(name: 'REST & GraphQL', level: 90, levelLabel: 'Expert (%90)'),
        SkillItem(name: 'CI/CD & DevOps', level: 85, levelLabel: 'Advanced (%85)'),
        SkillItem(name: 'UI/UX Design', level: 75, levelLabel: 'Proficient (%75)'),
      ],
      personalTraits: [
        'Analytical Thinking & Problem Solving',
        'Team Leadership & Agile Collaboration',
        'Fast Learning & High Adaptability',
        'Time & Priority Management',
        'Innovative & Solution-Oriented',
        'Effective Communication & Presentation',
      ],
      languages: [
        LanguageItem(language: 'English', level: 'Native / Bilingual'),
        LanguageItem(language: 'German', level: 'C1 - Advanced'),
        LanguageItem(language: 'Spanish', level: 'B2 - Upper Intermediate'),
      ],
      references: [
        ReferenceItem(
          name: 'Prof. Robert Anderson',
          position: 'Department Chair',
          company: 'Stanford Computer Science',
          phone: '+1 (650) 723-2300',
          email: 'anderson@cs.stanford.edu',
        ),
      ],
      projects: [
        ProjectItem(
          name: 'CV AI Pro Suite',
          role: 'Lead Architect',
          link: 'github.com/alex/cv-ai',
          date: '2025 - 2026',
          description: 'On-device PDF engine and AI-assisted professional CV generator mobile application.',
          technologies: 'Flutter, Dart, CorePDF, On-Device AI',
        ),
      ],
      certificates: [],
      customSections: [
        CustomCvSection(
          id: 'awards',
          title: 'Honors & Awards',
          items: [
            '1st Place - Global Collegiate Software Innovation Challenge (2019)',
            'Best UI/UX Design Award - International Mobile Developers Hackathon (2022)',
          ],
        ),
      ],
      template: CvTemplate.sidebarModern,
      primaryColorHex: 0xFF2563EB,
    );
  }
}
