import 'package:flutter/material.dart';
import 'app_router.dart';
import '../services/navigation_service.dart';

class App extends StatelessWidget {
  const App({super.key});



  @override
  Widget build(BuildContext context) {
    final navigationService = NavigationService();
    
    return MaterialApp(
      title: 'Must Study',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      navigatorKey: navigationService.navigatorKey,
      initialRoute: AppRouter.initialRoute,
      onGenerateRoute: AppRouter.generateRoute,
      debugShowCheckedModeBanner: false,
    );
  }
}