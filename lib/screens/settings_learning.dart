import 'package:flutter/material.dart';

class SettingsLearningScreen extends StatelessWidget {
  const SettingsLearningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习设置'),
      ),
      body: const Center(
        child: Text('学习设置页面'),
      ),
    );
  }
} 