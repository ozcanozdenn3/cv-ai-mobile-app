import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/services/localization_service.dart';
import 'package:mobile_app/screens/home_screen.dart';
import 'package:mobile_app/screens/login_screen.dart';
import 'package:mobile_app/screens/register_screen.dart';
import 'package:mobile_app/screens/profile_screen.dart';
import 'package:mobile_app/screens/cv_builder_screen.dart';
import 'package:mobile_app/screens/documents_library_screen.dart';
import 'package:mobile_app/screens/pdf_converter_screen.dart';
import 'package:mobile_app/screens/vip_paywall_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final screens = <String, Widget Function()>{
    'home': () => const HomeScreen(),
    'login': () => const LoginScreen(),
    'register': () => const RegisterScreen(),
    'profile': () => ProfileScreen(isDark: false, onToggleTheme: () {}),
    'documents': () => const DocumentsLibraryScreen(),
    'converter': () => const PdfConverterScreen(),
    'paywall': () => const VipPaywallSheet(),
    'imagePdf': () => const ImageToPdfSheet(),
    'docPdf': () => const DocToPdfSheet(),
    'excelPdf': () => const ExcelToPdfSheet(),
    'pptPdf': () => const PptxToPdfSheet(),
    'ocr': () => const OcrToTxtSheet(),
    'pdfDoc': () => const PdfToDocxSheet(),
    'pdfTxt': () => const PdfToTxtSheet(),
    'wordExcel': () => const WordToExcelSheet(),
    'excelDoc': () => const ExcelToDocxSheet(),
    'pptDoc': () => const PptxToDocxSheet(),
    'docPpt': () => const DocxToPptxSheet(),
    'pptExcel': () => const PptxToExcelSheet(),
  };
  for (final screen in screens.entries) {
    testWidgets('layout ${screen.key} all locales', (tester) async {
      SharedPreferences.setMockInitialValues({});
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final failures = <String>[];
      File('/tmp/layout-details-${screen.key}.log').writeAsStringSync('');
      final handler = FlutterError.onError;
      FlutterError.onError = (details) {
        File('/tmp/layout-details-${screen.key}.log').writeAsStringSync(
            '${LocalizationService.currentLocale}: ${details.toString()}\n', mode: FileMode.append);
        failures.add('${LocalizationService.currentLocale}: ${details.exceptionAsString()} ${details.context}');
      };
      try {
        for (final lang in LocalizationService.supportedLanguages.where((l) =>
            const String.fromEnvironment('LAYOUT_LOCALE').isEmpty || l.code == const String.fromEnvironment('LAYOUT_LOCALE'))) {
          LocalizationService.localeNotifier.value = lang.code;
          await tester.pumpWidget(MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)),
              child: child!),
            home: Scaffold(body: screen.value())));
          await tester.pump(const Duration(milliseconds: 400));
          final scrollables = find.byType(Scrollable);
          if (scrollables.evaluate().isNotEmpty) {
            for (var n = 0; n < 5; n++) {
              await tester.drag(scrollables.first, const Offset(0, -450));
              await tester.pump(const Duration(milliseconds: 100));
            }
          }
          await tester.pumpWidget(const SizedBox.shrink());
          await tester.pump(const Duration(seconds: 1));
        }
      } finally {
        FlutterError.onError = handler;
      }
      expect(failures.toSet(), isEmpty);
    });
  }

  testWidgets('layout CV all tabs with long imported content', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final failures = <String>[];
    File('/tmp/layout-details-cv.log').writeAsStringSync('');
    var activeTab = 0;
    final handler = FlutterError.onError;
    FlutterError.onError = (d) {
      File('/tmp/layout-details-cv.log').writeAsStringSync(
          '${LocalizationService.currentLocale} tab $activeTab: ${d.toString()}\n', mode: FileMode.append);
      failures.add('${LocalizationService.currentLocale} tab $activeTab: ${d.exceptionAsString()} ${d.context}');
    };
    try {
      for (final lang in LocalizationService.supportedLanguages.where((l) =>
          const String.fromEnvironment('LAYOUT_LOCALE').isEmpty || l.code == const String.fromEnvironment('LAYOUT_LOCALE'))) {
        LocalizationService.localeNotifier.value = lang.code;
        final cv = CvModel.createEmpty(lang.code)
          ..fullName = 'Alexandra Very Long Candidate Family Name'
          ..summary = List.filled(15, 'Detailed professional experience and accomplishments.').join(' ')
          ..email = '${List.filled(5, 'longaddress').join()}@example.com';
        cv.references.first.name = 'Professor Very Long Reference Contact Name';
        cv.experiences.first.company = 'International Research and Development Corporation';
        cv.educations.first.school = 'International University of Science and Technology';
        cv.projects.first.name = 'Large Distributed Mobile Application Development Project';
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.5)), child: child!),
          home: CvBuilderScreen(initialCv: cv)));
        await tester.pump(const Duration(milliseconds: 100));
        final controller = tester.widget<TabBar>(find.byType(TabBar)).controller!;
        for (activeTab = 0; activeTab < controller.length; activeTab++) {
          controller.index = activeTab;
          await tester.pump(const Duration(milliseconds: 400));
          final lists = find.byType(ListView).hitTestable();
          if (lists.evaluate().isEmpty) continue;
          final scrollables = find.descendant(of: lists.first, matching: find.byType(Scrollable));
          if (scrollables.evaluate().isNotEmpty) {
            for (var n = 0; n < 4; n++) {
              await tester.drag(scrollables.first, const Offset(0, -450));
              await tester.pump(const Duration(milliseconds: 100));
            }
          }
        }
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump(const Duration(seconds: 5));
      }
    } finally { FlutterError.onError = handler; }
    expect(failures.toSet(), isEmpty);
  });
}
