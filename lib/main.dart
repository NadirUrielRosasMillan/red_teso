import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/pages/login_page.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/student/presentation/pages/student_dashboard_page.dart';
import 'package:red_teso/features/company/presentation/pages/company_dashboard_page.dart';
import 'package:red_teso/features/admin/presentation/pages/admin_dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const RedTESOApp(),
    ),
  );
}

class RedTESOApp extends StatelessWidget {
  const RedTESOApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RedTESO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoggedIn) {
      if (authProvider.userType == UserType.alumno) {
        return const StudentDashboardPage();
      } else if (authProvider.userType == UserType.empresa) {
        return const CompanyDashboardPage();
      } else if (authProvider.userType == UserType.admin) {
        return const AdminDashboardPage();
      }
    }
    
    return const LoginPage();
  }
}
