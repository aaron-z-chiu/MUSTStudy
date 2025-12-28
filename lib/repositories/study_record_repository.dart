import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../models/study_record.dart';

class StudyRecordRepository {
  /// 添加一条学习记录
  Future<void> addStudyRecord(int userId, StudyRecord record) async {
    final object = ParseObject('StudyRecord')
      ..set('userId', userId)
      ..set('date', record.date.toIso8601String())
      ..set('duration', record.duration);
    final response = await object.save();
    if (!response.success) {
      throw Exception('保存学习记录失败');
    }
  }

  /// 获取用户的所有学习记录
  Future<List<StudyRecord>> getStudyRecords(int userId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('StudyRecord'))
      ..whereEqualTo('userId', userId)
      ..orderByAscending('date');
    final response = await query.query();
    if (response.success && response.results != null) {
      return (response.results as List<ParseObject>).map((obj) {
        final dateStr = obj.get<String>('date') ?? '';
        final duration = obj.get<int>('duration') ?? 0;
        final date = DateTime.tryParse(dateStr) ?? DateTime.now();
        return StudyRecord(date: date, duration: duration);
      }).toList();
    }
    return [];
  }
} 