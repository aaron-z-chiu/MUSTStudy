import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:muststudy/repositories/resource_repository.dart';
import 'package:muststudy/repositories/question_respositories.dart';

Future<T> _captureDebugPrint<T>(
  Future<T> Function() body,
  List<String> logs,
) async {
  final old = debugPrint;
  debugPrint = (String? message, {int? wrapWidth}) {
    if (message != null) logs.add(message);
  };
  try {
    return await body();
  } finally {
    debugPrint = old;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();

    // ---- SharedPreferences mock (before Parse.initialize) ----
    SharedPreferences.setMockInitialValues(<String, Object>{});

    const MethodChannel spChannel =
        MethodChannel('plugins.flutter.io/shared_preferences');
    final Map<String, Object> spStore = <String, Object>{};

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(spChannel, (MethodCall call) async {
      switch (call.method) {
        case 'getAll':
          return spStore;
        case 'setBool':
        case 'setInt':
        case 'setDouble':
        case 'setString':
        case 'setStringList':
          final String key = call.arguments['key'] as String;
          final Object value = call.arguments['value'] as Object;
          spStore[key] = value;
          return true;
        case 'remove':
          final String key = call.arguments as String;
          spStore.remove(key);
          return true;
        case 'clear':
          spStore.clear();
          return true;
        default:
          return null;
      }
    });

    // ---- package_info_plus mock ----
    const MethodChannel packageInfoChannel =
        MethodChannel('dev.fluttercommunity.plus/package_info');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(packageInfoChannel, (MethodCall call) async {
      if (call.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'muststudy',
          'packageName': 'muststudy',
          'version': '1.0.0',
          'buildNumber': '1',
          'buildSignature': 'test',
          'installerStore': null,
        };
      }
      return null;
    });

    // ---- path_provider mock ----
    final Directory tmpDir =
        await Directory.systemTemp.createTemp('muststudy_test_');
    final String tmpPath = tmpDir.path;

    Future<dynamic> _pathProviderHandler(MethodCall call) async {
      switch (call.method) {
        case 'getTemporaryDirectory':
        case 'getApplicationDocumentsDirectory':
        case 'getApplicationSupportDirectory':
        case 'getLibraryDirectory':
        case 'getDownloadsDirectory':
        case 'getExternalStorageDirectory':
          return tmpPath;
        case 'getExternalStorageDirectories':
          return <String>[tmpPath];
        default:
          return tmpPath;
      }
    }

    const MethodChannel pathProviderChannel =
        MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, _pathProviderHandler);

    const MethodChannel pathProviderMacOSChannel =
        MethodChannel('plugins.flutter.io/path_provider_macos');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderMacOSChannel, _pathProviderHandler);

    // ---- Parse init (fail-fast endpoint) ----
    await Parse().initialize(
      'testAppId',
      'http://127.0.0.1:1/parse',
      clientKey: 'testClientKey',
      autoSendSessionId: true,
      debug: false,
    );
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  // ============================================================
  // ResourceRepository tests
  // ============================================================
  group('ResourceRepository white-box tests (cache + TTL + fallback branches)', () {
    test('WB-01 cache-hit: fetchResources returns cached resources when cache is valid', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final resource = ParseObject('Resource')
        ..set<int>('r_id', 1)
        ..set<String>('title', 'Test Resource')
        ..set<String>('description', 'desc')
        ..set<String>('url', 'https://example.com')
        ..set<String>('type', 'video')
        ..set<int>('author_id', 100);

      final cachedData = <String, dynamic>{
        'timestamp': now,
        'resources': [resource.toJson()],
      };

      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_resources': jsonEncode(cachedData),
      });

      final repo = ResourceRepository();
      final results = (await repo.fetchResources()) ?? <ParseObject>[];

      expect(results.length, 1);
      expect(results.first.get<int>('r_id'), 1);
      expect(results.first.get<String>('title'), 'Test Resource');
    });

    // ✅ 关键：把 WB-08 放在任何会触发 _isConnectionFailed=true 的测试之前
    test('WB-08 TTL-expired + fallback: expired cache triggers "缓存已过期" then returns expired cache when remote fails', () async {
      final logs = <String>[];
      final oldTs =
          DateTime.now().subtract(const Duration(days: 8)).millisecondsSinceEpoch;

      final resource = ParseObject('Resource')
        ..set<int>('r_id', 2)
        ..set<String>('title', 'Expired-but-usable Resource')
        ..set<String>('description', 'desc')
        ..set<String>('url', 'https://example.com/expired')
        ..set<String>('type', 'doc')
        ..set<int>('author_id', 101);

      final cachedData = <String, dynamic>{
        'timestamp': oldTs,
        'resources': [resource.toJson()],
      };

      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_resources': jsonEncode(cachedData),
      });

      final repo = ResourceRepository();
      final results =
          ((await _captureDebugPrint(() => repo.fetchResources(), logs)) ??
              <ParseObject>[]);

      // 现在一定会走到 TTL 分支（因为 _isConnectionFailed 还没被前序测试污染）
      expect(logs.any((m) => m.contains('缓存已过期')), isTrue);

      // 网络失败后：fallback 返回 ignoreExpiry cache
      expect(results.length, 1);
      expect(results.first.get<int>('r_id'), 2);
      expect(results.first.get<String>('title'), 'Expired-but-usable Resource');
    });

    test('WB-09 corrupted cache robustness: broken JSON does not crash and returns empty list (logs contain "获取缓存资源数据失败")', () async {
      final logs = <String>[];

      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_resources': '{bad json',
      });

      final repo = ResourceRepository();
      final results =
          ((await _captureDebugPrint(() => repo.fetchResources(), logs)) ??
              <ParseObject>[]);

      expect(logs.any((m) => m.contains('获取缓存资源数据失败')), isTrue);
      expect(results, isEmpty);
    });

    test('WB-10 connectionFailed short-circuit: when last fetch failed, repo directly returns (possibly expired) cache', () async {
      final logs = <String>[];
      final repo = ResourceRepository();

      // Step 1: force a failure -> sets _isConnectionFailed = true
      await _captureDebugPrint(() => repo.fetchResources(), logs);

      // Step 2: provide expired cache; next call should short-circuit and return it
      final oldTs =
          DateTime.now().subtract(const Duration(days: 8)).millisecondsSinceEpoch;

      final resource = ParseObject('Resource')
        ..set<int>('r_id', 3)
        ..set<String>('title', 'Offline Resource (expired but returned)')
        ..set<String>('description', 'desc')
        ..set<String>('url', 'https://example.com/offline')
        ..set<String>('type', 'doc')
        ..set<int>('author_id', 102);

      final cachedData = <String, dynamic>{
        'timestamp': oldTs,
        'resources': [resource.toJson()],
      };

      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_resources': jsonEncode(cachedData),
      });

      logs.clear();
      final results =
          ((await _captureDebugPrint(() => repo.fetchResources(), logs)) ??
              <ParseObject>[]);

      expect(logs.any((m) => m.contains('上次连接失败，直接使用缓存数据')), isTrue);
      expect(results.length, 1);
      expect(results.first.get<int>('r_id'), 3);
    });

    test('WB-07 cache-miss fail-safe: when no cache is available, fetchResources returns empty list (no crash)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final repo = ResourceRepository();
      final results = (await repo.fetchResources()) ?? <ParseObject>[];

      expect(results, isA<List<ParseObject>>());
      expect(results, isEmpty);
    });
  });

  // ============================================================
  // QuestionRepository tests
  // ============================================================
  group('QuestionRepository white-box tests (cache + TTL + fallback branches)', () {
    test('WB-02 cache-hit: fetchQuestions returns cached questions when cache is valid', () async {
      final now = DateTime.now().millisecondsSinceEpoch;

      final question = ParseObject('Question')
        ..set<int>('q_id', 10)
        ..set<String>('q_title', 'Test Question')
        ..set<String>('q_content', 'content');

      final cachedData = <String, dynamic>{
        'timestamp': now,
        'questions': [question.toJson()],
      };

      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_questions': jsonEncode(cachedData),
      });

      final repo = QuestionRepository();
      final results = await repo.fetchQuestions();

      expect(results.length, 1);
      expect(results.first.get<int>('q_id'), 10);
      expect(results.first.get<String>('q_title'), 'Test Question');
    });

    // ✅ 同理：WB-08Q 放在任何会触发 _isConnectionFailed=true 的测试之前
    test('WB-08Q TTL-expired + fallback: expired cache triggers "问题缓存已过期" then returns expired cache when remote fails', () async {
      final logs = <String>[];
      final oldTs =
          DateTime.now().subtract(const Duration(days: 8)).millisecondsSinceEpoch;

      final question = ParseObject('Question')
        ..set<int>('q_id', 11)
        ..set<String>('q_title', 'Expired-but-usable Question')
        ..set<String>('q_content', 'content');

      final cachedData = <String, dynamic>{
        'timestamp': oldTs,
        'questions': [question.toJson()],
      };

      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_questions': jsonEncode(cachedData),
      });

      final repo = QuestionRepository();
      final results =
          await _captureDebugPrint(() => repo.fetchQuestions(), logs);

      expect(logs.any((m) => m.contains('问题缓存已过期')), isTrue);
      expect(results.length, 1);
      expect(results.first.get<int>('q_id'), 11);
    });

    test('WB-09Q corrupted cache robustness: broken JSON does not crash and returns empty list (logs contain "获取缓存问题数据失败")', () async {
      final logs = <String>[];

      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_questions': '{bad json',
      });

      final repo = QuestionRepository();
      final results =
          await _captureDebugPrint(() => repo.fetchQuestions(), logs);

      expect(logs.any((m) => m.contains('获取缓存问题数据失败')), isTrue);
      expect(results, isEmpty);
    });

    test('WB-10Q connectionFailed short-circuit: when last fetch failed, repo directly returns (possibly expired) cache', () async {
      final logs = <String>[];
      final repo = QuestionRepository();

      // Step 1: force failure -> sets _isConnectionFailed = true
      await _captureDebugPrint(() => repo.fetchQuestions(), logs);

      // Step 2: provide expired cache; next call should short-circuit and return it
      final oldTs =
          DateTime.now().subtract(const Duration(days: 8)).millisecondsSinceEpoch;

      final question = ParseObject('Question')
        ..set<int>('q_id', 12)
        ..set<String>('q_title', 'Offline Question (expired but returned)')
        ..set<String>('q_content', 'content');

      final cachedData = <String, dynamic>{
        'timestamp': oldTs,
        'questions': [question.toJson()],
      };

      SharedPreferences.setMockInitialValues(<String, Object>{
        'cached_questions': jsonEncode(cachedData),
      });

      logs.clear();
      final results =
          await _captureDebugPrint(() => repo.fetchQuestions(), logs);

      expect(logs.any((m) => m.contains('上次连接失败，直接使用缓存数据')), isTrue);
      expect(results.length, 1);
      expect(results.first.get<int>('q_id'), 12);
    });

    test('WB-07Q cache-miss fail-safe: when no cache is available, fetchQuestions returns empty list (no crash)', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      final repo = QuestionRepository();
      final results = await repo.fetchQuestions();

      expect(results, isEmpty);
    });
  });
}
