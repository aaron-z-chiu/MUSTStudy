import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../repositories/q_tag_respositories.dart';
import '../repositories/question_respositories.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';

class ForumUpdateQuestionsScreen extends StatefulWidget {
  const ForumUpdateQuestionsScreen({super.key});

  @override
  State<ForumUpdateQuestionsScreen> createState() => _ForumUpdateQuestionsScreenState();
}

class _ForumUpdateQuestionsScreenState extends State<ForumUpdateQuestionsScreen> {
  // 学院和专业映射
  final List<String> _colleges = ['创新工程学院', '商学院', '法学院', '医学院'];
  // 专业映射
  final Map<String, List<String>> _majorMap = {
    '创新工程学院': ['计算机科学', '电子信息', '软件工程'],
    '商学院': ['A专业', 'B专业', 'C专业'],
    '法学院': ['A专业', 'B专业', 'C专业'],
    '医学院': ['A专业', 'B专业', 'C专业'],
  };
  final QtagRepository _qtagRepository = QtagRepository();
  final QuestionRepository _questionRepository = QuestionRepository();
  List<String> _existingTags = [];

  String _selectedCollege = '创新工程学院';
  String _selectedMajor = '计算机科学';
  String _selectedDifficulty = '中等';
  final List<String> _difficultyOptions = ['简单', '中等', '困难'];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _informationController = TextEditingController();
  final TextEditingController _tagController = TextEditingController();
  final RegExp _courseCodePattern = RegExp(r'^[A-Za-z]{2}\d{3}$');

  final ImagePicker _picker = ImagePicker();
  final List<XFile> _images = [];
  final List<String> _attributeTags = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 拉取已有标签用于自动补全
    _qtagRepository.fetchQtag().then((list) {
      if (list != null) {
        final tags = list
          .expand((obj) => _qtagRepository.parseTags(obj))
          .toSet()
          .toList();
        setState(() {
          _existingTags = tags;
        });
      }
    });
  }

  // 选择图片
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _images.add(image);
        });
      }
    } catch (e) {
      debugPrint('选择图片失败: $e');
    }
  }

  // 添加属性标签
  void _addTag() {
    final tag = _tagController.text.trim();
    if (tag.isNotEmpty && !_attributeTags.contains(tag)) {
      setState(() {
        _attributeTags.add(tag);
        _tagController.clear();
      });
    }
  }

  // 移除属性标签
  void _removeTag(String tag) {
    setState(() {
      _attributeTags.remove(tag);
    });
  }

  // 删除选中图片
  void _removeImage(XFile image) {
    setState(() {
      _images.remove(image);
    });
  }

  // 提交操作
  Future<void> _submit() async {
    final courseCode = _titleController.text.trim();
    final description = _descriptionController.text.trim();
    final information = _informationController.text.trim();

    if (courseCode.isEmpty || description.isEmpty || information.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写所有必填字段')),
      );
      return;
    }

    if (!_courseCodePattern.hasMatch(courseCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('课程编号格式需为两个字母+三个数字，例如 CS123')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 获取当前用户ID
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('currentUsername') ?? '';
      int userId = 1; // 默认用户ID

      if (username.isNotEmpty) {
        final query = QueryBuilder<ParseObject>(ParseObject('Userinfo'))
          ..whereEqualTo('u_name', username);
        final response = await query.query();
        
        if (response.success && response.results != null && response.results!.isNotEmpty) {
          final userObj = response.results!.first as ParseObject;
          userId = userObj.get<int>('u_id') ?? 1;
        }
      }

      // 生成唯一问题ID
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // 创建问题
      await _questionRepository.createQuestionItem(
        timestamp,
        userId,
        courseCode,
        information,
        0, // 初始点赞数为0
        description,
        _selectedDifficulty, // 用户选择的难度
        _attributeTags,
        _selectedCollege
      );

      // 为问题添加标签
      await _qtagRepository.createQtagItem(timestamp, _attributeTags);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('题目上传成功！')),
      );
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('上传题目失败: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('上传失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _informationController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('上传题目'),
        backgroundColor: const Color(0xFFFFE4D4),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('课程编号:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '请输入课程编号',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('选择学院:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: '选择学院'),
                      initialValue: _selectedCollege,
                      items: _colleges.map((c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedCollege = value;
                            _selectedMajor = _majorMap[_selectedCollege]!.first;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('选择专业:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: '选择专业'),
                      initialValue: _selectedMajor,
                      items: _majorMap[_selectedCollege]!.map((m) => DropdownMenuItem<String>(
                            value: m,
                            child: Text(m),
                          )).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedMajor = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('难度标签:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: '选择难度'),
                      value: _selectedDifficulty,
                      items: _difficultyOptions
                          .map((d) => DropdownMenuItem<String>(
                                value: d,
                                child: Text(d),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedDifficulty = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text('题目描述:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '请输入题目的简短描述',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('题目内容:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    TextFormField(
                      controller: _informationController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: '请输入题目内容',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('上传图片:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        // 已选图片预览
                        ..._images.map((img) => Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(File(img.path), width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            Positioned(
                              top: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _removeImage(img),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.4),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.remove, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        )),
                        // 添加图片占位
                        GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Center(
                              child: Icon(Icons.add, color: Colors.grey),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Autocomplete<String>(
                      optionsBuilder: (TextEditingValue value) {
                        final text = value.text;
                        if (!text.startsWith('#') || text.length < 2) return const Iterable<String>.empty();
                        final keyword = text.substring(1).toLowerCase();
                        return _existingTags
                          .where((tag) => tag.toLowerCase().contains(keyword))
                          .map((tag) => '#$tag');
                      },
                      fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
                        _tagController.text = controller.text;
                        return TextField(
                          controller: controller,
                          focusNode: focusNode,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            hintText: '#输入标签',
                          ),
                          onSubmitted: (_) => _addTag(),
                        );
                      },
                      onSelected: (String selection) {
                        _tagController.text = selection;
                        _addTag();
                      },
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: _attributeTags.map((tag) => Chip(
                        label: Text(tag),
                        onDeleted: () => _removeTag(tag),
                      )).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        child: const Text('上传题目'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
