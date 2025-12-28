import 'package:flutter/material.dart';

class AppColors {
  static const Color coral = Color(0xFFF98C53);
  static const Color mint = Color(0xFFD2E0AA);
  static const Color skyBlue = Color(0xFFABD7FB);
  static const Color blushPink = Color(0xFFF9F2EF);
  static const Color peach = Color(0xFFFCCEB4);
  
  static const Color primary = coral;
  static const Color secondary = mint;
  static const Color background = Color(0xFFFFF8F3); // 米白色背景
  static const Color headerBackground = Color(0xFFFFE4D4); // 顶部导航栏背景色
  
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [coral, peach],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient secondaryGradient = LinearGradient(
    colors: [mint, skyBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

ThemeData appTheme = ThemeData(
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: ColorScheme.light(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    surface: Colors.white,
  ),
  
  // AppBar主题
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.primary),
    titleTextStyle: TextStyle(
      color: Colors.black87,
      fontSize: 20,
      fontWeight: FontWeight.w600,
    ),
  ),
  
  // 卡片主题
  cardTheme: CardThemeData( //cardTheme: CardTheme(
    color: Colors.white,
    elevation: 2,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    ),
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  ),
  
  // 输入框主题
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(20),
      borderSide: const BorderSide(color: AppColors.primary, width: 1),
    ),
  ),
  
  // 按钮主题
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),
  
  // 文本按钮主题
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  
  // 图标主题
  iconTheme: const IconThemeData(
    color: AppColors.primary,
    size: 24,
  ),
); 