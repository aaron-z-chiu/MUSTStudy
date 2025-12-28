import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/app_footer.dart';

class SettingsUserInfoScreen extends StatefulWidget {
  const SettingsUserInfoScreen({super.key});
  @override
  State<SettingsUserInfoScreen> createState() => _SettingsUserInfoScreenState();
}

class _SettingsUserInfoScreenState extends State<SettingsUserInfoScreen> {
  // 学院及对应专业列表
  final Map<String, List<String>> collegeMajors = {
    '创新工程学院': ['计算机科学', '电子信息', '软件工程'],
    '商学院': ['金融学', '市场营销', '会计学'],
    '法学院': ['法学', '知识产权法', '国际法'],
    '医学院': ['临床医学', '护理学', '药学'],
    '博雅学院': ['哲学', '历史学', '文学'],
  };
  // 字段名到持久化Key的映射
  final Map<String, String> _prefsKeys = {
    '邮箱': 'email',
    '电话': 'phone',
    '学号': 'studentId',
  };

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }
  // 从 SharedPreferences 加载用户信息
  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      email = prefs.getString('email') ?? '未绑定';
      phone = prefs.getString('phone') ?? '未绑定';
      studentId = prefs.getString('studentId') ?? '未绑定';
      college = prefs.getString('college') ?? '未绑定';
      major = prefs.getString('major') ?? '未绑定';
    });
  }

  String email = '未绑定';
  String phone = '未绑定';
  String studentId = '未绑定';
  String college = '未绑定';
  String major = '未绑定';

  Future<void> _editField(String fieldName, String currentValue, 
  ValueChanged<String> onSaved) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('编辑$fieldName'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(labelText: fieldName),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: 
            const Text('取消')),
            TextButton(onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('保存')),
          ],
        );
      },
    );
    if (result != null) {
      final newValue = result.trim().isEmpty ? '未绑定' : result;
      setState(() {
        onSaved(newValue);
      });
      // 保存到 SharedPreferences
      final prefsKey = _prefsKeys[fieldName]!;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(prefsKey, newValue);
    }
  }

  // 选择学院
  Future<void> _selectCollege() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('选择学院'),
        children: collegeMajors.keys.map((c) => SimpleDialogOption(
          child: Text(c),
          onPressed: () => Navigator.pop(context, c),
        )).toList(),
      ),
    );
    if (selected != null) {
      setState(() {
        college = selected;
        major = '未绑定';
      });
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('college', college);
      await prefs.setString('major', major);
    }
  }
  // 选择专业（需先选择学院）
  Future<void> _selectMajor() async {
    if (college == '未绑定') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择学院')),
      );
      return;
    }
    final options = collegeMajors[college]!;
    final selected = await showDialog<String>(
      context: context,
      builder: (_) => SimpleDialog(
        title: const Text('选择专业'),
        children: options.map((m) => SimpleDialogOption(
          child: Text(m),
          onPressed: () => Navigator.pop(context, m),
        )).toList(),
      ),
    );
    if (selected != null) {
      setState(() => major = selected);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('major', major);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('账户与安全'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Container(
                  padding: const EdgeInsets.all(16.0),
                  margin: const EdgeInsets.only(bottom: 16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                        'https://ui-avatars.com/api/?name=User&background=random',
                      ),
                    ),
                    title: const Text('用户名'),
                    subtitle: const Text('用户名称'),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.2),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      InkWell(
                        onTap: () => _editField('邮箱', email, (val) => email = val),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('邮箱', style: TextStyle(fontSize: 16)),
                            Text(email, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Divider(color: Colors.grey[300], thickness: 0.5),
                      InkWell(
                        onTap: () => _editField('电话', phone, (val) => phone = val),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('电话', style: TextStyle(fontSize: 16)),
                            Text(phone, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Divider(color: Colors.grey[300], thickness: 0.5),
                      InkWell(
                        onTap: () => _editField('学号', studentId, (val) => studentId = val),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('学号', style: TextStyle(fontSize: 16)),
                            Text(studentId, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Divider(color: Colors.grey[300], thickness: 0.5),
                      InkWell(
                        onTap: _selectCollege,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('学院', style: TextStyle(fontSize: 16)),
                            Text(college, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Divider(color: Colors.grey[300], thickness: 0.5),
                      InkWell(
                        onTap: _selectMajor,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('专业', style: TextStyle(fontSize: 16)),
                            Text(major, style: const TextStyle(fontSize: 16, color: Colors.grey)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    // Handle logout
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: const Text('退出登录', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          const AppFooter(),
        ],
      ),
    );
  }
} 