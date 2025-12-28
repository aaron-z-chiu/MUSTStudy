import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';


class MessageRepository {
  Future<void> createMessage(int mid, int senderId, int receiverId,
      String content, DateTime timestamp) async {
    final message = ParseObject('Message')
      ..set('m_id', mid)
      ..set('sender_id', senderId)
      ..set('receiver_id', receiverId)
      ..set('content', content)
      ..set('timestamp', timestamp)
      ..set('is_read', false);
    final response = await message.save();
    if (!response.success) {
      throw Exception('Failed to create message: ${response.error?.message}');
    }
  }

  Future<List<ParseObject>> fetchMessages(int userId) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Message'))
      ..whereEqualTo('receiver_id', userId)
      ..orderByDescending('timestamp');
    final response = await query.query();
    if (response.success && response.results != null) {
      return response.results as List<ParseObject>;
    }
    throw Exception('Failed to fetch messages');
  }

  Future<void> markAsRead(int mid) async {
    final query = QueryBuilder<ParseObject>(ParseObject('Message'))
      ..whereEqualTo('m_id', mid);
    final response = await query.query();
    if (response.success && response.results != null) {
      final message = response.results!.first as ParseObject;
      message.set('is_read', true);
      await message.save();
    }
  }
}