import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'forum_screen.dart';
import 'learning_resources_screen.dart';
import '../repositories/userinfo_respositories.dart';
import '../routes/app_router.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = ''; // Initialize with an empty string
  final UserinfoRepository _userinfoRepository = UserinfoRepository(); // Create an instance

  @override
  void initState() {
    super.initState();
    _fetchUserName(); // Fetch the user name when the widget initializes
  }

  void _fetchUserName() async {
    // Fetch the user name from the database
    String fetchedName = await _userinfoRepository.getUserName(1); // Pass the user ID
    setState(() {
      _userName = fetchedName;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 设置状态栏颜色
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 顶部背景图片
          Container(
            height: 1000,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/home_bg_old.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 顶部区域
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 欢迎语
                Text(
                  '你好，$_userName',
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          // 可拖拽的内容区域
          ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(30),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.85, // 初始大小为 30%
              minChildSize: 0.5, // 最小大小为 30%
              maxChildSize: 0.95, // 最大大小为 95%
              builder: (context, scrollController) {
                return Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(30),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Column(
                          children: [
                            // 拖拽指示器
                            Container(
                              margin: const EdgeInsets.symmetric(vertical: 12),
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                            _buildSearchBar(context),
                            const SizedBox(height: 20),
                            _buildMotivationCard(context),
                            const SizedBox(height: 20),
                            _buildQuickActions(context),
                            const SizedBox(height: 20),
                            _buildRecentActivities(context),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Icon(Icons.search, color: Colors.grey[400]),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: '搜索题目、资源...',
                hintStyle: TextStyle(color: Colors.grey[400]),
                border: InputBorder.none,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tune,
              color: Colors.white,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    final List<Map<String, dynamic>> actions = [
      {'icon': Icons.forum_outlined, 'label': '学习论坛', 'color': AppColors.coral},
      {'icon': Icons.chat_outlined, 'label': 'AI助手', 'color': AppColors.mint},
      {'icon': Icons.library_books_outlined, 'label': '学习资源', 'color': AppColors.skyBlue},
      {'icon': Icons.assignment_outlined, 'label': '练习题库', 'color': AppColors.peach},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '快速入口',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: actions.map((action) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: InkWell(
                    onTap: () {
                      if (action['label'] == '学习论坛') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ForumScreen()),
                        );
                      } else if (action['label'] == 'AI助手') {
                        Navigator.pushNamed(context, RouteNames.aiAssistant);
                      } else if (action['label'] == '学习资源') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const LearningResourcesScreen()),
                        );
                      }
                    },
                    child: Container(
                      width: 80,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (action['color'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            action['icon'] as IconData,
                            color: action['color'] as Color,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            action['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: action['color'] as Color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMotivationCard(BuildContext context) {
    final quotes = [
      {'text': '学习不是为了竞争，而是为了成为更好的自己', 'author': '— 孔子'},
      {'text': '每一个不曾起舞的日子，都是对生命的辜负', 'author': '— 尼采'},
      {'text': '知识就是力量，行动才是关键', 'author': '— 培根'},
      {'text': '学习是一个渐进的过程，不要期待一蹴而就', 'author': '— 李白'},
    ];

    final randomQuote = (quotes..shuffle()).first;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // 左侧图片
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              image: DecorationImage(
                image: AssetImage('assets/image copy 2.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 20),
          // 右侧文字
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  randomQuote['text']!,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  randomQuote['author']!,
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
    );
  }

  Widget _buildRecentActivities(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '最近活动',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityCard(
            icon: Icons.assignment_turned_in,
            title: '完成每日练习',
            subtitle: '算法基础 - 链表',
            time: '2小时前',
            color: AppColors.coral,
          ),
          _buildActivityCard(
            icon: Icons.forum,
            title: '发布了问题',
            subtitle: '如何理解动态规划？',
            time: '4小时前',
            color: AppColors.mint,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String time,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
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
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
        ],
      ),
    );
  }
}