import 'package:flutter/material.dart';

import 'pages/learning_hub_page.dart';

export 'pages/certificate_verify_page.dart';
export 'pages/classroom_page.dart';
export 'pages/course_detail_page.dart';
export 'pages/course_editor_page.dart';
export 'pages/evaluation_editor_page.dart';
export 'pages/evaluation_page.dart';
export 'pages/learning_hub_page.dart';
export 'pages/live_sessions_page.dart';
export 'pages/student_catalog_page.dart';
export 'pages/teacher_courses_page.dart';

/// Entrada del modulo: abre AGORA Aprende segun el rol del usuario.
class LocalCoursesHomePage extends StatelessWidget {
  const LocalCoursesHomePage({super.key});

  @override
  Widget build(BuildContext context) => const LearningHubPage();
}
