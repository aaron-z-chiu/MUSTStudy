import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class AnswerRespositories {
  // 创建回答
  Future<void> createAnswer(int aid, String ainfo, int uid, int alike, int questionId) async {
    final answer = ParseObject('Answer')
      ..set('a_id', aid)
      ..set('ainfo', ainfo)
      ..set('uid', uid)
      ..set('alike', alike)
      ..set('question_id', questionId)
      ..set('created_at', DateTime.now());
    final response = await answer.save();
    if (!response.success) {
      throw Exception('Failed to create answer: ${response.error?.message}');
    }
    else{
      debugPrint('Answer created successfully');
    }
  }
  
  // 获取所有回答
  Future<List<ParseObject>> fetchAnswer() async {
    final query = QueryBuilder<ParseObject>(ParseObject('Answer'));
    final response = await query.query();
    if (response.success && response.results!= null) {
      return response.results as List<ParseObject>; 
    }
    else{
      return []; 
    }
  }
  
  // 获取特定问题的所有回答
  Future<List<ParseObject>> getAnswersByQuestionId(int questionId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Answer'))
      ..whereEqualTo('question_id', questionId)
      ..orderByDescending('alike');  // 默认按点赞数排序
    
    final response = await query.query();
    if (response.success && response.results != null) {
      return response.results as List<ParseObject>;
    }
    return [];
  }
  
  // 获取用户的所有回答
  Future<List<ParseObject>> getAnswersByUserId(int userId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Answer'))
      ..whereEqualTo('uid', userId)
      ..orderByDescending('created_at');
    
    final response = await query.query();
    if (response.success && response.results != null) {
      return response.results as List<ParseObject>;
    }
    return [];
  }
  
  // 为回答点赞
  Future<void> likeAnswer(int answerId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Answer'))
      ..whereEqualTo('a_id', answerId);
    
    final response = await query.query();
    if (response.success && response.results != null && response.results!.isNotEmpty) {
      final answer = response.results!.first as ParseObject;
      final currentLikes = answer.get<int>('alike') ?? 0;
      answer.set('alike', currentLikes + 1);
      await answer.save();
    }
  }
  
  // 更新回答内容
  Future<void> updateAnswer(int answerId, String newContent) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Answer'))
      ..whereEqualTo('a_id', answerId);
    
    final response = await query.query();
    if (response.success && response.results != null && response.results!.isNotEmpty) {
      final answer = response.results!.first as ParseObject;
      answer.set('ainfo', newContent);
      answer.set('updated_at', DateTime.now());
      await answer.save();
    }
  }
  
  // 删除回答
  Future<void> deleteAnswer(int answerId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Answer'))
      ..whereEqualTo('a_id', answerId);
    
    final response = await query.query();
    if (response.success && response.results != null && response.results!.isNotEmpty) {
      final answer = response.results!.first as ParseObject;
      await answer.delete();
    }
  }
  
  // 获取最佳回答（点赞数最高的回答）
  Future<ParseObject?> getBestAnswer(int questionId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Answer'))
      ..whereEqualTo('question_id', questionId)
      ..orderByDescending('alike')
      ..setLimit(1);
    
    final response = await query.query();
    if (response.success && response.results != null && response.results!.isNotEmpty) {
      return response.results!.first as ParseObject;
    }
    return null;
  }
}
