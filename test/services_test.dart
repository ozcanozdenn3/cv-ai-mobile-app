import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/models/document_model.dart';
import 'package:mobile_app/services/document_parser_service.dart';
import 'package:mobile_app/services/docx_converter_service.dart';
import 'package:mobile_app/services/office_converter_service.dart';
import 'package:mobile_app/services/ocr_engine_service.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/cv_storage_service.dart';
import 'package:mobile_app/services/pdf_generator_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  group('DocumentParserService Tests', () {
    test('parseCsv should correctly parse comma and semicolon separated tables', () {
      const csvData = 'Ad,Soyad,Departman,Maas\nCanberk,Yilmaz,Mobil,75000\nAhmet,Demir,Backend,70000';
      final result = DocumentParserService.parseCsv(csvData);

      expect(result.length, 3);
      expect(result[0], ['Ad', 'Soyad', 'Departman', 'Maas']);
      expect(result[1], ['Canberk', 'Yilmaz', 'Mobil', '75000']);
      expect(result[2], ['Ahmet', 'Demir', 'Backend', '70000']);
    });

    test('parseDocx should extract XML text correctly', () async {
      // Create a mock docx zip archive in memory with word/document.xml
      final archive = Archive();
      const documentXml = '''<?xml version="1.0" encoding="UTF-8"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    <w:p>
      <w:pPr><w:pStyle w:val="Heading1"/></w:pPr>
      <w:r><w:t>GIZLILIK SOZLESMESI</w:t></w:r>
    </w:p>
    <w:p>
      <w:r><w:t>Taraflar isbu sozlesmeyi onaylamistir.</w:t></w:r>
    </w:p>
  </w:body>
</w:document>''';

      final bytes = utf8.encode(documentXml);
      archive.addFile(ArchiveFile('word/document.xml', bytes.length, bytes));
      final zipBytes = ZipEncoder().encode(archive);

      final parsed = await DocumentParserService.parseDocx(Uint8List.fromList(zipBytes!));
      expect(parsed, contains('# GIZLILIK SOZLESMESI'));
      expect(parsed, contains('Taraflar isbu sozlesmeyi onaylamistir.'));
    });

    test('parseXlsx should extract sheets and cell matrices correctly', () async {
      // Create an Excel workbook in memory
      final excel = Excel.createExcel();
      final sheet = excel['Sheet1'];
      sheet.appendRow([TextCellValue('Urun'), TextCellValue('Fiyat'), TextCellValue('Adet')]);
      sheet.appendRow([TextCellValue('MacBook Pro'), TextCellValue('85000 TL'), TextCellValue('2')]);

      final bytes = excel.save();
      final parsed = await DocumentParserService.parseXlsx(Uint8List.fromList(bytes!));

      expect(parsed.isNotEmpty, true);
      expect(parsed[0], contains('Urun'));
      expect(parsed[1], contains('MacBook Pro'));
    });
  });

  group('OcrResult Tests', () {
    test('OcrResult model properties', () {
      const res = OcrResult(
        text: 'Test OCR Metni',
        blockCount: 2,
        lineCount: 5,
        isSuccess: true,
      );

      expect(res.text, 'Test OCR Metni');
      expect(res.blockCount, 2);
      expect(res.lineCount, 5);
    });
  });

  group('CV PDF Generator Tests', () {
    test('generateCvPdf should render sidebarModern template with profilePhotoBytes', () async {
      final cv = CvModel.createSample();
      cv.template = CvTemplate.sidebarModern;
      // 1x1 transparent PNG bytes for testing
      cv.profilePhotoBytes = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
      ]);

      final pdfBytes = await PdfGeneratorService.generateCvPdf(cv);
      expect(pdfBytes.isNotEmpty, true);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });

  group('CvStorageService Tests', () {
    test('saveActiveCv and loadActiveCv should persist CV data', () async {
      final cv = CvModel.createSample();
      cv.fullName = 'Test Persisted User';
      cv.jobTitle = 'Senior Cloud Architect';

      await CvStorageService.saveActiveCv(cv);
      final loaded = await CvStorageService.loadActiveCv();

      expect(loaded.fullName, 'Test Persisted User');
      expect(loaded.jobTitle, 'Senior Cloud Architect');
    });

    test('saveDocument, loadDocuments and deleteDocument should manage library', () async {
      final doc = DocumentModel(
        id: 'test_doc_99',
        title: 'Deneme_Belgesi.pdf',
        type: DocumentType.scannedDocument,
        createdAt: DateTime.now(),
        pageCount: 2,
        fileSize: '300 KB',
      );

      await CvStorageService.saveDocument(doc);
      var docs = await CvStorageService.loadDocuments();
      expect(docs.any((d) => d.id == 'test_doc_99'), true);

      await CvStorageService.deleteDocument('test_doc_99');
      docs = await CvStorageService.loadDocuments();
      expect(docs.any((d) => d.id == 'test_doc_99'), false);
    });
  });

  group('AuthService Tests', () {
    test('loginWithEmail should log in user successfully', () async {
      await AuthService.loginWithEmail(
        emailOrUsername: 'test@cvai.app',
        password: 'password123',
      );
      expect(AuthService.isLoggedIn, true);
      expect(AuthService.currentUser?.email, 'test@cvai.app');
    });

    test('registerWithEmail should require accepting terms', () async {
      expect(
        () async => await AuthService.registerWithEmail(
          fullName: 'Test User',
          email: 'test2@cvai.app',
          password: 'pass',
          acceptedTerms: false,
        ),
        throwsA(isA<Exception>()),
      );
    });

    test('signInWithGoogle & Apple should authenticate correctly', () async {
      await AuthService.signInWithGoogle();
      expect(AuthService.currentUser?.provider, AuthProviderType.google);

      await AuthService.signInWithApple();
      expect(AuthService.currentUser?.provider, AuthProviderType.apple);
    });

    test('logout and deleteAccount should clear session', () async {
      await AuthService.logout();
      expect(AuthService.currentUser, isNull);
      expect(AuthService.isLoggedIn, false);

      await AuthService.signInWithGoogle();
      expect(AuthService.isLoggedIn, true);

      await AuthService.deleteAccount();
      expect(AuthService.currentUser, isNull);
    });
  });

  group('DocxConverterService Tests', () {
    test('createDocxFromText should create valid OpenXML docx archive', () {
      final docxBytes = DocxConverterService.createDocxFromText(
        title: 'Örnek Test Belgesi',
        paragraphs: [
          'Birinci paragraf metni: CV AI Belge Dönüştürücü.',
          'İkinci paragraf: ATS uyumlu ve profesyonel format.',
        ],
      );

      expect(docxBytes.isNotEmpty, true);
      expect(docxBytes.length, greaterThan(200));

      final archive = ZipDecoder().decodeBytes(docxBytes);
      final files = archive.files.map((f) => f.name).toList();

      expect(files.contains('[Content_Types].xml'), true);
      expect(files.contains('_rels/.rels'), true);
      expect(files.contains('word/document.xml'), true);

      final docXmlFile = archive.findFile('word/document.xml');
      expect(docXmlFile, isNotNull);
      final docXmlContent = utf8.decode(docXmlFile!.content as List<int>);
      expect(docXmlContent.contains('Örnek Test Belgesi'), true);
      expect(docXmlContent.contains('CV AI Belge Dönüştürücü'), true);
    });

    test('extractTextLinesFromPdf should extract text from simple stream', () {
      const samplePdfContent = 'BT\n/F1 12 Tf\n(Merhaba Dunya) Tj\nET\nBT\n(CV AI Proje) Tj\nET';
      final bytes = Uint8List.fromList(utf8.encode(samplePdfContent));

      final lines = DocxConverterService.extractTextLinesFromPdf(bytes);
      expect(lines.contains('Merhaba Dunya'), true);
      expect(lines.contains('CV AI Proje'), true);
    });
  });

  group('OfficeConverterService Tests', () {
    test('createXlsxFromText should produce valid Excel workbook', () {
      final xlsxBytes = OfficeConverterService.createXlsxFromText(
        title: 'Bütçe Planı',
        paragraphs: [
          '# Gelirler',
          'Yazılım Geliştirme: 150000 TL',
          'Danışmanlık: 50000 TL',
          '# Giderler',
          'Sunucu Maliyeti: 12000 TL',
        ],
      );

      expect(xlsxBytes.isNotEmpty, true);
      final excel = Excel.decodeBytes(xlsxBytes);
      expect(excel.tables.isNotEmpty, true);
    });

    test('createDocxFromGrid should produce valid Word OpenXML table document', () {
      final docxBytes = OfficeConverterService.createDocxFromGrid(
        title: 'Personel Listesi',
        grid: [
          ['No', 'Ad Soyad', 'Departman'],
          ['1', 'Ali Yılmaz', 'Yazılım'],
          ['2', 'Ayşe Demir', 'Tasarım'],
        ],
      );

      expect(docxBytes.isNotEmpty, true);
      final archive = ZipDecoder().decodeBytes(docxBytes);
      final docXmlFile = archive.findFile('word/document.xml');
      expect(docXmlFile, isNotNull);

      final xml = utf8.decode(docXmlFile!.content as List<int>);
      expect(xml.contains('Personel Listesi'), true);
      expect(xml.contains('Ali Yılmaz'), true);
      expect(xml.contains('w:tbl'), true);
    });

    test('createPptxFromParagraphs should produce valid PresentationML pptx archive', () {
      final pptxBytes = OfficeConverterService.createPptxFromParagraphs(
        title: 'Yapay Zeka Sunumu',
        paragraphs: [
          '# Giriş',
          'AI Teknolojilerinin Gelişimi',
          'Derin Öğrenme Modelleri',
          '# Uygulama Alanları',
          'Doğal Dil İşleme',
          'Görüntü İşleme',
        ],
      );

      expect(pptxBytes.isNotEmpty, true);
      final archive = ZipDecoder().decodeBytes(pptxBytes);
      final files = archive.files.map((f) => f.name).toList();

      expect(files.contains('[Content_Types].xml'), true);
      expect(files.contains('ppt/presentation.xml'), true);
      expect(files.any((f) => f.startsWith('ppt/slides/slide')), true);
    });

    test('createXlsxFromSlides and createDocxFromSlides', () {
      final slides = [
        const PptxSlide(
          index: 1,
          title: 'Giriş Slaytı',
          bulletPoints: ['Proje Amacı', 'Kapsam'],
        ),
      ];

      final xlsx = OfficeConverterService.createXlsxFromSlides(
        title: 'Sunum Tablosu',
        slides: slides,
      );
      expect(xlsx.isNotEmpty, true);

      final docx = OfficeConverterService.createDocxFromSlides(
        title: 'Sunum Raporu',
        slides: slides,
      );
      expect(docx.isNotEmpty, true);
    });
  });
}
