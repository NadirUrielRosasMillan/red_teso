import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';

import '../../data/local_course_store.dart';
import '../theme/courses_theme.dart';
import 'student_catalog_page.dart';
import 'teacher_courses_page.dart';

/// Punto de entrada de AGORA Aprende. Lee el rol del usuario con sesion
/// iniciada (AuthProvider) y conecta el modulo con Firebase:
/// - profesor y admin: panel del profesor (admin ve y edita todos los cursos).
/// - alumno: catalogo con inscripcion, aula, evaluaciones y certificados.
/// - empresa: catalogo en modo consulta (no se inscribe a cursos).
class LearningHubPage extends StatefulWidget {
  const LearningHubPage({super.key});

  @override
  State<LearningHubPage> createState() => _LearningHubPageState();
}

class _LearningHubPageState extends State<LearningHubPage> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.user;
    final role = auth.userType;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final store = LocalCourseStore.instance;
      if (user == null || role == UserType.none) {
        store.detach();
      } else {
        store.attach(
          uid: user.uid,
          role: role.name,
          name: user.displayName ?? '',
        );
      }
    });
  }

  @override
  void dispose() {
    Future.microtask(LocalCourseStore.instance.detach);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    switch (auth.userType) {
      case UserType.profesor:
      case UserType.admin:
        return const TeacherCoursesPage();
      case UserType.alumno:
      case UserType.empresa:
        return const StudentCoursesPage();
      case UserType.none:
        return Theme(
          data: coursesTheme(),
          child: Scaffold(
            appBar: AppBar(title: const Text('AGORA Aprende')),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                  'Inicia sesion para ver tus cursos.',
                  style: TextStyle(color: CoursesColors.muted),
                ),
              ),
            ),
          ),
        );
    }
  }
}
