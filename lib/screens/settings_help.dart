import 'package:flutter/material.dart';

class SettingsHelpScreen extends StatelessWidget {
  const SettingsHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('使用帮助'),
      ),
      body: const Center(
        child: Text('使用帮助页面'),
      ),
    );
  }
} 