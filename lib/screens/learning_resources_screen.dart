import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import 'resource_details.dart';
import '../models/resource.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../repositories/resource_repository.dart';

class LearningResourcesScreen extends StatefulWidget {
  const LearningResourcesScreen({super.key});

  @override
  State<LearningResourcesScreen> createState() => _LearningResourcesScreenState();
}

class _LearningResourcesScreenState extends State<LearningResourcesScreen> {
  String _selectedCategory = '全部';
  String _selectedCollege = '全部';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final ResourceRepository _resourceRepository = ResourceRepository();
  List<ParseObject> _resources = [];
  bool _isLoading = true;
  String _errorMessage = '';
  bool _usingLocalData = false;

  // 本地数据作为备份
  final List<Map<String, dynamic>> _localResources = [
    {
      'objectId': '1',
      'title': '数据结构',
      'description': '魏老师的数据结构与算法基础课程笔记，适合初学者学习',
      'type': '笔记',
      'category': '数据结构',
      'imageUrl': 'https://picsum.photos/200/300?random=1',
      'author': '魏老师',
      'college': '创新工程学院',
      'viewCount': 120,
      'rating': 5.0,
    },
    {
      'objectId': '2',
      'title': '算法分析与设计教程视频',
      'description': 'Ricardo老师老师讲解算法分析与设计的视频课程，包含多种经典算法的详细分析',
      'type': '视频',
      'category': '算法',
      'imageUrl': 'https://picsum.photos/200/300?random=2',
      'author': 'Ricardo老师',
      'college': '创新工程学院',
      'viewCount': 208,
      'rating': 2.8,
      'duration': '45:30',
    },
    {
      'objectId': '3',
      'title': '软件工程',
      'description': '黄老师编著的软件工程教材，内容丰富，案例详实',
      'type': '教材',
      'category': '软件工程',
      'imageUrl': 'https://picsum.photos/200/300?random=3',
      'author': '黄老师',
      'college': '创新工程学院',
      'viewCount': 156,
      'rating': 4.2,
    },
    {
      'objectId': '4',
      'title': '数据库优化指南',
      'description': '魏老师的数据库优化笔记，包含MySQL、PostgreSQL等多种数据库的优化技巧',
      'type': '笔记',
      'category': '数据库',
      'imageUrl': 'https://picsum.photos/200/300?random=4',
      'author': '魏老师',
      'college': '创新工程学院',
      'viewCount': 98,
      'rating': 5.0,
    }
  ];

  // 添加学院列表
  final List<String> _colleges = [
    '全部',
    '创新工程学院',
    '商学院',
    '国际学院',
  ];

  // 添加不同学院的标签映射
  final Map<String, List<String>> _collegeCategories = {
    '全部': [
      '全部',
      '数据结构',
      '算法',
      '软件工程',
      '数据库',
      '前端开发',
      '后端开发'
    ],
    '创新工程学院': [
      '全部',
      '数据结构',
      '算法',
      '软件工程',
      '数据库',
      '前端开发',
      '后端开发'
    ],
    '商学院': [
      '全部',
      '会计',
      '金融',
      '市场营销',
      '经济学',
      '管理学'
    ],
    '国际学院': [
      '全部',
      '国际贸易',
      '商务英语',
      '跨文化管理',
      '国际金融'
    ],
  };

  void _showCollegeSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '选择学院',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[800],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: _colleges.length,
                  itemBuilder: (context, index) {
                    final college = _colleges[index];
                    return ListTile(
                      title: Text(college),
                      trailing: _selectedCollege == college
                          ? Icon(Icons.check, color: AppColors.primary)
                          : null,
                      onTap: () {
                        setState(() {
                          _selectedCollege = college;
                          // 重置分类选择
                          _selectedCategory = '全部';
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    
    // 使用 Future.delayed 来确保 UI 已经渲染完成
    Future.delayed(Duration.zero, () {
      _loadResourcesFromCache();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // 从缓存加载资源
  Future<void> _loadResourcesFromCache() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      debugPrint('开始加载资源数据...');
      final result = await _resourceRepository.fetchResources();
      
      if (!mounted) return;
      
      if (result != null && result.isNotEmpty) {
        setState(() {
          _resources = result;
          _usingLocalData = false;
          _isLoading = false;
        });
      } else {
        debugPrint('没有获取到资源数据，使用本地数据');
        _useLocalData();
      }
    } catch (e) {
      debugPrint('加载资源数据失败: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = '加载失败，请检查网络连接';
      });
      _useLocalData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 使用本地数据
  void _useLocalData() {
    debugPrint('使用本地数据作为备份');
    if (!mounted) return;
    
    setState(() {
      _usingLocalData = true;
      _resources = _localResources.map((data) {
        final obj = ParseObject('Resource');
        data.forEach((key, value) {
          obj.set(key, value);
        });
        return obj;
      }).toList();
      _isLoading = false;
    });
  }

  // 刷新数据
  Future<void> _refreshData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final result = await _resourceRepository.refreshResources();
      
      if (!mounted) return;
      
      if (result != null && result.isNotEmpty) {
        setState(() {
          _resources = result;
          _usingLocalData = false;
          _isLoading = false;
        });
      } else {
        debugPrint('刷新失败，使用本地数据');
        _useLocalData();
      }
    } catch (e) {
      debugPrint('刷新资源数据失败: $e');
      if (!mounted) return;
      setState(() {
        _errorMessage = '刷新失败，请检查网络连接';
      });
      _useLocalData();
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // 创建示例资源数据
  // ignore: unused_element
  Future<void> _createSampleResources() async {
    try {
      debugPrint('开始创建示例资源数据...');
      
      // 创建笔记资源
      await _resourceRepository.createResource(
        DateTime.now().millisecondsSinceEpoch, 
        '数据结构与算法基础笔记', 
        '张老师的数据结构与算法基础课程笔记，适合初学者学习', 
        'https://picsum.photos/200/300?random=1', 
        '笔记', 
        1
      );
      
      // 创建视频资源
      await _resourceRepository.createResource(
        DateTime.now().millisecondsSinceEpoch + 1, 
        '算法分析与设计教程视频', 
        '李老师讲解算法分析与设计的视频课程，包含多种经典算法的详细分析', 
        'https://picsum.photos/200/300?random=2', 
        '视频', 
        2
      );
      
      // 创建教材资源
      await _resourceRepository.createResource(
        DateTime.now().millisecondsSinceEpoch + 2, 
        '系统设计实践教材', 
        '王老师编著的系统设计实践教材，内容丰富，案例详实', 
        'https://picsum.photos/200/300?random=3', 
        '教材', 
        3
      );
      
      debugPrint("示例资源创建成功");
    } catch (e) {
      debugPrint('创建示例资源失败: $e');
    }
  }

  // 修改筛选逻辑，并转换为Resource对象
  List<Resource> _getFilteredResources() {
    // 如果正在加载，直接返回空列表
    if (_isLoading) {
      return [];
    }
    
    return _resources.where((resource) {
      final resourceType = resource.get<String>('type') ?? '';
      final resourceCollege = resource.get<String>('college') ?? '';
      final title = resource.get<String>('title') ?? '';
      final description = resource.get<String>('description') ?? '';
      final category = resource.get<String>('category') ?? resourceType; // 如果没有类别，使用类型
      
      final matchesCategory = _selectedCategory == '全部' || category == _selectedCategory;
      final matchesCollege = _selectedCollege == '全部' || resourceCollege == _selectedCollege;
      final matchesSearch = _searchQuery.isEmpty ||
          title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          description.toLowerCase().contains(_searchQuery.toLowerCase());
          
      return matchesCategory && matchesCollege && matchesSearch;
    }).map((parseObject) => Resource.fromParseObject(parseObject)).toList();
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
        title: Text(
          _selectedCollege,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.school, color: Colors.black87),
            onPressed: () => _showCollegeSelector(context),
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
            color: const Color(0xFFFFE4D4),
          ),
          Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                color: const Color(0xFFFFE4D4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "探索学习资源",
                      style: TextStyle(
                        fontSize: 28.0,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: '搜索学习资源...',
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey[400]),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: Icon(Icons.clear, color: Colors.grey[400]),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildCategoryChips(),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                  child: _isLoading
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text(
                            '正在加载资源...',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    )
                  : _errorMessage.isNotEmpty && !_usingLocalData
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 72, color: Colors.red[300]),
                            const SizedBox(height: 16),
                            Text(
                              _errorMessage,
                              style: TextStyle(
                                fontSize: 16.0,
                                color: Colors.red[700],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: _refreshData,
                              child: const Text('重试'),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedCategory == '全部' ? "推荐资源" : "$_selectedCategory资源",
                                  style: TextStyle(
                                    fontSize: 20.0,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                if (_usingLocalData)
                                  Chip(
                                    label: const Text('使用本地数据'),
                                    backgroundColor: Colors.amber[100],
                                    labelStyle: TextStyle(color: Colors.amber[900], fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: _buildResourceList(),
                          ),
                        ],
                      ),
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshData,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildCategoryChips() {
    // 获取当前选中学院的标签列表
    final categories = _collegeCategories[_selectedCollege] ?? _collegeCategories['全部']!;

    return SizedBox(
      height: 50.0,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: categories.map((category) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(category),
                selected: _selectedCategory == category,
                selectedColor: AppColors.primary.withValues(alpha: 0.2),
                checkmarkColor: AppColors.primary,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = selected ? category : '全部';
                  });
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildResourceList() {
    final filteredResources = _getFilteredResources();
    
    if (filteredResources.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              "没有找到符合条件的资源",
              style: TextStyle(
                fontSize: 18.0,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      itemCount: filteredResources.length,
      itemBuilder: (context, index) {
        final resource = filteredResources[index];
        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResourceDetails(resource: resource),
              ),
            );
          },
          child: _buildResourceCard(resource),
        );
      },
    );
  }

  Widget _buildResourceCard(Resource resource) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16.0),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ResourceDetails(resource: resource),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 60.0,
                      height: 60.0,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Icon(
                        _getIconForCategory(resource.type),
                        color: AppColors.primary,
                        size: 30.0,
                      ),
                    ),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            resource.title,
                            style: const TextStyle(
                              fontSize: 18.0,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            resource.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14.0,
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 16.0,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                resource.author,
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(width: 16.0),
                              Icon(
                                Icons.remove_red_eye_outlined,
                                size: 16.0,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4.0),
                              Text(
                                '${resource.viewCount}次观看',
                                style: TextStyle(
                                  fontSize: 12.0,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getIconForCategory(String type) {
    switch (type.toLowerCase()) {
      case '笔记':
        return Icons.note;
      case '视频':
        return Icons.video_library;
      case '教材':
        return Icons.book;
      default:
        return Icons.description;
    }
  }
}
