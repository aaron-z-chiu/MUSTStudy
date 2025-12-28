import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class UserLearningDataRepository {
  Future<void> createUserLearningData(int uid, int time, int solved, int achievement, int continuousTime, ) async {
    final userLearningData = ParseObject('User_learning_data')
      ..set('uid', uid)
      ..set('time', time)
      ..set('solved', solved)
      ..set('achievement', achievement)
      ..set('continuousTime', continuousTime);
    final response = await userLearningData.save();
    if (!response.success) {
      throw Exception('Failed to create user learning data: ${response.error?.message}');
   
    }
  }
  Future<List<ParseObject>> fetchUserLearningData(int userId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('User_learning_data'))
      ..whereEqualTo('uid', userId)
      ..orderByDescending('createdAt');
    final response = await query.query();
    if (!response.success) {
      throw Exception('Failed to fetch user learning data: ${response.error?.message}');
    } else {
      return response.results as List<ParseObject>;
     }
  }
}