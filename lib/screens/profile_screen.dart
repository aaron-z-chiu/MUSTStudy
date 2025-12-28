import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/userinfo_respositories.dart';
import '../routes/app_router.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserinfoRepository _userinfoRepository = UserinfoRepository();
  bool _isLoading = true;
  String _username = '未登录';
  String _level = 'Lv.1 初学者';
  int _userId = 0;
  
  // 学习统计数据
  Map<String, dynamic> _statistics = {
    'studyHours': 0,
    'solvedProblems': 0,
    'achievements': 0,
  };

  // 缓存键
  static const String _userInfoCacheKey = 'cached_user_info';
  static const String _userStatsCacheKey = 'cached_user_stats';
  static const Duration _cacheDuration = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    // 先尝试从缓存加载数据
    _loadCachedData().then((_) {
      // 然后从网络加载最新数据
      _loadUserData();
    });
  }

  // 从缓存加载数据
  Future<void> _loadCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 加载缓存的用户信息
      final cachedUserInfo = prefs.getString(_userInfoCacheKey);
      if (cachedUserInfo != null) {
        final userInfo = jsonDecode(cachedUserInfo);
        setState(() {
          _username = userInfo['username'] ?? '未登录';
          _userId = userInfo['userId'] ?? 0;
        });
      }
      
      // 加载缓存的统计数据
      final cachedStats = prefs.getString(_userStatsCacheKey);
      if (cachedStats != null) {
        final stats = jsonDecode(cachedStats);
        setState(() {
          _statistics = stats;
          _level = _userinfoRepository.getUserLevel(stats['solvedProblems']);
        });
      }
    } catch (e) {
      debugPrint('加载缓存数据失败: $e');
    }
  }

  // 保存数据到缓存
  Future<void> _cacheUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 缓存用户信息
      final userInfo = {
        'username': _username,
        'userId': _userId,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_userInfoCacheKey, jsonEncode(userInfo));
      
      // 缓存统计数据
      final stats = {
        ..._statistics,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString(_userStatsCacheKey, jsonEncode(stats));
    } catch (e) {
      debugPrint('缓存数据失败: $e');
    }
  }

  // 检查缓存是否过期
  // ignore: unused_element
  bool _isCacheExpired(int timestamp) {
    final cacheTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return DateTime.now().difference(cacheTime) > _cacheDuration;
  }

  // 加载用户数据
  Future<void> _loadUserData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      // 从SharedPreferences获取当前登录的用户ID
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('currentUsername') ?? '';
      
      if (username.isNotEmpty) {
        // 并行加载用户信息和统计数据
        await Future.wait([
          _loadUserInfo(username),
          _loadUserStatistics(_userId),
        ]);
        
        // 保存到缓存
        _cacheUserData();
      } else {
        debugPrint('未登录或无用户信息');
        _loadTestUserData();
      }
    } catch (e) {
      debugPrint('加载用户数据失败: $e');
      _loadTestUserData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 加载用户信息
  Future<void> _loadUserInfo(String username) async {
    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Userinfo'))
        ..whereEqualTo('u_name', username);
      final response = await query.query();
      
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        final userObj = response.results!.first as ParseObject;
        
        if (!mounted) return;
        setState(() {
          _username = userObj.get<String>('u_name') ?? '未知用户';
          _userId = userObj.get<int>('u_id') ?? 0;
        });
      } else {
        debugPrint('未找到用户信息');
        _loadTestUserData();
      }
    } catch (e) {
      debugPrint('加载用户信息失败: $e');
      _loadTestUserData();
    }
  }

  // 加载用户统计数据
  Future<void> _loadUserStatistics(int userId) async {
    try {
      // 从后端获取用户的学习统计数据
      final userStats = await _userinfoRepository.getUserStatistics(userId);
      
      if (!mounted) return;
      setState(() {
        _statistics = userStats;
        _level = _userinfoRepository.getUserLevel(userStats['solvedProblems']);
      });
    } catch (e) {
      debugPrint('加载用户统计数据失败: $e');
      // 使用模拟数据作为备选
      if (!mounted) return;
      setState(() {
        if (userId == 1) { // test用户
          _statistics = {
            'studyHours': 120,
            'solvedProblems': 256,
            'achievements': 15,
          };
          _level = 'Lv.5 勤奋学习者';
        } else { // admin用户或其他用户
          _statistics = {
            'studyHours': 85,
            'solvedProblems': 178,
            'achievements': 10,
          };
          _level = 'Lv.4 进阶者';
        }
      });
    }
  }

  // 登出
  Future<void> _logout() async {
    try {
      // 清除登录状态
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('currentUsername');
      
      // 更新路由守卫状态
      RouteGuard.setLoggedIn(false);
      
      // 跳转到登录页面
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        RouteNames.login,
        (route) => false,
      );
    } catch (e) {
      debugPrint('登出失败: $e');
    }
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
      body: _isLoading
      ? _buildSkeletonLoading()
      : Stack(
        children: [
          Container(
            height: 300,
            width: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/img.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          Column(
            children: [
              // 顶部个人信息
              SafeArea(
                child: Container(
                  padding: const EdgeInsets.only(top: 20, bottom: 30),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(
                          'https://ui-avatars.com/api/?name=$_username&background=random',
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _username,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _level,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 内容区域
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF8F3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          const SizedBox(height: 20),
                          _buildStatisticsCard(),
                          const SizedBox(height: 16),
                          _buildFunctionList(),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '学习数据',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // 添加刷新按钮
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () async {
                  // 刷新用户统计数据
                  if (_userId > 0) {
                    setState(() {
                      _isLoading = true;
                    });
                    await _loadUserStatistics(_userId);
                    if (!mounted) return;
                    setState(() {
                      _isLoading = false;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('数据已刷新')),
                    );
                  }
                },
                tooltip: '刷新数据',
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatisticsItem(
                icon: Icons.timer,
                value: _statistics['studyHours'].toString(),
                label: '学习时长(h)',
                color: Colors.blue[700]!,
              ),
              _buildStatisticsItem(
                icon: Icons.assignment_turned_in,
                value: _statistics['solvedProblems'].toString(),
                label: '已解题目',
                color: Colors.green[700]!,
              ),
              _buildStatisticsItem(
                icon: Icons.emoji_events,
                value: _statistics['achievements'].toString(),
                label: '获得成就',
                color: Colors.orange[700]!,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return GestureDetector(
      onTap: () {
        if (icon == Icons.emoji_events) {
          Navigator.pushNamed(context, RouteNames.achievementList);
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
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
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
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
      ),
    );
  }

  Widget _buildFunctionList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        children: [
          _buildFunctionItem(
            icon: Icons.trending_up,
            title: '模拟学习',
            onTap: () {
              // 模拟增加学习时长
              if (_userId > 0) {
                _simulateStudy();
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('请先登录')),
                );
              }
            },
          ),
          _buildDivider(),
          _buildFunctionItem(
            icon: Icons.favorite_border,
            title: '我的收藏',
            onTap: () {
              // 跳转到收藏页面
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('我的收藏功能即将上线')),
              );
            },
          ),
          _buildDivider(),
          _buildFunctionItem(
            icon: Icons.history,
            title: '学习记录',
            onTap: () {
              Navigator.pushNamed(context, RouteNames.studyRecord);
            },
          ),
          _buildDivider(),
          _buildFunctionItem(
            icon: Icons.emoji_events_outlined,
            title: '我的成就',
            onTap: () {
              // 跳转到成就页面
              Navigator.pushNamed(context, RouteNames.achievements);
            },
          ),
          _buildDivider(),
          _buildFunctionItem(
            icon: Icons.settings_outlined,
            title: '设置',
            onTap: () {
              Navigator.pushNamed(context, RouteNames.settings);
            },
          ),
          _buildDivider(),
          _buildFunctionItem(
            icon: Icons.logout,
            title: '退出登录',
            onTap: () {
              // 显示登出确认对话框
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('确认退出'),
                  content: const Text('确定要退出登录吗？'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('取消'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _logout();
                      },
                      child: const Text('确定'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFunctionItem({
    required IconData icon,
    required String title,
    required Function() onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Colors.grey[700],
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[400],
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 20,
      endIndent: 20,
      color: Colors.grey[200],
    );
  }

  // 模拟学习功能
  Future<void> _simulateStudy() async {
    int selectedHours = 0;
    int selectedMinutes = 0;

    // 显示选择学习时长的对话框
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.timer_outlined,
                color: Colors.blue[700],
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '选择要增加的学习时长',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '滑动选择时间',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.normal,
              ),
            ),
          ],
        ),
        content: Container(
          height: 180,
          width: 280,
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 小时选择器
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '小时',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 40,
                        useMagnifier: true,
                        magnification: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          selectedHours = index;
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            return Container(
                              alignment: Alignment.center,
                              child: Text(
                                index.toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                          childCount: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // 分隔符
              Container(
                height: 100,
                width: 1,
                color: Colors.grey[300],
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              // 分钟选择器
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '分钟',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListWheelScrollView.useDelegate(
                        itemExtent: 40,
                        useMagnifier: true,
                        magnification: 1.2,
                        physics: const FixedExtentScrollPhysics(),
                        onSelectedItemChanged: (index) {
                          selectedMinutes = index * 5;
                        },
                        childDelegate: ListWheelChildBuilderDelegate(
                          builder: (context, index) {
                            return Container(
                              alignment: Alignment.center,
                              child: Text(
                                (index * 5).toString(),
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue[700],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                          childCount: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.grey[600],
                ),
                child: const Text(
                  '取消',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  
                  if (selectedHours == 0 && selectedMinutes == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('请选择学习时长')),
                    );
                    return;
                  }

                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  // 显示加载中
                  setState(() {
                    _isLoading = true;
                  });

                  try {
                    // 将分钟转换为小时（保留一位小数）
                    final hours = selectedHours + (selectedMinutes / 60);
                    
                    // 更新学习时长
                    final success = await _userinfoRepository.updateStudyHours(_userId, hours);

                    if (!mounted) return;

                    if (success) {
                      // 刷新数据
                      await _loadUserStatistics(_userId);

                      if (!mounted) return;
                      scaffoldMessenger.showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(Icons.check_circle, color: Colors.white),
                              const SizedBox(width: 8),
                              Text('成功增加 $selectedHours 小时 $selectedMinutes 分钟学习时长'),
                            ],
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('增加学习时长失败'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    debugPrint('增加学习时长失败: $e');
                    if (!mounted) return;
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(
                        content: Text('增加学习时长失败'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    if (mounted) {
                      setState(() {
                        _isLoading = false;
                      });
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  '确定',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 加载测试用户数据
  void _loadTestUserData() {
    setState(() {
      // 使用登录页面里的测试用户数据
      _username = 'test';
      _userId = 1;
      _level = 'Lv.5 勤奋学习者';
      
      // 加载测试统计数据
      _loadUserStatistics(_userId);
    });
  }

  // 骨架屏加载效果
  Widget _buildSkeletonLoading() {
    return Stack(
      children: [
        Container(
          height: 300,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/img.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Column(
          children: [
            // 顶部个人信息骨架屏
            SafeArea(
              child: Container(
                padding: const EdgeInsets.only(top: 20, bottom: 30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: 120,
                      height: 24,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      width: 100,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // 内容区域骨架屏
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(30),
                ),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F3),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildSkeletonStatisticsCard(),
                        const SizedBox(height: 16),
                        _buildSkeletonFunctionList(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // 统计数据卡片骨架屏
  Widget _buildSkeletonStatisticsCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 80,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(3, (index) => _buildSkeletonStatItem()),
          ),
        ],
      ),
    );
  }

  // 统计项目骨架屏
  Widget _buildSkeletonStatItem() {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 40,
          height: 20,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 60,
          height: 16,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ],
    );
  }

  // 功能列表骨架屏
  Widget _buildSkeletonFunctionList() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
      child: Column(
        children: List.generate(
          6,
          (index) => _buildSkeletonFunctionItem(),
        ),
      ),
    );
  }

  // 功能项目骨架屏
  Widget _buildSkeletonFunctionItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 16,
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Container(
            width: 100,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const Spacer(),
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}
