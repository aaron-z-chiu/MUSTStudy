    import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SettingsContactScreen extends StatelessWidget {
  const SettingsContactScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF5E5),
      appBar: AppBar(
        title: const Text('联系'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 写邮件区域
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  title: const Text('写邮件'),
                  subtitle: const Text('muststudy250312@outlook.com', style: TextStyle(color: Colors.grey)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final Uri emailUri = Uri.parse('mailto:muststudy250312@outlook.com');
                    if (await canLaunchUrl(emailUri)) {
                      await launchUrl(emailUri, mode: LaunchMode.externalApplication);
                    } else {
                      messenger.showSnackBar(
                        const SnackBar(content: Text('无法打开邮件应用')),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '任何问题或建议，欢迎邮件联系我们',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 16),
              // 社交媒体区域
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    ListTile(title: const Text('小红书'), trailing: const Icon(Icons.chevron_right)),
                    const Divider(height: 1),
                    ListTile(title: const Text('抖音'), trailing: const Icon(Icons.chevron_right)),
                    const Divider(height: 1),
                    ListTile(title: const Text('公众号'), trailing: const Icon(Icons.chevron_right)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // 举报投诉
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  title: const Text('举报投诉'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: 16),
              // 提交错误日志
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ListTile(
                  title: const Text('提交错误日志'),
                  trailing: const Icon(Icons.chevron_right),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 