import 'package:flutter/material.dart';
import 'package:red_teso/core/widgets/liquid_glass_floating_navbar.dart';
import 'package:red_teso/features/courses/presentation/pages/course_catalog_page.dart';
import 'package:red_teso/features/company/presentation/pages/company_home_page.dart';
import 'package:red_teso/features/company/presentation/pages/company_applicants_page.dart';
import 'package:red_teso/features/company/presentation/pages/manage_vacancies_page.dart';
import 'package:red_teso/features/company/presentation/pages/company_profile_edit_page.dart';

class CompanyDashboardPage extends StatefulWidget {
  const CompanyDashboardPage({super.key});

  @override
  State<CompanyDashboardPage> createState() => _CompanyDashboardPageState();
}

class _CompanyDashboardPageState extends State<CompanyDashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const CourseCatalogPage(),
    const CompanyHomePage(),
    const ManageVacanciesPage(),
    const CompanyApplicantsPage(),
    const CompanyProfileEditPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Permite que el contenido haga scroll traslúcido bajo el dock Liquid Glass
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
            icon: Icons.school_outlined,
            activeIcon: Icons.school_rounded,
            label: 'Cursos',
          ),
          LiquidGlassNavItem(
            icon: Icons.person_search_outlined,
            activeIcon: Icons.person_search_rounded,
            label: 'Talento',
          ),
          LiquidGlassNavItem(
            icon: Icons.list_alt_outlined,
            activeIcon: Icons.list_alt_rounded,
            label: 'Vacantes',
          ),
          LiquidGlassNavItem(
            icon: Icons.people_outline,
            activeIcon: Icons.people_rounded,
            label: 'Postulados',
          ),
          LiquidGlassNavItem(
            icon: Icons.business_outlined,
            activeIcon: Icons.business_rounded,
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
