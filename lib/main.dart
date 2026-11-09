import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:red_teso/core/services/fcm_notification_service.dart';
import 'package:red_teso/core/services/gemini_ai_service.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/core/theme/theme_provider.dart';
import 'package:red_teso/features/auth/presentation/pages/login_page.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/admin/presentation/pages/admin_dashboard_page.dart';
import 'package:red_teso/features/ecosystem/presentation/pages/ecosystem_selector_page.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await GeminiAiService.init();
  await FcmNotificationService.init();

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
      child: const RedTESOApp(),
    ),
  );
}

class RedTESOApp extends StatefulWidget {
  const RedTESOApp({super.key});

  @override
  State<RedTESOApp> createState() => _RedTESOAppState();
}

class _RedTESOAppState extends State<RedTESOApp> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'ÁGORA',
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
        // Espera a que Firebase restaure una sesión existente.
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

        // AuthWrapper decide el destino según el rol del usuario.
        if (authProvider.isLoggedIn) {
          return const AuthWrapper();
        }

        // La única entrada para usuarios sin sesión es el login de ÁGORA.
        return const LoginPage();
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
          case UserType.profesor:
          case UserType.empresa:
            // El selector filtra las experiencias según el rol.
            // Las empresas únicamente verán ÁGORA Talento.
            return const EcosystemSelectorPage();
          case UserType.admin:
            return const AdminDashboardPage();
          case UserType.none:
            return const LoginPage();
        }
      },
    );
  }
}
