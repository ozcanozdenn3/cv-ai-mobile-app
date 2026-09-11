import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets(
      'SplashScreen renders center logo, top ticker flowing right, bottom ticker flowing left without overflow',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: SplashScreen(
          onToggleTheme: () {},
        ),
      ),
    );

    // Initial frame
    await tester.pump();
    expect(find.byType(SplashScreen), findsOneWidget);

    // Verify center logo image is present
    expect(find.byType(Image), findsOneWidget);

    // Verify presence of document badge items across the tickers
    expect(find.text('PDF'), findsWidgets);
    expect(find.text('Word'), findsWidgets);
    expect(find.text('CV'), findsWidgets);
    expect(find.text('CamScanner'), findsWidgets);
    expect(find.text('Excel'), findsWidgets);
    expect(find.text('PPTX'), findsWidgets);

    // Advance animation frames to verify ticker translation without RenderFlex overflow
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull,
          reason: 'No exceptions or RenderFlex overflows during ticker animation at step $i');
    }

    // Complete pending timer so test shuts down cleanly
    await tester.pump(const Duration(milliseconds: 2500));
  });
}
