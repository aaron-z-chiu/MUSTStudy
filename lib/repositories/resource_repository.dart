import 'package:flutter/foundation.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ResourceRepository {
  static const String _cacheKey = 'cached_resources';
  static const Duration _cacheDuration = Duration(days: 7); // 延长缓存有效期到7天
  
  // 添加连接状态跟踪
  static bool _isConnectionFailed = false;
  
  Future<void> createResource(int rid, String title, String description, String url,
      String type, int authorId) async {
    final resource = ParseObject('Resource')
      ..set('r_id', rid)
      ..set('title', title)
      ..set('description', description)
      ..set('url', url)
      ..set('type', type)
      ..set('author_id', authorId);
    final response = await resource.save();
    if (!response.success) {
      throw Exception('Failed to create resource: ${response.error?.message}');
    }
  }

  // 使用缓存机制获取资源
  Future<List<ParseObject>?> fetchResources() async {
    try {
      // 如果上次连接失败，直接使用缓存数据
      if (_isConnectionFailed) {
        debugPrint('上次连接失败，直接使用缓存数据');
        final cachedData = await _getCachedResources(ignoreExpiry: true);
        return cachedData ?? [];
      }
      
      // 尝试从缓存获取数据
      final cachedResources = await _getCachedResources();
      if (cachedResources != null) {
        debugPrint('使用缓存的资源数据');
        return cachedResources;
      }
      
      // 缓存不存在或已过期，进行网络请求
      debugPrint('从网络获取资源数据');
      final query = QueryBuilder<ParseObject>(ParseObject('Resource'));
      final response = await query.query();
      
      if (response.success && response.results != null) {
        final results = response.results as List<ParseObject>;
        
        // 保存到缓存
        _cacheResources(results);
        _isConnectionFailed = false;
        return results;
      }
      
      throw Exception('获取资源失败');
    } catch (e) {
      debugPrint('获取资源数据失败: $e');
      _isConnectionFailed = true;
      
      // 尝试返回可能过期的缓存数据作为备份
      return await _getCachedResources(ignoreExpiry: true) ?? [];
    }
  }
  
  // 保存资源到缓存
  Future<void> _cacheResources(List<ParseObject> resources) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 序列化资源数据
      final cachedData = {
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'resources': resources.map((resource) => resource.toJson()).toList(),
      };
      
      await prefs.setString(_cacheKey, jsonEncode(cachedData));
      debugPrint('资源数据已缓存，共 ${resources.length} 条记录');
    } catch (e) {
      debugPrint('缓存资源数据失败: $e');
    }
  }
  
  // 从缓存获取资源
  Future<List<ParseObject>?> _getCachedResources({bool ignoreExpiry = false}) async {
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
        debugPrint('缓存已过期');
        return null;
      }
      
      // 反序列化资源数据
      final resourcesJson = cachedData['resources'] as List;
      final resources = resourcesJson.map((json) {
        final resource = ParseObject('Resource');
        resource.fromJson(json);
        return resource;
      }).toList();
      
      debugPrint('从缓存获取了 ${resources.length} 条资源记录');
      return resources;
    } catch (e) {
      debugPrint('获取缓存资源数据失败: $e');
      return null;
    }
  }
  
  // 强制刷新资源数据（忽略缓存）
  Future<List<ParseObject>?> refreshResources() async {
    try {
      _isConnectionFailed = false; // 重置连接状态
      debugPrint('强制刷新资源数据');
      final query = QueryBuilder<ParseObject>(ParseObject('Resource'));
      final response = await query.query();
      
      if (response.success && response.results != null) {
        final results = response.results as List<ParseObject>;
        
        // 更新缓存
        _cacheResources(results);
        return results;
      }
      throw Exception('刷新资源失败');
    } catch (e) {
      debugPrint('刷新资源数据失败: $e');
      _isConnectionFailed = true;
      return await _getCachedResources(ignoreExpiry: true);
    }
  }
}
