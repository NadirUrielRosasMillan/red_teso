import 'package:flutter/material.dart';
import 'package:red_teso/core/widgets/liquid_glass_floating_navbar.dart';
import 'package:red_teso/features/student/presentation/pages/student_home_page.dart';
import 'package:red_teso/features/student/presentation/pages/student_profile_page.dart';
import 'package:red_teso/features/student/presentation/pages/student_applications_page.dart';

class StudentDashboardPage extends StatefulWidget {
  const StudentDashboardPage({super.key});

  @override
  State<StudentDashboardPage> createState() => _StudentDashboardPageState();
}

class _StudentDashboardPageState extends State<StudentDashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const StudentHomePage(),
    const StudentApplicationsPage(),
    const StudentProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Scroll traslúcido tras la barra estilo WhatsApp iOS Liquid Glass
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: LiquidGlassFloatingNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          LiquidGlassNavItem(
            icon: Icons.work_outline_rounded,
            activeIcon: Icons.work_rounded,
            label: 'Oportunidades',
          ),
          LiquidGlassNavItem(
            icon: Icons.assignment_outlined,
            activeIcon: Icons.assignment_rounded,
            label: 'Postulaciones',
          ),
          LiquidGlassNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Mi Perfil',
          ),
        ],
      ),
    );
  }
}
