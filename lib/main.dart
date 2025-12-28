import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'routes/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 初始化 Parse
  try {
    await Parse().initialize(
      'B3nFoESSc6GUUQHgFCmFzvf7RQKliagLarf7Rs3g',
      'https://parseapi.back4app.com',
      clientKey: 'Y43iPlZRj7XgjqTR56PG48PAxhnPgf4QeeSMtWIv',
      debug: true,
      autoSendSessionId: true,
    );
    debugPrint('Parse 初始化成功');
  } catch (e) {
    debugPrint('Parse 初始化失败: $e');
  }

  runApp(const App());
}
