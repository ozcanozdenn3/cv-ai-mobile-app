import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_app/services/auth_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Apple review demo account signs in without Supabase', () async {
    SharedPreferences.setMockInitialValues({});

    final signedIn = await AuthService.loginWithEmail(
      emailOrUsername: 'demo@cvai.app',
      password: 'Demo123456!',
    );

    expect(signedIn, isTrue);
    expect(AuthService.currentUser?.email, 'demo@cvai.app');
  });
}
