import 'package:flutter/material.dart';
import '../routes/app_router.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  
  factory NavigationService() {
    return _instance;
  }
  
  NavigationService._internal();

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  
  // 获取当前上下文
  BuildContext? get context => navigatorKey.currentContext;
  
  // 导航到指定路由
  Future<dynamic> navigateTo(String routeName, {dynamic arguments}) async {
    if (!RouteGuard.canActivate(routeName)) {
      return navigateTo(RouteNames.login);
    }
    
    if (navigatorKey.currentState == null) {
      debugPrint('NavigatorState is null');
      return;
    }
    
    return navigatorKey.currentState!.pushNamed(routeName, arguments: arguments);
  }
  
  // 导航到资源详情页
  Future<dynamic> navigateToResourceDetails(dynamic resource) {
    return navigateTo(
      RouteNames.resourceDetails,
      arguments: RouteArguments.resourceDetails(resource),
    );
  }
  
  // 导航到问题详情页
  Future<dynamic> navigateToProblemDetails(dynamic problem) {
    return navigateTo(
      RouteNames.problemDetails,
      arguments: RouteArguments.problemDetails(problem),
    );
  }
  
  // 返回上一页
  void goBack() {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.pop();
    }
  }
  
  // 返回到指定路由
  void popUntil(String routeName) {
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState!.popUntil((route) => route.settings.name == routeName);
    }
  }
  
  // 替换当前路由
  Future<dynamic> replaceWith(String routeName, {dynamic arguments}) {
    if (navigatorKey.currentState == null) {
      debugPrint('NavigatorState is null');
      return Future.value();
    }
    return navigatorKey.currentState!.pushReplacementNamed(routeName, arguments: arguments);
  }
  
  // 清除所有路由并导航到新路由
  Future<dynamic> clearAndNavigateTo(String routeName, {dynamic arguments}) {
    if (navigatorKey.currentState == null) {
      debugPrint('NavigatorState is null');
      return Future.value();
    }
    return navigatorKey.currentState!.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }
} 