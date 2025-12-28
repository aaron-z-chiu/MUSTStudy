import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class UserinfoRepository {
  Future<void> createUserinfoItem(int id, String name, String password) async {
    final userinfo = ParseObject('Userinfo')
      ..set('u_id', id)
      ..set('u_name', name)
      ..set('u_password', password);
    final response = await userinfo.save();
    if (response.success) {
      debugPrint('Userinfo item created successfully');
    } else {
      debugPrint('Failed to create Userinfo item: ${response.error?.message}');
    }
  }

  Future<List<ParseObject>?> fetchUserinfo() async {
    try {
      debugPrint('开始获取用户信息...');
      final query = QueryBuilder<ParseObject>(ParseObject('Userinfo'));
      debugPrint('查询对象已创建');
      final response = await query.query();
      debugPrint('查询执行完成，状态：${response.success}');
      debugPrint('错误信息：${response.error?.message ?? "无"}');
      debugPrint('结果数量：${response.results?.length ?? 0}');
      
      if (response.success && response.results != null) {
        return response.results as List<ParseObject>;
      }
      debugPrint('获取失败：${response.error?.message}');
      return null;
    } catch (e) {
      debugPrint('获取用户信息时发生错误: $e');
      return null;
    }
  }

  Future<void> updateUserinfo(int id, String newName, String newPassword) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Userinfo'))
      ..whereEqualTo('u_id', id);
    final response = await query.query();
    if (response.success && response.results != null) {
      final user = response.results!.first as ParseObject;
      user
        ..set('u_name', newName)
        ..set('u_password', newPassword);
      await user.save();
    }
  }

  Future<void> deleteUserinfo(int id) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Userinfo'))
      ..whereEqualTo('u_id', id);
    final response = await query.query();
    if (response.success && response.results != null) {
      final user = response.results!.first as ParseObject;
      await user.delete();
    }
  }

  Future<String> getUserName(int userId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Userinfo'))
      ..whereEqualTo('u_id', userId);
    final response = await query.query();
    if (response.success && response.results != null && response.results!.isNotEmpty) {
      final user = response.results!.first as ParseObject;
      return user.get<String>('u_name') ?? 'Unknown';
    }
    return 'Unknown';
  }

  // 获取用户学习统计数据
  Future<Map<String, dynamic>> getUserStatistics(int userId) async {
    try {
      // 查询用户学习统计数据
      final query = QueryBuilder<ParseObject>(ParseObject('UserStatistics'))
        ..whereEqualTo('userId', userId);
      final response = await query.query();
      
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        final stats = response.results!.first as ParseObject;
        return {
          'studyHours': stats.get<int>('studyHours') ?? 0,
          'solvedProblems': stats.get<int>('solvedProblems') ?? 0,
          'achievements': stats.get<int>('achievements') ?? 0,
        };
      } else {
        // 如果用户没有统计数据，创建一条默认数据
        return await _createDefaultStatistics(userId);
      }
    } catch (e) {
      debugPrint('获取用户统计数据失败: $e');
      // 返回默认数据
      return {
        'studyHours': 0,
        'solvedProblems': 0,
        'achievements': 0,
      };
    }
  }
  
  // 创建默认统计数据
  Future<Map<String, dynamic>> _createDefaultStatistics(int userId) async {
    final stats = ParseObject('UserStatistics')
      ..set('userId', userId)
      ..set('studyHours', 0)
      ..set('solvedProblems', 0)
      ..set('achievements', 0);
    
    final response = await stats.save();
    if (response.success) {
      return {
        'studyHours': 0,
        'solvedProblems': 0,
        'achievements': 0,
      };
    } else {
      debugPrint('创建用户统计数据失败: ${response.error?.message}');
      return {
        'studyHours': 0,
        'solvedProblems': 0,
        'achievements': 0,
      };
    }
  }
  
  // 更新用户学习时长
  Future<bool> updateStudyHours(int userId, double hours) async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('UserStatistics'))
        ..whereEqualTo('userId', userId);
      final response = await query.query();

      ParseObject userStats;
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        userStats = response.results!.first as ParseObject;
        // 获取当前的学习时长
        final currentHours = userStats.get<double>('studyHours') ?? 0.0;
        // 更新学习时长
        userStats.set('studyHours', currentHours + hours);
      } else {
        // 如果不存在记录，创建新记录
        userStats = ParseObject('UserStatistics')
          ..set('userId', userId)
          ..set('studyHours', hours)
          ..set('solvedProblems', 0)
          ..set('achievements', 0);
      }

      final saveResponse = await userStats.save();
      return saveResponse.success;
    } catch (e) {
      debugPrint('更新学习时长失败: $e');
      return false;
    }
  }
  
  // 更新已解题目数量
  Future<bool> updateSolvedProblems(int userId, {int increment = 1}) async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('UserStatistics'))
        ..whereEqualTo('userId', userId);
      final response = await query.query();
      
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        final stats = response.results!.first as ParseObject;
        final currentSolved = stats.get<int>('solvedProblems') ?? 0;
        stats.set('solvedProblems', currentSolved + increment);
        final updateResponse = await stats.save();
        return updateResponse.success;
      } else {
        // 如果用户没有统计数据，创建一条新数据
        final stats = ParseObject('UserStatistics')
          ..set('userId', userId)
          ..set('studyHours', 0)
          ..set('solvedProblems', increment)
          ..set('achievements', 0);
        final createResponse = await stats.save();
        return createResponse.success;
      }
    } catch (e) {
      debugPrint('更新已解题目数量失败: $e');
      return false;
    }
  }
  
  // 更新成就数量
  Future<bool> updateAchievements(int userId, {int increment = 1}) async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('UserStatistics'))
        ..whereEqualTo('userId', userId);
      final response = await query.query();
      
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        final stats = response.results!.first as ParseObject;
        final currentAchievements = stats.get<int>('achievements') ?? 0;
        stats.set('achievements', currentAchievements + increment);
        final updateResponse = await stats.save();
        return updateResponse.success;
      } else {
        // 如果用户没有统计数据，创建一条新数据
        final stats = ParseObject('UserStatistics')
          ..set('userId', userId)
          ..set('studyHours', 0)
          ..set('solvedProblems', 0)
          ..set('achievements', increment);
        final createResponse = await stats.save();
        return createResponse.success;
      }
    } catch (e) {
      debugPrint('更新成就数量失败: $e');
      return false;
    }
  }
  
  // 计算用户等级
  String getUserLevel(int solvedProblems) {
    if (solvedProblems >= 500) {
      return 'Lv.10 专家';
    } else if (solvedProblems >= 400) {
      return 'Lv.9 大师';
    } else if (solvedProblems >= 300) {
      return 'Lv.8 高级学者';
    } else if (solvedProblems >= 200) {
      return 'Lv.7 学者';
    } else if (solvedProblems >= 150) {
      return 'Lv.6 高级学习者';
    } else if (solvedProblems >= 100) {
      return 'Lv.5 勤奋学习者';
    } else if (solvedProblems >= 70) {
      return 'Lv.4 进阶者';
    } else if (solvedProblems >= 40) {
      return 'Lv.3 实践者';
    } else if (solvedProblems >= 10) {
      return 'Lv.2 新手';
    } else {
      return 'Lv.1 初学者';
    }
  }

  // 添加查询用户收藏的方法
  Future<List<int>> getUserBookmarks(int userId) async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('UserBookmarks'))
        ..whereEqualTo('userId', userId);
      final response = await query.query();
      
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        final userBookmarks = response.results!.first as ParseObject;
        final bookmarksList = userBookmarks.get<List>('bookmarkedQuestions');
        if (bookmarksList != null) {
          return List<int>.from(bookmarksList);
        }
      }
      return [];
    } catch (e) {
      debugPrint('获取用户收藏失败: $e');
      return [];
    }
  }
  
  // 添加收藏题目方法
  Future<bool> bookmarkQuestion(int userId, int questionId) async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('UserBookmarks'))
        ..whereEqualTo('userId', userId);
      final response = await query.query();
      
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        // 更新现有收藏
        final userBookmarks = response.results!.first as ParseObject;
        final bookmarksList = userBookmarks.get<List>('bookmarkedQuestions') ?? [];
        
        if (!bookmarksList.contains(questionId)) {
          bookmarksList.add(questionId);
          userBookmarks.set('bookmarkedQuestions', bookmarksList);
          final updateResponse = await userBookmarks.save();
          return updateResponse.success;
        }
        return true; // 已经收藏了
      } else {
        // 创建新的收藏记录
        final userBookmarks = ParseObject('UserBookmarks')
          ..set('userId', userId)
          ..set('bookmarkedQuestions', [questionId]);
        final createResponse = await userBookmarks.save();
        return createResponse.success;
      }
    } catch (e) {
      debugPrint('添加收藏失败: $e');
      return false;
    }
  }
  
  // 取消收藏题目方法
  Future<bool> unbookmarkQuestion(int userId, int questionId) async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('UserBookmarks'))
        ..whereEqualTo('userId', userId);
      final response = await query.query();
      
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        final userBookmarks = response.results!.first as ParseObject;
        final bookmarksList = userBookmarks.get<List>('bookmarkedQuestions') ?? [];
        
        if (bookmarksList.contains(questionId)) {
          bookmarksList.remove(questionId);
          userBookmarks.set('bookmarkedQuestions', bookmarksList);
          final updateResponse = await userBookmarks.save();
          return updateResponse.success;
        }
        return true; // 题目已经不在收藏列表中
      }
      return false;
    } catch (e) {
      debugPrint('取消收藏失败: $e');
      return false;
    }
  }
  
  // 检查题目是否已收藏
  Future<bool> isQuestionBookmarked(int userId, int questionId) async {
    try {
      final bookmarks = await getUserBookmarks(userId);
      return bookmarks.contains(questionId);
    } catch (e) {
      debugPrint('检查收藏状态失败: $e');
      return false;
    }
  }
}
