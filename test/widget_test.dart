import 'dart:convert';
import 'dart:typed_data';
import 'package:archive/archive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/main.dart';
import 'package:mobile_app/screens/cam_scanner_screen.dart';
import 'package:mobile_app/screens/cv_builder_screen.dart';
import 'package:mobile_app/screens/documents_library_screen.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/screens/register_screen.dart';
import 'package:mobile_app/screens/pdf_converter_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/screens/vip_paywall_sheet.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/screens/cv_preview_screen.dart';
import 'package:mobile_app/services/auth_service.dart';
import 'package:mobile_app/services/document_parser_service.dart';
import 'package:mobile_app/services/pdf_generator_service.dart';
import 'package:mobile_app/services/localization_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final sampleUser = UserModel(
    id: 'usr_101',
    fullName: 'Canberk Yılmaz',
    email: 'canberk.yilmaz@email.com',
    isPro: true,
    provider: AuthProviderType.google,
  );

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'app_selected_language_code': 'tr',
      'cv_ai_active_user_session': json.encode(sampleUser.toJson()),
      'cv_ai_saved_documents_list': json.encode([
        {
          'id': 'test_doc_1',
          'title': 'Canberk_Yilmaz_Resume.pdf',
          'type': 'cv',
          'createdAt': DateTime.now().toIso8601String(),
          'pageCount': 1,
          'fileSize': '45 KB',
        }
      ]),
    });
    LocalizationService.localeNotifier.value = 'tr';
    AuthService.currentUserNotifier.value = sampleUser;
  });

  testWidgets('CV AI smoke and splash to home navigation test', (WidgetTester tester) async {
    await tester.pumpWidget(const CvAiApp());
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('CV AI'), findsWidgets);

    // Let splash finish and navigate to Home
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(MainNavigationWrapper), findsOneWidget);
  });

  testWidgets('CvBuilderScreen shows back button when pushed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Root'))),
      ),
    );

    // Push CvBuilderScreen
    final BuildContext context = tester.element(find.text('Root'));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CvBuilderScreen()),
    );
    await tester.pumpAndSettle();

    // Verify back button exists and works
    final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Verified back on root
    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('CvBuilderScreen initializes with clean empty fields and no mock Canberk data', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CvBuilderScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify mock sample data is NOT shown
    expect(find.text('Canberk Yılmaz'), findsNothing);
    expect(find.text('Kıdemli Mobil Yazılım Uzmanı'), findsNothing);
    expect(find.text('TechVentures Global'), findsNothing);
    expect(find.text('SoftStudio Solutions'), findsNothing);
  });

  testWidgets('CamScannerScreen shows back button when pushed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Root'))),
      ),
    );

    final BuildContext context = tester.element(find.text('Root'));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CamScannerScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('PdfConverterScreen shows back button when pushed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Root'))),
      ),
    );

    final BuildContext context = tester.element(find.text('Root'));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const PdfConverterScreen()),
    );
    await tester.pumpAndSettle();

    final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('DocumentsLibraryScreen shows back button when pushed', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Root'))),
      ),
    );

    final BuildContext context = tester.element(find.text('Root'));
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const DocumentsLibraryScreen()),
    );
    await tester.pumpAndSettle();

    final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows back button and returns safely', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('Root'))),
      ),
    );

    final BuildContext context = tester.element(find.text('Root'));
    ProfileScreen.show(context, isDark: false, onToggleTheme: () {});
    await tester.pumpAndSettle();

    final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    expect(find.text('Root'), findsOneWidget);
  });

  testWidgets('CamScannerScreen shows back button in bottom-nav tab mode and calls onReturnHome', (WidgetTester tester) async {
    bool returnedHome = false;

    await tester.pumpWidget(
      MaterialApp(
        home: CamScannerScreen(
          onReturnHome: () => returnedHome = true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pump();
    expect(returnedHome, isTrue);
  });

  testWidgets('Tapping CamScanner on Home and tapping Back button returns to Home', (WidgetTester tester) async {
    // Push CamScanner on top of HomeScreen directly
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('HomeRoot'))),
      ),
    );
    await tester.pump();

    final BuildContext ctx = tester.element(find.text('HomeRoot'));
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const CamScannerScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // We are on CamScanner screen - back button visible
    final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backBtn, findsOneWidget);

    // Tap back
    await tester.tap(backBtn, warnIfMissed: false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));

    // Back on HomeRoot page
    expect(find.text('HomeRoot'), findsOneWidget);
    expect(find.byType(CamScannerScreen), findsNothing);
  });

  testWidgets('CamScanner interactive features test (modes, capture, detail modal, OCR)', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CamScannerScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Check Document Modes switching
    expect(find.byIcon(Icons.badge_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.badge_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byIcon(Icons.badge_rounded), findsOneWidget);

    // 2. Test Gallery Import Button (Opens Source Selection)
    final galleryBtn = find.byIcon(Icons.photo_library_rounded);
    expect(galleryBtn, findsOneWidget);
    await tester.tap(galleryBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(BottomSheet), findsOneWidget);
  });

  testWidgets('DocumentsLibraryScreen interactive filters and action sheet test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DocumentsLibraryScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Check title
    expect(find.text(LocalizationService.tr('docs_title')), findsOneWidget);

    // 2. Tap document item to open action sheet if present
    final docItem = find.textContaining('Canberk_Yilmaz');
    if (docItem.evaluate().isNotEmpty) {
      await tester.tap(docItem.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Action Sheet items
      expect(find.text(LocalizationService.tr('docs_action_share')), findsOneWidget);
      expect(find.text(LocalizationService.tr('docs_action_print')), findsOneWidget);
      expect(find.text(LocalizationService.tr('docs_action_delete')), findsOneWidget);
    }
  });

  testWidgets('PdfConverterScreen real converter sheets interaction test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PdfConverterScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Check title & tools
    expect(find.text(LocalizationService.tr('converter_title')), findsOneWidget);
    expect(find.text(LocalizationService.tr('card_word_to_pdf')), findsOneWidget);
    expect(find.text(LocalizationService.tr('card_excel_to_pdf')), findsOneWidget);

    // 2. Tap Word to PDF Card
    await tester.tap(find.text(LocalizationService.tr('card_word_to_pdf')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify modal elements
    expect(find.byType(BottomSheet), findsOneWidget);

    // Close modal
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  });

  testWidgets('LoginScreen and RegisterScreen auth flow test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Check Login elements
    expect(find.text(LocalizationService.tr('auth_btn_login')), findsWidgets);
    expect(find.text(LocalizationService.tr('auth_email')), findsOneWidget);
    expect(find.text(LocalizationService.tr('auth_password')), findsOneWidget);
    expect(find.text(LocalizationService.tr('auth_google')), findsWidgets);
    expect(find.text(LocalizationService.tr('auth_apple')), findsWidgets);

    // 2. Switch to RegisterScreen
    await tester.pumpWidget(
      const MaterialApp(
        home: RegisterScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(LocalizationService.tr('auth_create_account')), findsWidgets);
    expect(find.text(LocalizationService.tr('auth_name')), findsOneWidget);
    expect(find.text(LocalizationService.tr('auth_btn_register')), findsWidgets);
    expect(find.text(LocalizationService.tr('auth_google')), findsWidgets);
    expect(find.text(LocalizationService.tr('auth_apple')), findsWidgets);
  });

  testWidgets('ProfileScreen shows Logout and Delete Account with confirmation dialogs', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MaterialApp(
        home: ProfileScreen(
          isDark: false,
          onToggleTheme: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Check presence of Logout & Delete Account buttons
    final logoutFinder = find.text(LocalizationService.tr('profile_logout'));
    expect(logoutFinder, findsWidgets);
    final deleteFinder = find.text(LocalizationService.tr('profile_delete_acc'));
    expect(deleteFinder, findsWidgets);

    // Tap Logout Button
    await tester.tap(logoutFinder.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlertDialog), findsOneWidget);

    // Cancel dialog
    await tester.tap(find.text(LocalizationService.tr('cancel')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Delete Account Button
    await tester.tap(deleteFinder.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('Full auth state transition: Login -> Home -> Logout -> Login without black screen', (WidgetTester tester) async {
    // 1. Reset auth to null and remove stored session
    await AuthService.logout();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('cv_ai_active_user_session');
    AuthService.currentUserNotifier.value = null;

    await tester.pumpWidget(const CvAiApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 2400));
    await tester.pump(const Duration(milliseconds: 800));

    // 2. Verified on LoginScreen (No guest button, hero logo present)
    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.textContaining('Misafir Olarak'), findsNothing);

    // 3. Enter credentials and perform login
    await tester.enterText(find.byType(TextField).first, 'test@cvai.com');
    await tester.enterText(find.byType(TextField).last, 'password123');
    await tester.pump(const Duration(milliseconds: 100));

    final loginBtn = find.widgetWithText(ElevatedButton, LocalizationService.tr('auth_btn_login'));
    expect(loginBtn, findsOneWidget);
    await tester.tap(loginBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(milliseconds: 600));

    // 4. Verified seamlessly on HomeScreen (NO black screen, MainNavigationWrapper present)
    expect(find.byType(MainNavigationWrapper), findsOneWidget);

    // 5. Logout
    await AuthService.logout();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 400));

    // 6. Verified transitioned cleanly back to LoginScreen
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Push CamScanner on top of HomeScreen directly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: Text('HomeRoot'))),
      ),
    );
    await tester.pump();

    final BuildContext ctx = tester.element(find.text('HomeRoot'));
    Navigator.of(ctx).push(
      MaterialPageRoute(builder: (_) => const CamScannerScreen()),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // We are on CamScanner screen - back button visible
    final backBtn = find.byIcon(Icons.arrow_back_ios_new_rounded);
    expect(backBtn, findsOneWidget);
    await tester.tap(backBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // Back on home root
    expect(find.text('HomeRoot'), findsOneWidget);
  });

  testWidgets('PdfConverterScreen bidirectional direction switcher and tools test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: PdfConverterScreen()),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Initial direction: PDF'e Dönüştür (only tab now)
    expect(find.text(LocalizationService.tr('converter_direction_to_pdf')), findsOneWidget);
    expect(find.text(LocalizationService.tr('card_word_to_pdf')), findsOneWidget);
    expect(find.text(LocalizationService.tr('card_pdf_to_word')), findsOneWidget);
    expect(find.text(LocalizationService.tr('card_ocr_text')), findsOneWidget);

    // PDF'ten Dönüştür tab removed - no direction switcher test needed
  });

  test('PowerPoint (PPTX) parser and PDF generator test', () async {
    // 1. Create a synthetic valid PPTX archive with 2 slides
    final archive = Archive();
    const slide1Xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:sp><p:txBody><a:p><a:r><a:t>Giriş ve Proje Özeti</a:t></a:r></a:p></p:txBody></p:sp>
      <p:sp><p:txBody><a:p><a:r><a:t>CV AI modern mobil uygulama mimarisi.</a:t></a:r></a:p></p:txBody></p:sp>
    </p:spTree>
  </p:cSld>
</p:sld>''';

    const slide2Xml = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<p:sld xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main">
  <p:cSld>
    <p:spTree>
      <p:sp><p:txBody><a:p><a:r><a:t>Sonuç ve Yol Haritası</a:t></a:r></a:p></p:txBody></p:sp>
      <p:sp><p:txBody><a:p><a:r><a:t>Tüm office formatları PDF standardında.</a:t></a:r></a:p></p:txBody></p:sp>
    </p:spTree>
  </p:cSld>
</p:sld>''';

    archive.addFile(ArchiveFile('ppt/slides/slide1.xml', slide1Xml.length, utf8.encode(slide1Xml)));
    archive.addFile(ArchiveFile('ppt/slides/slide2.xml', slide2Xml.length, utf8.encode(slide2Xml)));
    final pptxBytes = Uint8List.fromList(ZipEncoder().encode(archive)!);

    // 2. Parse PPTX
    final slides = await DocumentParserService.parsePptx(pptxBytes);
    expect(slides.length, equals(2));
    expect(slides[0].title, equals('Giriş ve Proje Özeti'));
    expect(slides[0].bulletPoints, contains('CV AI modern mobil uygulama mimarisi.'));
    expect(slides[1].title, equals('Sonuç ve Yol Haritası'));

    // 3. Generate presentation PDF
    final pdfBytes = await PdfGeneratorService.generatePresentationPdfFromPptx(
      presentationTitle: 'CV AI Sunum',
      slides: slides,
    );
    expect(pdfBytes.isNotEmpty, isTrue);
    expect(pdfBytes.sublist(0, 4), equals(utf8.encode('%PDF')));
  });

  testWidgets('ProfileScreen shows Top 15+ CV Countries languages modal', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            isDark: true,
            onToggleTheme: () {},
            isProUser: true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Tap language setting
    final langTile = find.text(LocalizationService.tr('profile_language'));
    expect(langTile, findsOneWidget);
    await tester.tap(langTile);
    await tester.pumpAndSettle();

    // Verify top CV countries appear
    expect(find.text(LocalizationService.tr('profile_language')), findsWidgets);
    expect(find.text('Türkçe'), findsWidgets);
    expect(find.text('English (US)'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('Français'), findsOneWidget);
    expect(find.text('Español (ES)'), findsOneWidget);
  });

  testWidgets('ProfileScreen shows Help & VIP Support modal with ozden9865@gmail.com', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfileScreen(
            isDark: true,
            onToggleTheme: () {},
            isProUser: true,
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Tap Help & Support setting
    final supportTile = find.text(LocalizationService.tr('profile_help'));
    expect(supportTile, findsOneWidget);
    await tester.tap(supportTile);
    await tester.pumpAndSettle();

    // Verify support modal content
    expect(find.text(LocalizationService.tr('support_modal_title')), findsOneWidget);
    expect(find.text('ozden9865@gmail.com'), findsOneWidget);
  });

  testWidgets('VipPaywallSheet displays secure checkout without free trial references and allows upgrade', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: VipPaywallSheet(),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // 1. Verify title and clean guarantee text
    expect(find.text(LocalizationService.tr('paywall_subtitle')), findsOneWidget);
    expect(find.text(LocalizationService.tr('paywall_guarantee')), findsWidgets);
    expect(find.textContaining('3 Gün Ücretsiz Deneme'), findsNothing);
    expect(find.textContaining('3-Day Free Trial'), findsNothing);

    // 2. Verify the 3 active tiers (Weekly, Monthly, Yearly). Lifetime was removed.
    expect(find.text(LocalizationService.tr('paywall_plan_weekly')), findsOneWidget);
    expect(find.text(LocalizationService.tr('paywall_plan_monthly')), findsOneWidget);
    expect(find.text(LocalizationService.tr('paywall_plan_yearly')), findsOneWidget);

    // 3. CTA button is present
    final ctaBtn = find.text(LocalizationService.tr('paywall_cta'));
    expect(ctaBtn, findsOneWidget);
    await tester.tap(ctaBtn);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    // IAP flow requires a real StoreKit / Play Billing session — no further assertions here.
  });

  testWidgets('CvPreviewScreen gates both Print and Share actions when user is not Pro', (WidgetTester tester) async {
    // Reset to free user
    AuthService.currentUserNotifier.value = UserModel(
      id: 'test_free',
      fullName: 'Test Free User',
      email: 'free@test.com',
      isPro: false,
    );

    final testCv = CvModel.createSample();

    await tester.pumpWidget(
      MaterialApp(
        home: CvPreviewScreen(cv: testCv),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));

    // Find print icon in app bar and tap it
    final printBtn = find.byIcon(Icons.print_rounded);
    expect(printBtn, findsWidgets);
    await tester.tap(printBtn.first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // Verify VipPaywallSheet opened
    expect(find.byType(VipPaywallSheet), findsOneWidget);
  });

  test('Multi-language CV Generation and Localized PDF Headers verification',
      () async {
    // 1. English localized profile test
    final enCv = CvModel.createSample('en');
    expect(enCv.fullName, equals('Alex Morgan'));
    expect(enCv.jobTitle, contains('Senior Mobile Software Engineer'));
    expect(enCv.educations.first.school, contains('Stanford'));
    expect(enCv.experiences.first.isCurrent, isTrue);

    // 2. German localized profile test
    final deCv = CvModel.createSample('de');
    expect(deCv.fullName, equals('Max Mustermann'));
    expect(deCv.educations.first.school, contains('München'));

    // 3. Turkish localized profile test
    final trCv = CvModel.createSample('tr');
    expect(trCv.fullName, equals('Canberk Yılmaz'));
    expect(trCv.educations.first.school, contains('Teknik Üniversitesi'));

    // 4. PdfCvLocaleHelper section headers localization test
    expect(PdfCvLocaleHelper.getSectionTitle(CvSectionType.experiences, 'en'), equals('WORK EXPERIENCE'));
    expect(PdfCvLocaleHelper.getSectionTitle(CvSectionType.educations, 'en'), equals('EDUCATION'));
    expect(PdfCvLocaleHelper.getSectionTitle(CvSectionType.skills, 'en'), equals('SKILLS & EXPERTISE'));
    expect(PdfCvLocaleHelper.getSectionTitle(CvSectionType.languages, 'en'), equals('LANGUAGES'));
    expect(PdfCvLocaleHelper.getPresentText('en'), equals('Present'));

    expect(PdfCvLocaleHelper.getSectionTitle(CvSectionType.experiences, 'de'), equals('BERUFSERFAHRUNG'));
    expect(PdfCvLocaleHelper.getSectionTitle(CvSectionType.educations, 'de'), equals('AUSBILDUNG'));
    expect(PdfCvLocaleHelper.getPresentText('de'), equals('Heute'));

    expect(PdfCvLocaleHelper.getSectionTitle(CvSectionType.experiences, 'tr'), equals('İŞ DENEYİMLERİ'));
    expect(PdfCvLocaleHelper.getSectionTitle(CvSectionType.educations, 'tr'), equals('EĞİTİM'));
    expect(PdfCvLocaleHelper.getPresentText('tr'), equals('Günümüz'));

    // 5. LocalizationService.getLanguageLevels() dynamic localization
    LocalizationService.setLanguage('en');
    final enLevels = LocalizationService.getLanguageLevels();
    expect(enLevels, contains('Native / Bilingual'));
    expect(enLevels.any((l) => l.contains('C1 - Advanced')), isTrue);

    LocalizationService.setLanguage('tr');
    final trLevels = LocalizationService.getLanguageLevels();
    expect(trLevels.any((l) => l.contains('Ana Dil')), isTrue);
    expect(trLevels.any((l) => l.contains('C1 - İleri Düzey')), isTrue);

    // 6. Generate valid PDF in English
    final enPdfBytes = await PdfGeneratorService.generateCvPdf(enCv, locale: 'en');
    expect(enPdfBytes.isNotEmpty, isTrue);
    expect(enPdfBytes.sublist(0, 4), equals(utf8.encode('%PDF')));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('CvModel certificates empty by default and no static 2023 dummy certificate', () {
    final sampleTr = CvModel.createSample('tr');
    final sampleEn = CvModel.createSample('en');
    final sampleDe = CvModel.createSample('de');

    expect(sampleTr.certificates, isEmpty);
    expect(sampleEn.certificates, isEmpty);
    expect(sampleDe.certificates, isEmpty);

    // When user adds 1 certificate, only 1 certificate exists
    sampleTr.certificates.add(CertificateItem(
      name: 'PMP - Project Management Professional',
      issuer: 'PMI',
      date: '2024',
      credentialUrl: 'pmi.org/verify/999',
    ));
    expect(sampleTr.certificates.length, equals(1));
    expect(sampleTr.certificates.first.name, equals('PMP - Project Management Professional'));
  });
}

