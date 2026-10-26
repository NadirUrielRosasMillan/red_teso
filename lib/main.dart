import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:red_teso/core/services/fcm_notification_service.dart';
import 'package:red_teso/core/services/gemini_ai_service.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/core/theme/theme_provider.dart';
import 'package:red_teso/features/auth/presentation/pages/login_page.dart';
import 'package:red_teso/features/auth/presentation/pages/onboarding_page.dart';
import 'package:red_teso/features/auth/presentation/pages/splash_page.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/student/presentation/pages/student_dashboard_page.dart';
import 'package:red_teso/features/company/presentation/pages/company_dashboard_page.dart';
import 'package:red_teso/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:red_teso/features/professor/presentation/pages/professor_dashboard_page.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GeminiAiService.init();
  await FcmNotificationService.init();

  final prefs = await SharedPreferences.getInstance();
  final bool showOnboarding = prefs.getBool('showOnboarding') ?? true;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => AuthProvider(),
        ),
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
      ],
      child: RedTESOApp(showOnboarding: showOnboarding),
    ),
  );
}

class RedTESOApp extends StatefulWidget {
  final bool showOnboarding;

  const RedTESOApp({
    super.key,
    required this.showOnboarding,
  });

  @override
  State<RedTESOApp> createState() => _RedTESOAppState();
}

class _RedTESOAppState extends State<RedTESOApp> {
  String _currentStep = 'splash';

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'RedTESO',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode:
              themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: _buildCurrentScreen(),
        );
      },
    );
  }

  Widget _buildCurrentScreen() {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        // No mostrar splash/onboarding mientras Firebase está resolviendo
        // una sesión existente.
        if (authProvider.isInitializing) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        // AuthWrapper decide qué dashboard corresponde y escucha al provider.
        if (authProvider.isLoggedIn) {
          return const AuthWrapper();
        }

        if (_currentStep == 'splash') {
          return SplashPage(
            onInitializationComplete: () {
              if (!mounted) return;
              setState(() {
                _currentStep =
                    widget.showOnboarding ? 'onboarding' : 'auth';
              });
            },
          );
        }

        if (_currentStep == 'onboarding') {
          return OnboardingPage(
            onFinish: () async {
              final prefs = await SharedPreferences.getInstance();
              await prefs.setBool('showOnboarding', false);

              if (!mounted) return;
              setState(() => _currentStep = 'auth');
            },
          );
        }

        return const AuthWrapper();
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isInitializing) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryGreen,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        if (!authProvider.isLoggedIn) {
          return const LoginPage();
        }

        switch (authProvider.userType) {
          case UserType.alumno:
            return const StudentDashboardPage();
          case UserType.empresa:
            return const CompanyDashboardPage();
          case UserType.admin:
            return const AdminDashboardPage();
          case UserType.profesor:
            return const ProfessorDashboardPage();
          case UserType.none:
            return const LoginPage();
        }
      },
    );
  }
}
