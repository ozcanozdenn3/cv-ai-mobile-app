import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cv_model.dart';
import '../models/document_model.dart';
import 'supabase_service.dart';
import 'localization_service.dart';

class CvStorageService {
  static const String _activeCvKey = 'cv_ai_active_cv_model';
  static const String _documentsListKey = 'cv_ai_saved_documents_list';

  /// Aktif CV'yi hem SharedPreferences'a hem de bağlıysa Supabase bulutuna kaydeder
  static Future<void> saveActiveCv(CvModel cv, {Uint8List? pdfBytes, Uint8List? photoBytes}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = _cvToMap(cv);
      final jsonStr = json.encode(map);
      await prefs.setString(_activeCvKey, jsonStr);

      // Supabase Bulut Senkronizasyonu
      if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
        SupabaseService.saveResume(cv, pdfBytes: pdfBytes, photoBytes: photoBytes);
      }
    } catch (e) {
      debugPrint('CvStorageService save error: $e');
    }
  }

  /// Kayıtlı aktif CV'yi çeker; yoksa aktif dile uygun varsayılan şablonu üretir
  static Future<CvModel> loadActiveCv() async {
    try {
      // Eğer Supabase bağlıysa buluttan çekmeyi dene
      if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
        final cloudCv = await SupabaseService.fetchActiveResume();
        if (cloudCv != null && !cloudCv.isSample) {
          // Yerel önbelleği güncelle
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_activeCvKey, json.encode(_cvToMap(cloudCv)));
          return cloudCv;
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_activeCvKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        final localCv = _cvFromMap(map);
        if (!localCv.isSample) {
          return localCv;
        }
      }
    } catch (e) {
      debugPrint('CvStorageService load error: $e');
    }

    return CvModel.createEmpty(LocalizationService.currentLocale);
  }

  /// Yeni üretilen belgeyi fiziksel diske ve arşive kaydeder (Yerel + Supabase)
  static Future<void> saveDocument(DocumentModel doc, {Uint8List? fileBytes}) async {
    try {
      DocumentModel docToSave = doc;

      if (fileBytes != null && fileBytes.isNotEmpty) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          final docsDir = Directory('${dir.path}/saved_documents');
          if (!await docsDir.exists()) {
            await docsDir.create(recursive: true);
          }
          final sanitizedTitle = doc.title.replaceAll(RegExp(r'[^\w\.-]'), '_');
          final targetFile = File('${docsDir.path}/${doc.id}_$sanitizedTitle');
          await targetFile.writeAsBytes(fileBytes, flush: true);
          docToSave = doc.copyWith(filePath: targetFile.path);
        } catch (fileErr) {
          debugPrint('Error saving physical document file: $fileErr');
        }
      }

      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_documentsListKey);
      final List<DocumentModel> docs = [];
      if (str != null && str.isNotEmpty) {
        try {
          final List<dynamic> list = json.decode(str) as List<dynamic>;
          docs.addAll(list.map((item) => _docFromMap(item as Map<String, dynamic>)));
        } catch (_) {}
      }

      docs.removeWhere((d) => d.id == docToSave.id);
      docs.insert(0, docToSave);
      final jsonList = docs.map((d) => _docToMap(d)).toList();
      await prefs.setString(_documentsListKey, json.encode(jsonList));

      // Supabase Bulut Senkronizasyonu
      if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
        SupabaseService.saveDocument(docToSave, fileBytes: fileBytes);
      }
    } catch (e) {
      debugPrint('Error saving document: $e');
    }
  }

  /// Arşivdeki tüm belgeleri yükler (Yerel fiziksel kayıtlar + Supabase bulut kayıtlarının akıllı birleşimi)
  static Future<List<DocumentModel>> loadDocuments() async {
    try {
      // 1. Önce yerel önbellekteki gerçek kullanıcı belgelerini çek (fiziksel dosya yollarını korur)
      final prefs = await SharedPreferences.getInstance();
      final str = prefs.getString(_documentsListKey);
      final List<DocumentModel> localDocs = [];
      if (str != null && str.isNotEmpty) {
        try {
          final List<dynamic> list = json.decode(str) as List<dynamic>;
          localDocs.addAll(list
              .map((item) => _docFromMap(item as Map<String, dynamic>))
              .where((d) => !const ['1', '2', '3', '4', '5'].contains(d.id)));
        } catch (e) {
          debugPrint('Error decoding local docs: $e');
        }
      }

      // 2. Supabase bağlı ve oturum varsa buluttan belgeleri çek ve yerel kayıtlarla birleştir
      if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
        try {
          final cloudDocs = await SupabaseService.fetchDocuments();
          if (cloudDocs.isNotEmpty) {
            final mergedMap = <String, DocumentModel>{};
            for (final cd in cloudDocs) {
              mergedMap[cd.id] = cd;
            }
            // Yerel kayıtlar fiziksel filePath taşıdığı için yerel bilgileri koru/ekle
            for (final ld in localDocs) {
              if (mergedMap.containsKey(ld.id)) {
                mergedMap[ld.id] = mergedMap[ld.id]!.copyWith(
                  filePath: ld.filePath ?? mergedMap[ld.id]!.filePath,
                  previewImage: ld.previewImage ?? mergedMap[ld.id]!.previewImage,
                );
              } else {
                mergedMap[ld.id] = ld;
              }
            }
            final result = mergedMap.values.toList();
            result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
            return result;
          }
        } catch (cloudErr) {
          debugPrint('Error fetching cloud docs: $cloudErr');
        }
      }

      localDocs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return localDocs;
    } catch (e) {
      debugPrint('Error loading documents: $e');
    }
    return [];
  }

  /// Belgenin gerçek fiziksel baytlarını güvenli ve dinamik olarak bulur ve okur
  static Future<Uint8List?> getDocumentBytes(DocumentModel doc) async {
    // 1. Önce doc.filePath'i doğrudan dene
    if (doc.filePath != null && doc.filePath!.isNotEmpty) {
      try {
        final file = File(doc.filePath!);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          if (bytes.isNotEmpty) return bytes;
        }
      } catch (e) {
        debugPrint('File direct read error: $e');
      }
    }

    // 2. iOS sandbox UUID değişimine karşı docsDir içinde doc.id ile başlayan dosyayı dinamik ara
    try {
      final dir = await getApplicationDocumentsDirectory();
      final docsDir = Directory('${dir.path}/saved_documents');
      if (await docsDir.exists()) {
        final entities = await docsDir.list().toList();
        for (final entity in entities) {
          if (entity is File && entity.path.contains(doc.id)) {
            final bytes = await entity.readAsBytes();
            if (bytes.isNotEmpty) return bytes;
          }
        }
      }
    } catch (e) {
      debugPrint('Dynamic sandbox scan error: $e');
    }

    // 3. Bulut URL varsa indir
    if (doc.fileUrl != null && doc.fileUrl!.isNotEmpty) {
      try {
        final res = await http.get(Uri.parse(doc.fileUrl!));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          return res.bodyBytes;
        }
      } catch (e) {
        debugPrint('Cloud download error: $e');
      }
    }

    return null;
  }

  /// Belgeyi arşivden ve telefonun fiziksel diskinden siler
  static Future<void> deleteDocument(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final docs = await loadDocuments();
      final targetDoc = docs.firstWhere(
        (d) => d.id == id,
        orElse: () => DocumentModel(
          id: '',
          title: '',
          type: DocumentType.cv,
          createdAt: DateTime.now(),
          pageCount: 0,
          fileSize: '',
        ),
      );

      if (targetDoc.filePath != null && targetDoc.filePath!.isNotEmpty) {
        try {
          final file = File(targetDoc.filePath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          debugPrint('Error deleting physical file: $e');
        }
      }

      docs.removeWhere((d) => d.id == id);
      final jsonList = docs.map((d) => _docToMap(d)).toList();
      await prefs.setString(_documentsListKey, json.encode(jsonList));

      // Supabase Bulut Silme
      if (SupabaseService.isInitialized && SupabaseService.isAuthenticated) {
        SupabaseService.deleteDocument(id);
      }
    } catch (e) {
      debugPrint('Error deleting document: $e');
    }
  }

  static Map<String, dynamic> _docToMap(DocumentModel doc) {
    return {
      'id': doc.id,
      'title': doc.title,
      'type': doc.type.name,
      'createdAt': doc.createdAt.toIso8601String(),
      'pageCount': doc.pageCount,
      'fileSize': doc.fileSize,
      'previewImage': doc.previewImage,
      'filePath': doc.filePath,
      'fileUrl': doc.fileUrl,
    };
  }

  static DocumentModel _docFromMap(Map<String, dynamic> map) {
    return DocumentModel(
      id: map['id'] as String? ?? 'doc_1',
      title: map['title'] as String? ?? '${LocalizationService.tr('default_converted_doc_title')}.pdf',
      type: DocumentType.values.firstWhere(
        (t) => t.name == map['type'],
        orElse: () => DocumentType.cv,
      ),
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      pageCount: map['pageCount'] as int? ?? 1,
      fileSize: map['fileSize'] as String? ?? '250 KB',
      previewImage: map['previewImage'] as String?,
      filePath: map['filePath'] as String?,
      fileUrl: map['fileUrl'] as String?,
    );
  }

  static Map<String, dynamic> _cvToMap(CvModel cv) {
    return {
      'id': cv.id,
      'fullName': cv.fullName,
      'jobTitle': cv.jobTitle,
      'email': cv.email,
      'phone': cv.phone,
      'location': cv.location,
      'summary': cv.summary,
      'linkedin': cv.linkedin,
      'github': cv.github,
      'portfolioUrl': cv.portfolioUrl,
      'hasPhoto': cv.hasPhoto,
      'profilePhotoBytes': cv.profilePhotoBytes != null ? base64Encode(cv.profilePhotoBytes!) : null,
      'primaryColorHex': cv.primaryColorHex,
      'template': cv.template.name,
      'targetLanguage': cv.targetLanguage,
      'personalTraits': cv.personalTraits,
      'experiences': cv.experiences
          .map((e) => {
                'company': e.company,
                'position': e.position,
                'startDate': e.startDate,
                'endDate': e.endDate,
                'isCurrent': e.isCurrent,
                'description': e.description,
              })
          .toList(),
      'educations': cv.educations
          .map((e) => {
                'school': e.school,
                'degree': e.degree,
                'field': e.field,
                'startDate': e.startDate,
                'endDate': e.endDate,
                'gpa': e.gpa,
              })
          .toList(),
      'skills': cv.skills
          .map((s) => {
                'name': s.name,
                'level': s.level,
                'levelLabel': s.levelLabel,
              })
          .toList(),
      'languages': cv.languages
          .map((l) => {
                'language': l.language,
                'level': l.level,
              })
          .toList(),
      'references': cv.references
          .map((r) => {
                'name': r.name,
                'position': r.position,
                'company': r.company,
                'phone': r.phone,
                'email': r.email,
              })
          .toList(),
      'projects': cv.projects
          .map((p) => {
                'name': p.name,
                'role': p.role,
                'link': p.link,
                'date': p.date,
                'description': p.description,
                'technologies': p.technologies,
              })
          .toList(),
      'certificates': cv.certificates
          .map((c) => {
                'name': c.name,
                'issuer': c.issuer,
                'date': c.date,
                'credentialUrl': c.credentialUrl,
              })
          .toList(),
      'sectionOrder': cv.sectionOrder.map((s) => s.name).toList(),
    };
  }

  static CvModel _cvFromMap(Map<String, dynamic> map) {
    Uint8List? photoBytes;
    if (map['profilePhotoBytes'] != null) {
      try {
        photoBytes = base64Decode(map['profilePhotoBytes'] as String);
      } catch (_) {}
    }

    final cv = CvModel(
      id: map['id'] as String? ?? 'cv_1',
      fullName: map['fullName'] as String? ?? '',
      jobTitle: map['jobTitle'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      location: map['location'] as String? ?? '',
      summary: map['summary'] as String? ?? '',
      linkedin: map['linkedin'] as String? ?? '',
      github: map['github'] as String? ?? '',
      portfolioUrl: map['portfolioUrl'] as String? ?? '',
      hasPhoto: map['hasPhoto'] as bool? ?? true,
      profilePhotoBytes: photoBytes,
      primaryColorHex: map['primaryColorHex'] as int? ?? 0xFF2563EB,
      targetLanguage: map['targetLanguage'] as String?,
      template: CvTemplate.values.firstWhere(
        (t) => t.name == map['template'],
        orElse: () => CvTemplate.sidebarModern,
      ),
      personalTraits: (map['personalTraits'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      experiences: (map['experiences'] as List<dynamic>?)
              ?.map((e) => WorkExperience(
                    company: e['company'] as String? ?? '',
                    position: e['position'] as String? ?? '',
                    startDate: e['startDate'] as String? ?? '',
                    endDate: e['endDate'] as String? ?? '',
                    isCurrent: e['isCurrent'] as bool? ?? false,
                    description: e['description'] as String? ?? '',
                  ))
              .toList() ??
          [],
      educations: (map['educations'] as List<dynamic>?)
              ?.map((e) => Education(
                    school: e['school'] as String? ?? '',
                    degree: e['degree'] as String? ?? '',
                    field: e['field'] as String? ?? '',
                    startDate: e['startDate'] as String? ?? '',
                    endDate: e['endDate'] as String? ?? '',
                    gpa: e['gpa'] as String? ?? '',
                  ))
              .toList() ??
          [],
      skills: (map['skills'] as List<dynamic>?)
              ?.map((s) => SkillItem(
                    name: s['name'] as String? ?? '',
                    level: s['level'] as int? ?? 80,
                    levelLabel: s['levelLabel'] as String? ?? LocalizationService.tr('cv_level_advanced'),
                  ))
              .toList() ??
          [],
      languages: (map['languages'] as List<dynamic>?)
              ?.map((l) => LanguageItem(
                    language: l['language'] as String? ?? '',
                    level: l['level'] as String? ?? '',
                  ))
              .toList() ??
          [],
      references: (map['references'] as List<dynamic>?)
              ?.map((r) => ReferenceItem(
                    name: r['name'] as String? ?? '',
                    position: r['position'] as String? ?? '',
                    company: r['company'] as String? ?? '',
                    phone: r['phone'] as String? ?? '',
                    email: r['email'] as String? ?? '',
                  ))
              .toList() ??
          [],
      projects: (map['projects'] as List<dynamic>?)
              ?.map((p) => ProjectItem(
                    name: p['name'] as String? ?? '',
                    role: p['role'] as String? ?? '',
                    link: p['link'] as String? ?? '',
                    date: p['date'] as String? ?? '',
                    description: p['description'] as String? ?? '',
                    technologies: p['technologies'] as String? ?? '',
                  ))
              .toList() ??
          [],
      certificates: (map['certificates'] as List<dynamic>?)
              ?.map((c) => CertificateItem(
                    name: c['name'] as String? ?? '',
                    issuer: c['issuer'] as String? ?? '',
                    date: c['date'] as String? ?? '',
                    credentialUrl: c['credentialUrl'] as String? ?? '',
                  ))
              .where((c) =>
                  !(c.name.contains('Google Certified Associate Android Developer') ||
                    c.credentialUrl.contains('verify.google.com/cert/12345')))
              .toList() ??
          [],
    );

    if (map['sectionOrder'] != null) {
      final orderList = (map['sectionOrder'] as List<dynamic>)
          .map((s) => CvSectionType.values.firstWhere(
                (sec) => sec.name == s,
                orElse: () => CvSectionType.summary,
              ))
          .toList();
      cv.sectionOrder = orderList;
    }

    return cv;
  }

  @visibleForTesting
  static Map<String, dynamic> cvToMapForTesting(CvModel cv) => _cvToMap(cv);

  @visibleForTesting
  static CvModel cvFromMapForTesting(Map<String, dynamic> map) => _cvFromMap(map);
}
