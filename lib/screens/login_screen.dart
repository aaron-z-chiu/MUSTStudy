import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk_flutter.dart';
import '../repositories/userinfo_respositories.dart';
import '../widgets/danmu_widget.dart';
import 'package:google_fonts/google_fonts.dart';
import '../routes/app_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  final _userinfoRepository = UserinfoRepository();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // 预加载字体
    GoogleFonts.pressStart2p();
  }

  // ignore: unused_element
  TextStyle get _pixelTextStyle => GoogleFonts.pressStart2p(
        fontSize: 12,
        color: Colors.white,
        letterSpacing: 1.0,
        height: 1.2,
      );

  TextStyle get _pixelTextStyleSmall => GoogleFonts.pressStart2p(
        fontSize: 10,
        color: Colors.white,
        letterSpacing: 1.0,
        height: 1.2,
      );

  TextStyle get _pixelTextStyleError => GoogleFonts.pressStart2p(
        fontSize: 12,
        color: Colors.red,
        letterSpacing: 1.0,
        height: 1.2,
      );

  TextStyle get _pixelTextStyleInput => GoogleFonts.pressStart2p(
        fontSize: 12,
        color: Colors.black,
        letterSpacing: 1.0,
        height: 1.2,
      );

  TextStyle get _pixelTextStyleHint => GoogleFonts.pressStart2p(
        fontSize: 12,
        color: Colors.grey,
        letterSpacing: 1.0,
        height: 1.2,
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/login_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // 弹幕
          DanmuWidget(
            safeAreas: [
              // 整体登录区域（包含标题和输入框）
              Rect.fromLTWH(
                MediaQuery.of(context).size.width / 2 - 150,  // 水平居中
                MediaQuery.of(context).size.height / 2 - 200, // 垂直位置
                300,  // 宽度
                400,  // 高度
              ),
            ],
            topPadding: 50,
            bottomPadding: 50,
          ),
          // 登录表单
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          // Logo或标题
                          Text(
                            "Must Study",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.pressStart2p(
                              fontSize: 35,
                              color: Colors.white,
                              letterSpacing: 1,
                              height: 1.2,
                              shadows: const [
                                Shadow(
                                  color: Color(0x4D000000),
                                  offset: Offset(4, 4),
                                  blurRadius: 0,
                                ),
                                Shadow(
                                  color: Color(0x4D000000),
                                  offset: Offset(2, 2),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 40),
                          // 用户名输入框
                          TextFormField(
                            controller: _usernameController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter username';
                              }
                              return null;
                            },
                            style: _pixelTextStyleInput,
                            decoration: InputDecoration(
                              errorStyle: _pixelTextStyleError,
                              hintText: 'Username',
                              hintStyle: _pixelTextStyleHint,
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.person, size: 24),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 密码输入框
                          TextFormField(
                            controller: _passwordController,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter password';
                              }
                              return null;
                            },
                            style: _pixelTextStyleInput,
                            obscureText: true,
                            decoration: InputDecoration(
                              errorStyle: _pixelTextStyleError,
                              hintText: 'Password',
                              hintStyle: _pixelTextStyleHint,
                              filled: true,
                              fillColor: Colors.white,
                              prefixIcon: const Icon(Icons.lock, size: 24),
                              contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // 登录/注册按钮
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  offset: const Offset(4, 4),
                                  blurRadius: 0,
                                ),
                              ],
                            ),
                            child: GestureDetector(
                              onTap: _isLoading ? null : _handleSubmit,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: _isLoading
                                    ? SizedBox(
                                        width: 10,
                                        height: 10,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF7CB342)),
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? 'Log in' : 'register',
                                        style: GoogleFonts.pressStart2p(
                                          fontSize: 12,
                                          color: const Color(0xFF7CB342),
                                          letterSpacing: 1.0,
                                          height: 1.2,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          // 切换登录/注册模式
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _isLogin = !_isLogin;
                              });
                            },
                            child: Text(
                              _isLogin ? 'No account? Register now' : 'Already have an account? Log in',
                              style: _pixelTextStyleSmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 50), // 添加间距
                  ],
                ),
              ),
            ),
          ),
          // 自定义底部图标
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(FontAwesomeIcons.graduationCap, size: 24, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'MUSTSTUDY v1.0',
                    style: GoogleFonts.getFont(
                      'Press Start 2P',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final query = QueryBuilder<ParseObject>(ParseObject('Userinfo'))
        ..whereEqualTo('u_name', _usernameController.text)
        ..whereEqualTo('u_password', _passwordController.text);
      
      final response = await query.query();
      
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        final user = response.results!.first;
        final username = user.get<String>('u_name');
        
        // Save current username to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('currentUsername', username!);
        
        // Login successful
        if (!mounted) return;
        RouteGuard.setLoggedIn(true);
        Navigator.of(context).pushNamedAndRemoveUntil(
          RouteNames.home,
          (route) => false,
        );
      } else {
        // Login failed
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Username or password is incorrect',
              style: _pixelTextStyleError,
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Login failed: $e',
            style: _pixelTextStyleError,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Check if username already exists
      final query = QueryBuilder<ParseObject>(ParseObject('Userinfo'))
        ..whereEqualTo('u_name', _usernameController.text);
      final response = await query.query();
      if (!mounted) return;
      
      if (response.success && response.results != null && response.results!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Username already exists',
              style: _pixelTextStyleError,
            ),
          ),
        );
        return;
      }

      // Get the count of existing users for new user ID
      final countQuery = QueryBuilder<ParseObject>(ParseObject('Userinfo'));
      final countResponse = await countQuery.count();
      if (!mounted) return;
      final newUserId = countResponse.count + 1;

      // Create new user
      await _userinfoRepository.createUserinfoItem(
        newUserId,
        _usernameController.text,
        _passwordController.text,
      );
      if (!mounted) return;

      // Save current username to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('currentUsername', _usernameController.text);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration successful! You can now log in.',
            style: _pixelTextStyleError,
          ),
        ),
      );
      
      setState(() {
        _isLogin = true;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Registration failed: $e',
            style: _pixelTextStyleError,
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_isLogin) {
        _handleLogin();
      } else {
        _handleRegister();
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
