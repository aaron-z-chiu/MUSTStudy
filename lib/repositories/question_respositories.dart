import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class QuestionRepository {
  static const String _cacheKey = 'cached_questions';
  static const Duration _cacheDuration = Duration(days: 7); // 延长缓存有效期到7天
  
  // 标记连接状态
  static bool _isConnectionFailed = false;

  Future<void> createQuestionItem(int qid, int userId, String title, String content,
      int likeCount, String description, String difficulty, List<String> tags, String college) async {
    try {
      debugPrint('QuestionRepository: 开始创建问题，ID: $qid, 用户ID: $userId');
      final question = ParseObject('Question')
        ..set('q_id', qid)
        ..set('q_person_id', userId)
        ..set('q_title', title)
        ..set('q_information', content)
        ..set('q_like', likeCount)
        ..set('q_description', description)
        ..set('q_difficulty', difficulty)
        ..set('q_tags', tags)
        ..set('q_college', college)
        ..set('q_submission_count', 0)
        ..set('q_success_count', 0);
      
      debugPrint('QuestionRepository: 准备保存问题对象');
      final response = await question.save();
      
      if (response.success) {
        debugPrint('QuestionRepository: 问题创建成功: ${response.results?.first.objectId}');
        // 新建后清理缓存，下一次请求强制拉新数据
        await _clearCache();
      } else {
        debugPrint('QuestionRepository: 问题创建失败: ${response.error?.message}');
        throw Exception('Failed to create question: ${response.error?.message}');
      }
    } catch (e) {
      debugPrint('QuestionRepository: 创建问题时发生异常: $e');
      throw Exception('创建问题异常: $e');
    }
  }

  // 清除问题缓存
  Future<void> _clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      debugPrint('QuestionRepository: 已清除问题缓存');
    } catch (e) {
      debugPrint('QuestionRepository: 清除缓存失败: $e');
    }
  }

  // 通过ID获取单个问题
  Future<ParseObject?> getQuestionById(int qid) async {
    try {
      // 先尝试从缓存获取
      final cachedQuestions = await _getCachedQuestions();
      if (cachedQuestions != null) {
        final question = cachedQuestions.firstWhere(
          (q) => q.get<int>('q_id') == qid,
          orElse: () => ParseObject('Question'),
        );
        
        if (question.objectId != null) {
          debugPrint('从缓存获取问题详情，ID: $qid');
          return question;
        }
      }
      
      // 如果缓存中没有，并且之前连接失败，则返回null
      if (_isConnectionFailed) {
        return null;
      }
      
      // 尝试从网络获取
      final query = QueryBuilder<ParseObject>(ParseObject('Question'))
        ..whereEqualTo('q_id', qid);
      final response = await query.query();
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        return response.results!.first as ParseObject;
      }
    } catch (e) {
      debugPrint('获取问题详情失败: $e');
      _isConnectionFailed = true;
    }
    return null;
  }

  // 获取所有问题，可指定按创建时间或点赞数排序
  Future<List<ParseObject>> fetchQuestions({String orderBy = 'createdAt'}) async {
    try {
      // 如果之前连接失败，直接使用缓存
      if (_isConnectionFailed) {
        debugPrint('上次连接失败，直接使用缓存数据');
        final cached = await _getCachedQuestions(ignoreExpiry: true);
        return cached ?? [];
      }
      
      // 尝试从缓存获取数据
      final cachedQuestions = await _getCachedQuestions();
      if (cachedQuestions != null) {
        debugPrint('使用缓存的问题数据');
        return cachedQuestions;
      }
      
      // 缓存不存在或已过期，从网络获取
      debugPrint('Repository: 开始获取问题列表，排序方式: $orderBy');
      final query = QueryBuilder<ParseObject>(ParseObject('Question'));
      
      if (orderBy == 'createdAt') {
        query.orderByDescending('createdAt');
      } else if (orderBy == 'likes') {
        query.orderByDescending('q_like');
      }
      
      final response = await query.query();
      if (response.success && response.results != null) {
        final results = response.results as List<ParseObject>;
        debugPrint('Repository: 成功获取${results.length}个问题');
        
        // 保存到缓存
        _cacheQuestions(results);
        _isConnectionFailed = false;
        return results;
      }
      
      throw Exception('Failed to fetch questions');
    } catch (e) {
      debugPrint('Repository: 获取问题失败，错误: $e');
      _isConnectionFailed = true;
      
      // 尝试返回可能过期的缓存数据作为备份
      final cached = await _getCachedQuestions(ignoreExpiry: true);
      return cached ?? [];
    }
  }

  // 根据条件筛选问题
  Future<List<ParseObject>> filterQuestions({
    String? college,
    String? tag,
    String? searchQuery,
  }) async {
    try {
      // 先获取所有问题
      final allQuestions = await fetchQuestions();
      
      // 在本地进行筛选
      return allQuestions.where((q) {
        final qCollege = q.get<String>('q_college') ?? '';
        final qMajor = q.get<String>('q_major') ?? '';
        final qTags = q.get<List>('q_tags') ?? [];
        final qTitle = q.get<String>('q_title') ?? '';
        final qDescription = q.get<String>('q_description') ?? '';
        final qInformation = q.get<String>('q_information') ?? '';
        
        // 检查学院筛选
        if (college != null && college != '全部' && qCollege != college) {
          return false;
        }
        
        // 检查标签筛选
        if (tag != null && tag != '全部' && !(qTags.contains(tag))) {
          return false;
        }
        
        // 检查搜索关键词
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final searchLower = searchQuery.toLowerCase();
          if (!qTitle.toLowerCase().contains(searchLower) &&
              !qDescription.toLowerCase().contains(searchLower) &&
              !qInformation.toLowerCase().contains(searchLower) &&
              !qCollege.toLowerCase().contains(searchLower) &&
              !qMajor.toLowerCase().contains(searchLower)) {
            return false;
          }
        }
        
        return true;
      }).toList();
    } catch (e) {
      debugPrint('筛选问题失败: $e');
      return [];
    }
  }

  // 保存问题到缓存
  Future<void> _cacheQuestions(List<ParseObject> questions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 序列化问题数据
      final cachedData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'questions': questions.map((question) => question.toJson()).toList(),
      };
      
      await prefs.setString(_cacheKey, jsonEncode(cachedData));
      debugPrint('问题数据已缓存，共 ${questions.length} 条记录');
    } catch (e) {
      debugPrint('缓存问题数据失败: $e');
    }
  }
  
  // 从缓存获取问题
  Future<List<ParseObject>?> _getCachedQuestions({bool ignoreExpiry = false}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedString = prefs.getString(_cacheKey);
      
      if (cachedString == null) {
        return null;
      }
      
      final cachedData = jsonDecode(cachedString);
      final timestamp = cachedData['timestamp'] as int;
      final cachedTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
      
      // 检查缓存是否过期
      if (!ignoreExpiry && DateTime.now().difference(cachedTime) > _cacheDuration) {
        debugPrint('问题缓存已过期');
        return null;
      }
      
      // 反序列化问题数据
      final questionsJson = cachedData['questions'] as List;
      final questions = questionsJson.map((json) {
        final question = ParseObject('Question');
        question.fromJson(json);
        return question;
      }).toList();
      
      debugPrint('从缓存获取了 ${questions.length} 条问题记录');
      return questions;
    } catch (e) {
      debugPrint('获取缓存问题数据失败: $e');
      return null;
    }
  }

  // 为问题添加点赞
  Future<void> likeQuestion(int qid) async {
    try {
      final question = await getQuestionById(qid);
      if (question != null) {
        final currentLikes = question.get<int>('q_like') ?? 0;
        question.set('q_like', currentLikes + 1);
        await question.save();
      }
    } catch (e) {
      debugPrint('点赞失败: $e');
    }
  }

  // 记录问题提交次数
  Future<void> incrementSubmissionCount(int qid) async {
    try {
      final question = await getQuestionById(qid);
      if (question != null) {
        final submissionCount = question.get<int>('q_submission_count') ?? 0;
        question.set('q_submission_count', submissionCount + 1);
        await question.save();
      }
    } catch (e) {
      debugPrint('增加提交计数失败: $e');
    }
  }

  // 记录问题成功解答次数
  Future<void> incrementSuccessCount(int qid) async {
    try {
      final question = await getQuestionById(qid);
      if (question != null) {
        final successCount = question.get<int>('q_success_count') ?? 0;
        question.set('q_success_count', successCount + 1);
        await question.save();
      }
    } catch (e) {
      debugPrint('增加成功计数失败: $e');
    }
  }

  // 获取热门问题（浏览量或提交次数较多的问题）
  Future<List<ParseObject>> getHotQuestions(int limit) async {
    try {
      final allQuestions = await fetchQuestions();
      // 在本地对数据进行排序
      allQuestions.sort((a, b) {
        final aCount = a.get<int>('q_submission_count') ?? 0;
        final bCount = b.get<int>('q_submission_count') ?? 0;
        return bCount.compareTo(aCount);
      });
      
      // 返回前limit个
      return allQuestions.take(limit).toList();
    } catch (e) {
      debugPrint('获取热门问题失败: $e');
      return [];
    }
  }

  // 获取某学院的推荐问题
  Future<List<ParseObject>> getRecommendedQuestions(String college, int limit) async {
    try {
      final allQuestions = await fetchQuestions();
      // 在本地筛选和排序
      var filtered = allQuestions;
      
      if (college != '全部') {
        filtered = allQuestions.where((q) => 
          q.get<String>('q_college') == college
        ).toList();
      }
      
      // 按点赞数排序
      filtered.sort((a, b) {
        final aLikes = a.get<int>('q_like') ?? 0;
        final bLikes = b.get<int>('q_like') ?? 0;
        return bLikes.compareTo(aLikes);
      });
      
      // 返回前limit个
      return filtered.take(limit).toList();
    } catch (e) {
      debugPrint('获取推荐问题失败: $e');
      return [];
    }
  }
}
