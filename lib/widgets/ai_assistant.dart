import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_markdown/flutter_markdown.dart';

class AIAssistantDialog extends StatefulWidget {
  const AIAssistantDialog({super.key});

  @override
  State<AIAssistantDialog> createState() => _AIAssistantDialogState();
}

class _AIAssistantDialogState extends State<AIAssistantDialog> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<String> _getAIResponse(String message) async {
    // Must API 文档推荐的通用免费模型（见《WeMust AI API 使⽤指南》）
    const apiKey = 'sk-051c5f8f-d551-4dff-8935-2c8a7a26501c';
    const apiUrl = 'https://ai-apigateway.must.edu.mo/openhub/v1/chat/completions';
    const model = 'glm-4.5-flash';

    try {
      // 构建消息历史
      final List<Map<String, String>> messageHistory = [];
      for (var msg in _messages) {
        messageHistory.add({
          'role': msg['type'] == 'user' ? 'user' : 'assistant',
          'content': msg['message']!
        });
      }
      // 添加当前消息
      messageHistory.add({
        'role': 'user',
        'content': message
      });

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          'model': model,
          'messages': messageHistory,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = utf8.decode(response.bodyBytes);
        debugPrint('Raw response: $responseBody');
        
        final data = jsonDecode(responseBody);
        final content = data['choices'][0]['message']['content'] as String;
        debugPrint('Decoded content: $content');
        
        return content;
      } else {
        debugPrint('Error status code: ${response.statusCode}');
        debugPrint('Error response: ${response.body}');
        return '抱歉，我遇到了一些问题。请稍后再试。';
      }
    } catch (e) {
      debugPrint('Error in _getAIResponse: $e');
      return '抱歉，我遇到了一些问题。请稍后再试。';
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text;
    _messageController.clear();

    setState(() {
      _messages.add({
        'type': 'user',
        'message': userMessage,
      });
      _isLoading = true;
    });
    _scrollToBottom();

    final aiResponse = await _getAIResponse(userMessage);

    setState(() {
      _messages.add({
        'type': 'ai',
        'message': aiResponse,
      });
      _isLoading = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isLoading) {
                  return const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }
                final message = _messages[index];
                final isUser = message['type'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: isUser
                        ? Text(
                            message['message']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          )
                        : MarkdownBody(
                            data: message['message']!,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                height: 1.5,
                              ),
                              code: TextStyle(
                                backgroundColor: Colors.grey[300],
                                color: Colors.black87,
                                fontSize: 14,
                                fontFamily: 'monospace',
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              blockquote: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                height: 1.5,
                              ),
                            ),
                            selectable: true,
                          ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 10,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: '输入你的问题...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 0),
                    ),
                    keyboardType: TextInputType.multiline,
                    maxLines: null,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 16),
                    onSubmitted: (value) {
                      if (!_isLoading) {
                        _sendMessage();
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  color: Theme.of(context).primaryColor,
                  onPressed: _isLoading ? null : _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 
