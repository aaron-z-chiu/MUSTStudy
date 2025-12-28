import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/question_respositories.dart';
import '../repositories/q_tag_respositories.dart';
import '../theme/app_theme.dart';

class CreateProblemScreen extends StatefulWidget {
  const CreateProblemScreen({super.key});

  @override
  State<CreateProblemScreen> createState() => _CreateProblemScreenState();
}

class _CreateProblemScreenState extends State<CreateProblemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _informationController = TextEditingController();
  final _tagController = TextEditingController();
  
  final QuestionRepository _questionRepository = QuestionRepository();
  final QtagRepository _qtagRepository = QtagRepository();
  
  String _selectedDifficulty = '中等';
  String _selectedCollege = '创新工程学院';
  final List<String> _selectedTags = [];
  bool _isLoading = false;
  
  // 难度选项
  final List<String> _difficulties = ['简单', '中等', '困难'];
  
  // 学院选项
  final List<String> _colleges = [
    '创新工程学院',
    '商学院',
    '国际学院',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _informationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  // 添加标签
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagController.clear();
      });
    }
  }

  // 移除标签
  void _removeTag(String tag) {
    setState(() {
      _selectedTags.remove(tag);
    });
  }

  // 提交表单创建问题
  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      // 检查是否至少有一个标签
      if (_selectedTags.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请至少添加一个标签')),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });

      try {
        debugPrint('开始创建新题目...');
        // 获取当前用户ID
        final prefs = await SharedPreferences.getInstance();
        final username = prefs.getString('currentUsername') ?? '';
        debugPrint('当前用户名: $username');
        
        int userId = 1; // 默认用户ID
        
        if (username.isNotEmpty) {
          debugPrint('查询用户ID...');
          final query = QueryBuilder<ParseObject>(ParseObject('Userinfo'))
            ..whereEqualTo('u_name', username);
          final response = await query.query();
          
          if (response.success && response.results != null && response.results!.isNotEmpty) {
            final userObj = response.results!.first as ParseObject;
            userId = userObj.get<int>('u_id') ?? 1;
            debugPrint('获取到用户ID: $userId');
          } else {
            debugPrint('未找到用户信息，使用默认ID: 1');
          }
        } else {
          debugPrint('未登录，使用默认ID: 1');
        }
        
        // 生成唯一问题ID
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        debugPrint('生成题目ID: $timestamp');
        
        debugPrint('准备创建题目：');
        debugPrint('标题: ${_titleController.text}');
        debugPrint('描述: ${_descriptionController.text}');
        debugPrint('内容: ${_informationController.text}');
        debugPrint('难度: $_selectedDifficulty');
        debugPrint('学院: $_selectedCollege');
        debugPrint('标签: $_selectedTags');
        
        // 创建问题
        debugPrint('调用createQuestionItem...');
        await _questionRepository.createQuestionItem(
          timestamp,
          userId,
          _titleController.text,
          _informationController.text,
          0, // 初始点赞数为0
          _descriptionController.text,
          _selectedDifficulty,
          _selectedTags,
          _selectedCollege
        );
        debugPrint('题目创建成功');
        
        // 为问题添加标签
        debugPrint('调用createQtagItem...');
        await _qtagRepository.createQtagItem(timestamp, _selectedTags);
        debugPrint('标签添加成功');
        
        if (!mounted) return;
        
        // 创建成功，返回上一页
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('题目创建成功！')),
        );
        Navigator.pop(context, true); // 返回true表示创建成功
      } catch (e) {
        debugPrint('创建题目失败: $e');
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('创建失败: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建新题目'),
        backgroundColor: const Color(0xFFFFE4D4),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 标题
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: '题目标题',
                          border: OutlineInputBorder(),
                          hintText: '请输入题目标题',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入题目标题';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // 描述
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: '简短描述',
                          border: OutlineInputBorder(),
                          hintText: '请输入简短描述',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入简短描述';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // 详细信息
                      TextFormField(
                        controller: _informationController,
                        decoration: const InputDecoration(
                          labelText: '详细内容',
                          border: OutlineInputBorder(),
                          hintText: '请输入详细内容',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入详细内容';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // 选择难度
                      const Text('选择难度:'),
                      Wrap(
                        spacing: 8.0,
                        children: _difficulties.map((difficulty) {
                          return ChoiceChip(
                            label: Text(difficulty),
                            selected: _selectedDifficulty == difficulty,
                            onSelected: (selected) {
                              setState(() {
                                _selectedDifficulty = difficulty;
                              });
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.2),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      
                      // 选择学院
                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: '选择学院',
                          border: OutlineInputBorder(),
                        ),
                        initialValue: _selectedCollege,
                        items: _colleges.map((college) {
                          return DropdownMenuItem<String>(
                            value: college,
                            child: Text(college),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedCollege = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // 添加标签
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _tagController,
                              decoration: const InputDecoration(
                                labelText: '添加标签',
                                border: OutlineInputBorder(),
                                hintText: '请输入标签名称',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _addTag,
                            child: const Text('添加'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // 显示已选标签
                      Wrap(
                        spacing: 8.0,
                        runSpacing: 4.0,
                        children: _selectedTags.map((tag) {
                          return Chip(
                            label: Text(tag),
                            deleteIcon: const Icon(Icons.cancel, size: 16),
                            onDeleted: () => _removeTag(tag),
                            backgroundColor: Colors.blue[50],
                            labelStyle: TextStyle(color: Colors.blue[700]),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      
                      // 提交按钮
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('创建题目'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
} 