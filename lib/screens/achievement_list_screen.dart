import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/achievement.dart';
import '../repositories/achievement_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class AchievementListScreen extends StatefulWidget {
  const AchievementListScreen({super.key});

  @override
  State<AchievementListScreen> createState() => _AchievementListScreenState();
}

class _AchievementListScreenState extends State<AchievementListScreen> {
  final AchievementRepository _achievementRepository = AchievementRepository();
  List<Achievement> _achievements = [];
  bool _isLoading = true;
  int _totalAchievements = 0;
  int _unlockedAchievements = 0;
  
  @override
  void initState() {
    super.initState();
    // 使用 Future.delayed 确保 UI 已经渲染完成
    Future.delayed(Duration.zero, () {
      _loadAchievements();
    });
  }
  
  Future<void> _loadAchievements() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // 从SharedPreferences获取当前登录的用户信息
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('currentUsername') ?? '';
      
      if (username.isNotEmpty) {
        // 获取用户ID
        final userId = await _getUserId(username);
        
        // 使用用户ID获取成就
        final parseAchievements = await _achievementRepository.fetchAchievements(userId);
        
        if (!mounted) return;
        
        if (parseAchievements.isNotEmpty) {
          final achievements = parseAchievements.map((parseObj) => Achievement.fromParseObject(parseObj)).toList();
          _updateAchievementStats(achievements);
          setState(() {
            _achievements = achievements;
            _isLoading = false;
          });
        } else {
          // 如果没有成就数据，使用默认成就
          _loadDefaultAchievements();
        }
      } else {
        // 未登录，使用默认成就
        _loadDefaultAchievements();
      }
    } catch (e) {
      debugPrint('Error loading achievements: $e');
      _loadDefaultAchievements();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 获取用户ID
  Future<int> _getUserId(String username) async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Userinfo'))
        ..whereEqualTo('u_name', username);
      final userResponse = await query.query();
      
      if (userResponse.success && userResponse.results != null && userResponse.results!.isNotEmpty) {
        final userObj = userResponse.results!.first as ParseObject;
        return userObj.get<int>('u_id') ?? 1;
      }
      return 1; // 默认使用ID为1
    } catch (e) {
      debugPrint('Error getting user ID: $e');
      return 1;
    }
  }

  // 加载默认成就
  void _loadDefaultAchievements() {
    if (!mounted) return;
    
    setState(() {
      _achievements = [];
      _isLoading = false;
    });
  }

  void _updateAchievementStats(List<Achievement> achievements) {
    _totalAchievements = achievements.length;
    _unlockedAchievements = achievements.where((a) => !a.isLocked).length;
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0xFFFFE4D4),
      statusBarIconBrightness: Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: const Color(0xFFFFE4D4),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFE4D4),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '探险成就',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
      ? const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                '正在加载成就数据...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        )
      : Stack(
        children: [
          Container(
            color: const Color(0xFFFFE4D4),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: _buildAchievementStats(),
              ),
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    child: _achievements.isEmpty
                    ? _buildDefaultCategories()
                    : _buildUserAchievements(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementStats() {
    final completionPercentage = _totalAchievements > 0 
        ? (_unlockedAchievements / _totalAchievements * 100).toStringAsFixed(2) 
        : '0.00';
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildStatItem('已获得成就', '$_unlockedAchievements/$_totalAchievements', Icons.emoji_events_outlined),
        Container(
          width: 1,
          height: 40,
          color: Colors.black12,
        ),
        _buildStatItem('完成度', '$completionPercentage%', Icons.pie_chart_outline),
        Container(
          width: 1,
          height: 40,
          color: Colors.black12,
        ),
        _buildStatItem('探险点数', '${_unlockedAchievements * 100}', Icons.star_outline),
      ],
    );
  }
  
  Widget _buildUserAchievements() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        final achievement = _achievements[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 15),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              if (achievement.isLocked)
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(15),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: achievement.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        achievement.icon,
                        color: achievement.isLocked ? Colors.grey : achievement.color,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: achievement.isLocked ? Colors.grey : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            achievement.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(5),
                            child: LinearProgressIndicator(
                              value: achievement.progressPercentage,
                              backgroundColor: Colors.grey[200],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                achievement.isLocked ? Colors.grey : AppColors.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (achievement.isLocked)
                      const Icon(
                        Icons.lock,
                        color: Colors.grey,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDefaultCategories() {
    return Column(
      children: [
        _buildAchievementCategory('亚洲探险', _asiaAchievements),
        _buildAchievementCategory('欧洲探险', _europeAchievements),
        _buildAchievementCategory('美洲探险', _americaAchievements),
        _buildAchievementCategory('大洋洲探险', _oceaniaAchievements),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCategory(String title, List<Map<String, dynamic>> achievements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
        ListView.builder(
          padding: EdgeInsets.zero,
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 15, left: 20, right: 20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  if (achievement['isLocked'] as bool)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: (achievement['color'] as Color?)?.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            achievement['icon'] as IconData,
                            color: achievement['isLocked'] as bool
                                ? Colors.grey
                                : achievement['color'] as Color?,
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                achievement['title'] as String,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: achievement['isLocked'] as bool
                                      ? Colors.grey
                                      : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                achievement['description'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              if (achievement['progress'] != null) ...[
                                const SizedBox(height: 8),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(5),
                                  child: LinearProgressIndicator(
                                    value: achievement['progress'] as double,
                                    backgroundColor: Colors.grey[200],
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      achievement['isLocked'] as bool
                                          ? Colors.grey
                                          : AppColors.primary,
                                    ),
                                    minHeight: 6,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (achievement['isLocked'] as bool)
                          const Icon(
                            Icons.lock,
                            color: Colors.grey,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // 亚洲地区成就
  static final List<Map<String, dynamic>> _asiaAchievements = [
    {
      'title': '长城探险家',
      'description': '累计完成30次收藏',
      'icon': Icons.landscape,
      'color': Colors.blue[700],
      'isLocked': false,
      'progress': 0.5,
    },
    {
      'title': '泰姬陵探险家',
      'description': '连续学习7天',
      'icon': Icons.mosque,
      'color': Colors.pink[700],
      'isLocked': true,
      'progress': 0.0,
    },
    {
      'title': '富士山探险家',
      'description': '完成50道编程题',
      'icon': Icons.terrain,
      'color': Colors.red[700],
      'isLocked': true,
      'progress': 0.0,
    },
  ];

  // 欧洲地区成就
  static final List<Map<String, dynamic>> _europeAchievements = [
    {
      'title': '巴黎铁塔探险家',
      'description': '观看100个视频教程',
      'icon': Icons.tour,
      'color': Colors.purple[700],
      'isLocked': true,
      'progress': 0.0,
    },
    {
      'title': '罗马斗兽场探险家',
      'description': '参与20次讨论',
      'icon': Icons.account_balance,
      'color': Colors.orange[700],
      'isLocked': true,
      'progress': 0.0,
    },
    {
      'title': '圣家堂探险家',
      'description': '完成10次项目实践',
      'icon': Icons.church,
      'color': Colors.brown[700],
      'isLocked': true,
      'progress': 0.0,
    },
  ];

  // 美洲地区成就
  static final List<Map<String, dynamic>> _americaAchievements = [
    {
      'title': '自由女神探险家',
      'description': '获得100个点赞',
      'icon': Icons.emoji_flags,
      'color': Colors.green[700],
      'isLocked': true,
      'progress': 0.0,
    },
    {
      'title': '大峡谷探险家',
      'description': '完成30次笔记整理',
      'icon': Icons.landscape,
      'color': Colors.deepOrange[700],
      'isLocked': true,
      'progress': 0.0,
    },
    {
      'title': '马丘比丘探险家',
      'description': '解锁20个知识点',
      'icon': Icons.terrain,
      'color': Colors.teal[700],
      'isLocked': true,
      'progress': 0.0,
    },
  ];

  // 大洋洲地区成就
  static final List<Map<String, dynamic>> _oceaniaAchievements = [
    {
      'title': '悉尼歌剧院探险家',
      'description': '完成5次在线考试',
      'icon': Icons.theater_comedy,
      'color': Colors.red[700],
      'isLocked': true,
      'progress': 0.0,
    },
    {
      'title': '大堡礁探险家',
      'description': '收藏50个学习资源',
      'icon': Icons.waves,
      'color': Colors.blue[700],
      'isLocked': true,
      'progress': 0.0,
    },
    {
      'title': '艾尔斯岩探险家',
      'description': '完成15次小组学习',
      'icon': Icons.landscape,
      'color': Colors.amber[700],
      'isLocked': true,
      'progress': 0.0,
    },
  ];
} 