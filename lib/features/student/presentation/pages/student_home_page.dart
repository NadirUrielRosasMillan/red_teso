import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/student/presentation/pages/vacancy_detail_page.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String _selectedCategory = 'Todos';
  final _searchController = TextEditingController();

  // Lista Mock de Vacantes basadas en el requerimiento del documento
  final List<Map<String, dynamic>> _vacancies = [
    {
      'puesto': 'Desarrollador Flutter Junior',
      'empresa': 'Tech Solutions TESOEM',
      'tipo': 'Residencias',
      'gpa': 8.5,
      'descripcion': 'Buscamos un estudiante de Ingeniería en Sistemas Computacionales entusiasta por el desarrollo móvil para integrarse a nuestro equipo de desarrollo interno mediante residencias profesionales. Aprenderás buenas prácticas de Clean Architecture y testing.',
      'requisitos': ['Flutter & Dart', 'Git / GitHub', 'Conocimientos de bases de datos', 'Promedio mínimo 8.5']
    },
    {
      'puesto': 'Soporte Técnico e Infraestructura',
      'empresa': 'Innovación Digital S.A.',
      'tipo': 'Servicio Social',
      'gpa': 7.5,
      'descripcion': 'Únete para liberar tu servicio social apoyando en el mantenimiento preventivo y correctivo del equipo de cómputo, servidores y redes de la empresa.',
      'requisitos': ['Redes básicas', 'Mantenimiento de Hardware', 'Proactivo', 'Estudiante activo de Sistemas']
    },
    {
      'puesto': 'Full Stack Developer (Node.js & React)',
      'empresa': 'Global Software Systems',
      'tipo': 'Empleo Egresados',
      'gpa': 8.0,
      'descripcion': 'Oportunidad de contratación inmediata para recién egresados de Sistemas Computacionales del TESOEM. Trabajarás en proyectos internacionales con metodologías ágiles.',
      'requisitos': ['JavaScript / TypeScript', 'Inglés intermedio (Leído/Hablado)', 'React o Angular', 'Node.js']
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Filtrado visual instantáneo
    final filteredVacancies = _vacancies.where((v) {
      final matchesCategory = _selectedCategory == 'Todos' || v['tipo'] == _selectedCategory;
      final matchesSearch = v['puesto'].toString().toLowerCase().contains(_searchController.text.toLowerCase()) ||
          v['empresa'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('RedTESO Oportunidades', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Buscador superior (Requisito 9.1.7)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Buscar vacantes, puestos o empresas...',
                prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Categorías rápidas con Filtros (Requisito 9.1.8)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildCategoryChip('Todos'),
                  _buildCategoryChip('Servicio Social'),
                  _buildCategoryChip('Residencias'),
                  _buildCategoryChip('Empleo Egresados'),
                ],
              ),
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              'Vacantes Disponibles para Sistemas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
          ),

          // Lista de Vacantes (Requisito 9.1.6)
          Expanded(
            child: filteredVacancies.isEmpty
                ? const Center(
                    child: Text('No se encontraron vacantes con esos criterios.'),
                  )
                : ListView.builder(
                    itemCount: filteredVacancies.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) {
                      final vacancy = filteredVacancies[index];
                      return _buildVacancyCard(vacancy);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(category),
        selected: isSelected,
        selectedColor: AppTheme.primaryGreen,
        checkmarkColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.primaryGreen,
          fontWeight: FontWeight.bold,
        ),
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppTheme.primaryGreen),
          borderRadius: BorderRadius.circular(20),
        ),
        onSelected: (bool selected) {
          setState(() {
            _selectedCategory = category;
          });
        },
      ),
    );
  }

  Widget _buildVacancyCard(Map<String, dynamic> vacancy) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.business, color: AppTheme.primaryGreen, size: 28),
        ),
        title: Text(
          vacancy['puesto'] as String,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(vacancy['empresa'] as String, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    vacancy['tipo'] as String,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Promedio: ${vacancy['gpa']}',
                  style: TextStyle(fontSize: 12, color: Colors.orange[800], fontWeight: FontWeight.bold),
                ),
              ],
            )
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          // Navegación interactiva al Paso 4 (Detalle de Vacante)
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VacancyDetailPage(vacancy: vacancy),
            ),
          );
        },
      ),
    );
  }
}
