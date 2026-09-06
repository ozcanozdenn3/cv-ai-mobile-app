import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/models/cv_model.dart';
import 'package:mobile_app/screens/cv_builder_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('education input keeps focus while typing', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final cv = CvModel.createEmpty('tr');

    await tester.pumpWidget(MaterialApp(home: CvBuilderScreen(initialCv: cv)));
    await tester.pump();

    final tabs = tester.widget<TabBar>(find.byType(TabBar));
    tabs.controller!.index = 3;
    await tester.pumpAndSettle();

    final schoolField = find.byType(TextFormField).first;
    await tester.tap(schoolField);
    await tester.enterText(schoolField, 'Bogazici University');
    await tester.pump();

    expect(FocusManager.instance.primaryFocus?.hasFocus, isTrue);
    expect(cv.educations.first.school, 'Bogazici University');
  });
}
