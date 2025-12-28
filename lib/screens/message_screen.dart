import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/app_footer.dart';

class MessageScreen extends StatefulWidget {
  const MessageScreen({super.key});

  @override
  State<MessageScreen> createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 设置状态栏颜色
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFFE4D4),
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFFFE4D4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4D4),
        elevation: 0,
        title: const Text(
          '消息中心',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFFFE4D4),
          ),
          Column(
            children: [
              Container(
                color: const Color(0xFFFFE4D4),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.grey[600],
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.label,
                    labelStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: const [
                      Tab(text: '系统通知'),
                      Tab(text: '互动消息'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F3),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSystemNotifications(),
                      _buildInteractionMessages(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSystemNotifications() {
    final notifications = [
      {
        'icon': Icons.star,
        'color': Colors.amber,
        'title': '获得新成就',
        'content': '恭喜你完成"编程高手"成就！',
        'time': '10分钟前',
        'isRead': false,
      },
      {
        'icon': Icons.emoji_events,
        'color': Colors.orange,
        'title': '每日任务完成',
        'content': '你已经连续学习3天，继续保持！',
        'time': '2小时前',
        'isRead': true,
      },
      {
        'icon': Icons.card_giftcard,
        'color': Colors.purple,
        'title': '新的学习资源',
        'content': '为你推荐5个精选算法题目',
        'time': '昨天',
        'isRead': true,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: notifications.length + 1,
      itemBuilder: (context, index) {
        if (index == notifications.length) {
          return const AppFooter();
        }
        final notification = notifications[index];
        return _buildMessageCard(
          icon: notification['icon'] as IconData,
          color: notification['color'] as Color,
          title: notification['title'] as String,
          content: notification['content'] as String,
          time: notification['time'] as String,
          isRead: notification['isRead'] as bool,
        );
      },
    );
  }

  Widget _buildInteractionMessages() {
    final messages = [
      {
        'avatar': 'https://ui-avatars.com/api/?name=张三&background=random',
        'name': '张三',
        'content': '回复了你的问题：这个解法思路很清晰！',
        'time': '5分钟前',
        'isRead': false,
      },
      {
        'avatar': 'https://ui-avatars.com/api/?name=李四&background=random',
        'name': '李四',
        'content': '在你的题解下评论：学习了，感谢分享',
        'time': '1小时前',
        'isRead': true,
      },
      {
        'avatar': 'https://ui-avatars.com/api/?name=王五&background=random',
        'name': '王五',
        'content': '赞了你的题解',
        'time': '昨天',
        'isRead': true,
      },
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: messages.length + 1,
      itemBuilder: (context, index) {
        if (index == messages.length) {
          return const AppFooter();
        }
        final message = messages[index];
        return _buildInteractionCard(
          avatar: message['avatar'] as String,
          name: message['name'] as String,
          content: message['content'] as String,
          time: message['time'] as String,
          isRead: message['isRead'] as bool,
        );
      },
    );
  }

  Widget _buildMessageCard({
    required IconData icon,
    required Color color,
    required String title,
    required String content,
    required String time,
    required bool isRead,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // TODO: 处理消息点击事件
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionCard({
    required String avatar,
    required String name,
    required String content,
    required String time,
    required bool isRead,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 10,
          ),
        ],
      ),
      child: InkWell(
        onTap: () {
          // TODO: 处理消息点击事件
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundImage: NetworkImage(avatar),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          time,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 
