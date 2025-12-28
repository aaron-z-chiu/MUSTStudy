import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:muststudy/screens/login_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // 避免 google_fonts 在测试里尝试联网拉字体导致报错
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  testWidgets('LoginScreen smoke test', (WidgetTester tester) async {
    // 避免 SharedPreferences 在测试环境报错
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
    await tester.pump(); // 不要 pumpAndSettle（有动画/定时器可能永远 settle 不完）

    expect(find.text('Must Study'), findsOneWidget);
    expect(find.text('Log in'), findsOneWidget);

    // 你的登录页有两个输入框（Username/Password）
    expect(find.byType(TextFormField), findsNWidgets(2));
  });
}
