import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';
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
    const CourseCatalogPage(), // Nueva sección principal de Cursos & Cortos TikTok
    const CompanyHomePage(), // Buscador de Talento
    const ManageVacanciesPage(),
    const CompanyApplicantsPage(),
    const CompanyProfileEditPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Cursos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_search_outlined),
            activeIcon: Icon(Icons.person_search),
            label: 'Talento',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Vacantes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people_outline),
            activeIcon: Icon(Icons.people),
            label: 'Postulados',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.business_outlined),
            activeIcon: Icon(Icons.business),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
