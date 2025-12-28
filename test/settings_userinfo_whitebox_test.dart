import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:network_image_mock/network_image_mock.dart';

import 'package:muststudy/screens/settings_userinfo.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsUserInfoScreen white-box branch tests', () {
    setUp(() async {
      // 每个用例前清空 mock prefs，避免互相污染
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    testWidgets('Selecting Major without College triggers guard SnackBar', (tester) async {
      await mockNetworkImagesFor(() async {
        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SettingsUserInfoScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 点击“专业” → 由于 college = 未绑定，应该弹 SnackBar
        await tester.tap(find.text('专业'));
        await tester.pumpAndSettle();

        expect(find.text('请先选择学院'), findsOneWidget);
      });
    });

    testWidgets('Selecting College resets Major to 未绑定 and persists prefs', (tester) async {
      await mockNetworkImagesFor(() async {
        // 预置：已有学院/专业
        SharedPreferences.setMockInitialValues(<String, Object>{
          'college': '商学院',
          'major': '金融学',
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SettingsUserInfoScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 点击“学院” → 选择“创新工程学院”
        await tester.tap(find.text('学院'));
        await tester.pumpAndSettle();
        expect(find.text('选择学院'), findsOneWidget);

        await tester.tap(find.text('创新工程学院'));
        await tester.pumpAndSettle();

        // 断言：prefs 已写入 college + major 重置为 未绑定
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('college'), '创新工程学院');
        expect(prefs.getString('major'), '未绑定');
      });
    });

    testWidgets('Edit Email saves to SharedPreferences (field persistence path)', (tester) async {
      await mockNetworkImagesFor(() async {
        SharedPreferences.setMockInitialValues(<String, Object>{
          'email': 'old@test.com',
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: Scaffold(body: SettingsUserInfoScreen()),
          ),
        );
        await tester.pumpAndSettle();

        // 点击“邮箱” → 弹出编辑框
        await tester.tap(find.text('邮箱'));
        await tester.pumpAndSettle();
        expect(find.text('编辑邮箱'), findsOneWidget);

        // 输入新邮箱并保存
        const newEmail = 'new@test.com';
        await tester.enterText(find.byType(TextField), newEmail);
        await tester.tap(find.text('保存'));
        await tester.pumpAndSettle();

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('email'), newEmail);
      });
    });
  });
}
