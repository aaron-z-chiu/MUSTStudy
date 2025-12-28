import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class AchievementRepository {
  Future<void> createAchievement(int aid, int userId, String title, String description,
      String iconName, int progress, int goal, bool isUnlocked) async {
    final achievement = ParseObject('Achievement')
      ..set('a_id', aid)
      ..set('user_id', userId)
      ..set('title', title)
      ..set('description', description)
      ..set('icon_name', iconName)
      ..set('progress', progress)
      ..set('goal', goal)
      ..set('is_unlocked', isUnlocked);
    final response = await achievement.save();
    if (!response.success) {
      throw Exception('Failed to create achievement: ${response.error?.message}');
    }
  }

  Future<List<ParseObject>> fetchAchievements(int userId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Achievement'))
      ..whereEqualTo('user_id', userId);
    final response = await query.query();
    if (response.success && response.results != null) {
      return response.results as List<ParseObject>;
    }
    throw Exception('Failed to fetch achievements');
  }

  Future<void> updateAchievementProgress(int aid, int progress, bool isUnlocked) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Achievement'))
      ..whereEqualTo('a_id', aid);
    final response = await query.query();
    if (response.success && response.results != null) {
      final achievement = response.results!.first as ParseObject;
      achievement
        ..set('progress', progress)
        ..set('is_unlocked', isUnlocked);
      await achievement.save();
    }
  }
}