import 'package:flutter/material.dart';
import 'package:muststudy/widgets/ai_assistant.dart';

class AIAssistantScreen extends StatelessWidget {
  const AIAssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 助手'),
        centerTitle: true,
      ),
      body: const AIAssistantDialog(),
    );
  }
} 