import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme.dart';

import 'viewmodels/landing_viewmodel.dart';
import 'viewmodels/onboarding_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';
import 'viewmodels/user_dashboard_viewmodel.dart';
import 'viewmodels/admin_dashboard_viewmodel.dart';
import 'viewmodels/add_task_viewmodel.dart';

import 'views/landing_page.dart';
import 'views/onboarding_page.dart';
import 'views/login_page.dart';
import 'views/user_dashboard_page.dart';
import 'views/admin_dashboard_page.dart';
import 'views/add_task_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LandingViewModel()),
        ChangeNotifierProvider(create: (_) => OnboardingViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
        ChangeNotifierProvider(create: (_) => UserDashboardViewModel()),
        ChangeNotifierProvider(create: (_) => AdminDashboardViewModel()),
        ChangeNotifierProvider(create: (_) => AddTaskViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Task Management',
      theme: AppTheme.light(),
      initialRoute: '/',
      routes: {
        '/': (context) => const LandingPage(),
        '/onboarding': (context) => const OnboardingPage(),
        '/login': (context) => const LoginPage(),
        '/user_dashboard': (context) => const UserDashboardPage(),
        '/admin_dashboard': (context) => const AdminDashboardPage(),
        '/add_task': (context) => const AddTaskPage(),
      },
    );
  }
}
