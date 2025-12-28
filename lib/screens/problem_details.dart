import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repositories/question_respositories.dart';
import '../repositories/userinfo_respositories.dart';
import '../repositories/answer_respositories.dart';

class ProblemDetails extends StatefulWidget {
  final ParseObject problem;

  const ProblemDetails({
    super.key,
    required this.problem,
  });

  @override
  State<ProblemDetails> createState() => _ProblemDetailsState();
}

class _ProblemDetailsState extends State<ProblemDetails> {
  final TextEditingController _messageController = TextEditingController();
  final QuestionRepository _questionRepository = QuestionRepository();
  final UserinfoRepository _userinfoRepository = UserinfoRepository();
  final AnswerRespositories _answerRepository = AnswerRespositories();
  
  bool _isBookmarked = false;
  bool _isSolved = false;
  bool _isSubmitting = false;
  bool _isBookmarking = false;
  int _userId = 0;
  List<ParseObject> _answers = [];
  bool _isLoadingAnswers = false;

  @override
  void initState() {
    super.initState();
    _loadQuestionDetails();
    _loadCurrentUser();
  }
  
  // 加载当前用户信息
  Future<void> _loadCurrentUser() async {
    try {
      debugPrint('开始加载用户信息...');
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('currentUsername') ?? '';
      
      debugPrint('当前登录用户名: $username');
      if (username.isEmpty) {
        debugPrint('没有找到登录用户');
        return;
      }
      
      final query = QueryBuilder<ParseObject>(ParseObject('Userinfo'))
        ..whereEqualTo('u_name', username);
      final response = await query.query();
      
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        final userObj = response.results!.first as ParseObject;
        final userId = userObj.get<int>('u_id') ?? 0;
        
        debugPrint('成功获取用户ID: $userId');
        setState(() {
          _userId = userId;
        });
        
        // 检查问题是否已被收藏
        if (_userId > 0) {
          final questionId = widget.problem.get<int>('q_id') ?? 0;
          final isBookmarked = await _userinfoRepository.isQuestionBookmarked(_userId, questionId);
          
          setState(() {
            _isBookmarked = isBookmarked;
          });
          
          // 检查问题是否已完成
          await _checkIfSolved();
        } else {
          debugPrint('获取到的用户ID为0或无效');
        }
      } else {
        debugPrint('未找到用户信息: ${response.error?.message ?? "无错误信息"}');
        // 如果没有找到用户信息，尝试使用测试用户（假设ID为1）
        if (username == 'test' || username == 'admin') {
          debugPrint('使用默认测试用户ID: 1');
          setState(() {
            _userId = 1;
          });
        }
      }
    } catch (e) {
      debugPrint('加载用户信息异常: $e');
    }
  }

  // 检查问题是否已被解决
  Future<void> _checkIfSolved() async {
    try {
      // 为简化，我们可以检查用户是否对该问题有回答，或者有特定的"已解决"标记
      // 这里使用一个简化的逻辑，根据UserStatistics中的已解题目列表来判断
      if (_userId > 0) {
        await _userinfoRepository.getUserStatistics(_userId);
        
        // 获取回答
        final questionId = widget.problem.get<int>('q_id') ?? 0;
        final userAnswers = await _answerRepository.getAnswersByUserId(_userId);
        
        // 如果用户对该问题有回答，我们假设他已经解决了这个问题
        setState(() {
          _isSolved = userAnswers.any((answer) => 
            answer.get<int>('question_id') == questionId
          );
        });
      }
    } catch (e) {
      debugPrint('Error checking if solved: $e');
    }
  }

  Future<void> _loadQuestionDetails() async {
    try {
      setState(() {
        _isLoadingAnswers = true;
      });
      
      // 加载问题详情
      final questionDetails = widget.problem;
      final questionId = questionDetails.get<int>('q_id') ?? 0;

      // 加载问题的回答
      final answers = await _answerRepository.getAnswersByQuestionId(questionId);
      setState(() {
        _answers = answers;
        _isLoadingAnswers = false;
      });
    } catch (e) {
      debugPrint('Error loading question details: $e');
      setState(() {
        _isLoadingAnswers = false;
      });
    }
  }
  
  // 收藏或取消收藏问题
  Future<void> _toggleBookmark() async {
    if (_userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录后再收藏题目')),
      );
      return;
    }
    
    setState(() {
      _isBookmarking = true;
    });
    
    try {
      final questionId = widget.problem.get<int>('q_id') ?? 0;
      bool success;
      
      if (_isBookmarked) {
        // 取消收藏
        success = await _userinfoRepository.unbookmarkQuestion(_userId, questionId);
        if (success) {
          if (!mounted) return;
          setState(() {
            _isBookmarked = false;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已取消收藏')),
          );
        }
      } else {
        // 添加收藏
        success = await _userinfoRepository.bookmarkQuestion(_userId, questionId);
        if (success) {
          if (!mounted) return;
          setState(() {
            _isBookmarked = true;
          });
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已添加到收藏')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error toggling bookmark: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('操作失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isBookmarking = false;
        });
      }
    }
  }
  
  // 标记题目为已完成
  Future<void> _markAsSolved() async {
    debugPrint('尝试标记题目为已完成，当前用户ID: $_userId');
    if (_userId == 0) {
      debugPrint('用户ID为0，提示需要登录');
      // 先再次尝试加载用户信息
      await _loadCurrentUser();
      
      // 如果仍然为0，则提示登录
      if (_userId == 0) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先登录后再标记题目')),
        );
        return;
      }
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final questionId = widget.problem.get<int>('q_id') ?? 0;
      
      // 更新问题的提交次数
      await _questionRepository.incrementSubmissionCount(questionId);
      
      // 更新问题的成功次数
      await _questionRepository.incrementSuccessCount(questionId);
      
      // 更新用户已解题目数量
      await _userinfoRepository.updateSolvedProblems(_userId);
      
      // 添加一个简单的回答，表示用户已完成此题
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await _answerRepository.createAnswer(
        timestamp, 
        "我已经完成了这道题目！", 
        _userId, 
        0, 
        questionId
      );
      
      if (!mounted) return;
      setState(() {
        _isSolved = true;
      });
      
      // 重新加载答案
      _loadQuestionDetails();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('恭喜你完成了这道题目！')),
      );
    } catch (e) {
      debugPrint('Error marking as solved: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('提交失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  // 点赞回答
  Future<void> _likeAnswer(int answerId) async {
    if (_userId == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先登录后再点赞')),
      );
      return;
    }
    
    try {
      await _answerRepository.likeAnswer(answerId);
      
      // 重新加载回答
      _loadQuestionDetails();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('点赞成功')),
      );
    } catch (e) {
      debugPrint('Error liking answer: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('点赞失败: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.problem.get<String>('q_title') ?? '未知标题'),
        actions: [
          _isBookmarking
              ? Container(
                  padding: const EdgeInsets.all(10),
                  child: const SizedBox(
                    width: 20, 
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : IconButton(
                  icon: Icon(_isBookmarked ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: _toggleBookmark,
                  tooltip: _isBookmarked ? '取消收藏' : '收藏题目',
                ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('分享功能即将上线')),
              );
            },
            tooltip: '分享题目',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProblemHeader(),
                  const SizedBox(height: 16.0),
                  _buildProblemDescription(),
                  const SizedBox(height: 16.0),
                  _buildProblemContent(),
                  const SizedBox(height: 24.0),
                  _buildSolveButton(),
                  const SizedBox(height: 24.0),
                  _buildDiscussionSection(),
                ],
              ),
            ),
          ),
          _buildBottomInput(),
        ],
      ),
    );
  }
  
  Widget _buildSolveButton() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: ElevatedButton(
        onPressed: _isSolved || _isSubmitting ? null : _markAsSolved,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          backgroundColor: Colors.green,
          disabledBackgroundColor: _isSolved ? Colors.green.withValues(alpha: 0.5) : null,
        ),
        child: _isSubmitting 
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                _isSolved ? '已完成' : '标记为已完成',
                style: const TextStyle(fontSize: 16.0),
              ),
      ),
    );
  }

  Widget _buildProblemHeader() {
    final difficulty = widget.problem.get<String>('q_difficulty') ?? '未知难度';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: difficulty == "简单"
                    ? Colors.green[50]
                    : difficulty == "中等"
                        ? Colors.orange[50]
                        : Colors.red[50],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                difficulty,
                style: TextStyle(
                  color: difficulty == "简单"
                      ? Colors.green[700]
                      : difficulty == "中等"
                          ? Colors.orange[700]
                          : Colors.red[700],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "通过率：${_calculateSuccessRate()}%",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              "${widget.problem.get<int>('submissions') ?? 0}人提交",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: (widget.problem.get<List>('q_tags') ?? []).map<Widget>((tag) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: Colors.blue[700],
                  fontSize: 12,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
  
  String _calculateSuccessRate() {
    final submissionCount = widget.problem.get<int>('submissions') ?? 0;
    final successCount = widget.problem.get<int>('success_count') ?? 0;
    
    if (submissionCount <= 0) {
      return '0.0';
    }
    
    return (successCount / submissionCount * 100).toStringAsFixed(1);
  }

  Widget _buildProblemContent() {
    final content = widget.problem.get<String>('q_information') ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "题目内容",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          content.isNotEmpty ? content : '暂无题目内容',
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildProblemDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "题目描述",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          widget.problem.get<String>('q_description') ?? '暂无描述',
          style: const TextStyle(
            fontSize: 16,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscussionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "讨论区",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _isLoadingAnswers
            ? const Center(child: CircularProgressIndicator())
            : _answers.isEmpty
                ? const Center(
                    child: Text(
                      "暂无讨论",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _answers.length,
                    itemBuilder: (context, index) {
                      final answer = _answers[index];
                      final content = answer.get<String>('ainfo') ?? '';
                      final userId = answer.get<int>('uid') ?? 0;
                      final likeCount = answer.get<int>('alike') ?? 0;
                      final answerId = answer.get<int>('a_id') ?? 0;
                      
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FutureBuilder<String>(
                                future: _userinfoRepository.getUserName(userId),
                                builder: (context, snapshot) {
                                  return Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: Colors.blue,
                                        child: Icon(Icons.person, color: Colors.white),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        snapshot.data ?? '匿名用户',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      GestureDetector(
                                        onTap: () => _likeAnswer(answerId),
                                        child: Row(
                                          children: [
                                            Icon(Icons.thumb_up, size: 16, color: Colors.grey[600]),
                                            const SizedBox(width: 4),
                                            Text('$likeCount', style: TextStyle(color: Colors.grey[600])),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                              const SizedBox(height: 8),
                              Text(
                                content,
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ],
    );
  }

  Widget _buildBottomInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: "写下你的想法...",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _userId == 0 ? null : _sendAnswer,
            child: const Text("发送"),
          ),
        ],
      ),
    );
  }
  
  // 发送回答
  Future<void> _sendAnswer() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入内容后再发送')),
      );
      return;
    }
    
    setState(() {
      _isSubmitting = true;
    });
    
    try {
      final questionId = widget.problem.get<int>('q_id') ?? 0;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      
      // 创建回答
      await _answerRepository.createAnswer(
        timestamp,
        message,
        _userId,
        0, // 初始点赞数为0
        questionId
      );
      
      if (!mounted) return;
      // 清空输入框
      _messageController.clear();
      
      // 重新加载回答
      _loadQuestionDetails();
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('发送成功')),
      );
    } catch (e) {
      debugPrint('Error sending answer: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('发送失败: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
