import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
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
import 'views/project_details_page.dart';
import 'views/task_details_page.dart';
import 'views/debug_notification_page.dart';

import 'services/task_notification_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Initialize notification manager (this will also initialize Firebase)
  await TaskNotificationManager().initialize();

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
        '/add_task': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>?;
          final projectId = args?['projectId'] as int?;
          return AddTaskPage(projectId: projectId);
        },
        '/project_details': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return ProjectDetailsPage(project: args);
        },
        '/task_details': (context) {
          final args =
              ModalRoute.of(context)!.settings.arguments
                  as Map<String, dynamic>;
          return TaskDetailsPage(task: args);
        },
        '/debug_notifications': (context) => const DebugNotificationPage(),
      },
    );
  }
}
