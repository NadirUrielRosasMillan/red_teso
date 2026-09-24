import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/pages/login_page.dart';
import 'package:red_teso/features/auth/presentation/pages/onboarding_page.dart';
import 'package:red_teso/features/auth/presentation/pages/splash_page.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/student/presentation/pages/student_dashboard_page.dart';
import 'package:red_teso/features/company/presentation/pages/company_dashboard_page.dart';
import 'package:red_teso/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  final bool showOnboarding = prefs.getBool('showOnboarding') ?? true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: RedTESOApp(showOnboarding: showOnboarding),
    ),
  );
}

class RedTESOApp extends StatefulWidget {
  final bool showOnboarding;
  const RedTESOApp({super.key, required this.showOnboarding});
  @override
  State<RedTESOApp> createState() => _RedTESOAppState();
}

class _RedTESOAppState extends State<RedTESOApp> {
  String _currentStep = 'splash';
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RedTESO',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: _buildCurrentScreen(),
    );
  }

  Widget _buildCurrentScreen() {
    if (_currentStep == 'splash') {
      return SplashPage(
        onInitializationComplete: () => setState(() => _currentStep = widget.showOnboarding ? 'onboarding' : 'auth'),
      );
    }
    if (_currentStep == 'onboarding') {
      return OnboardingPage(onFinish: () => setState(() => _currentStep = 'auth'));
    }
    return const AuthWrapper();
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    if (authProvider.isLoggedIn) {
      switch (authProvider.userType) {
        case UserType.alumno: return const StudentDashboardPage();
        case UserType.empresa: return const CompanyDashboardPage();
        case UserType.admin: return const AdminDashboardPage();
        default: return const LoginPage();
      }
    }
    return const LoginPage();
  }
}
