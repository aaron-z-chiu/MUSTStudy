import 'package:flutter/material.dart';

class SettingsLanguageScreen extends StatelessWidget {
  const SettingsLanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语言设置'),
      ),
      body: const Center(
        child: Text('语言设置页面'),
      ),
    );
  }
} 