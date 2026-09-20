import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/student/presentation/pages/vacancy_detail_page.dart';
import 'package:red_teso/features/notifications/presentation/pages/notifications_page.dart';
import 'package:red_teso/core/widgets/notification_bell.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  String _selectedCategory = 'Todos';
  final _searchController = TextEditingController();
  
  // Estados para Filtros Avanzados
  double _minSalary = 0;
  String _selectedLocation = 'Todas';

  final List<Map<String, dynamic>> _vacancies = [
    {
      'id': 'vac-1',
      'puesto': 'Desarrollador Flutter Junior',
      'empresa': 'Tech Solutions TESOEM',
      'tipo': 'Residencias',
      'gpa': 8.5,
      'ubicacion': 'Remoto',
      'apoyo': 4500,
      'descripcion': 'Buscamos un estudiante de Ingeniería en Sistemas Computacionales entusiasta por el desarrollo móvil.',
      'requisitos': ['Flutter & Dart', 'Git', 'Promedio mínimo 8.5']
    },
    {
      'id': 'vac-2',
      'puesto': 'Soporte Técnico',
      'empresa': 'Innovación Digital',
      'tipo': 'Servicio Social',
      'gpa': 7.5,
      'ubicacion': 'Chalco',
      'apoyo': 0,
      'descripcion': 'Apoyo en mantenimiento preventivo y correctivo de hardware.',
      'requisitos': ['Redes básicas', 'Hardware']
    },
    {
      'id': 'vac-3',
      'puesto': 'Full Stack Developer',
      'empresa': 'Global Software',
      'tipo': 'Empleo Egresados',
      'gpa': 8.0,
      'ubicacion': 'CDMX',
      'apoyo': 12000,
      'descripcion': 'Contratación inmediata para egresados con conocimientos en Node.js.',
      'requisitos': ['JavaScript', 'React', 'Node.js']
    },
  ];

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Filtros Avanzados', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Text('Ubicación: $_selectedLocation', style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Todas', 'Remoto', 'Chalco', 'CDMX', 'Ixtapaluca'].map((loc) {
                  return ChoiceChip(
                    label: Text(loc),
                    selected: _selectedLocation == loc,
                    onSelected: (val) {
                      setSheetState(() => _selectedLocation = loc);
                      setState(() => _selectedLocation = loc);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              Text('Apoyo Económico Mínimo: \$${_minSalary.toInt()}', style: const TextStyle(fontWeight: FontWeight.w500)),
              Slider(
                value: _minSalary,
                min: 0,
                max: 15000,
                divisions: 15,
                label: '\$${_minSalary.toInt()}',
                activeColor: AppTheme.primaryGreen,
                onChanged: (val) {
                  setSheetState(() => _minSalary = val);
                  setState(() => _minSalary = val);
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('APLICAR FILTROS'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _clearSearchAndFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = 'Todos';
      _minSalary = 0;
      _selectedLocation = 'Todas';
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredVacancies = _vacancies.where((v) {
      final matchesCategory = _selectedCategory == 'Todos' || v['tipo'] == _selectedCategory;
      final matchesSearch = v['puesto'].toString().toLowerCase().contains(_searchController.text.toLowerCase());
      final matchesSalary = (v['apoyo'] as int) >= _minSalary;
      final matchesLocation = _selectedLocation == 'Todas' || v['ubicacion'] == _selectedLocation;
      return matchesCategory && matchesSearch && matchesSalary && matchesLocation;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('RedTESO Oportunidades', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
        actions: [
          const NotificationBell(color: AppTheme.primaryGreen),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            onPressed: () => context.read<AuthProvider>().logout(),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Buscar puesto o empresa...',
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGreen),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  decoration: BoxDecoration(color: AppTheme.primaryGreen, borderRadius: BorderRadius.circular(12)),
                  child: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.white),
                    onPressed: _showFilterSheet,
                  ),
                ),
              ],
            ),
          ),

          // Categorías rápidas
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

          Expanded(
            child: filteredVacancies.isEmpty
                ? _buildPremiumEmptyState()
                : ListView.builder(
                    itemCount: filteredVacancies.length,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemBuilder: (context, index) => _buildVacancyCard(filteredVacancies[index]),
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
        labelStyle: TextStyle(color: isSelected ? Colors.white : AppTheme.primaryGreen, fontWeight: FontWeight.bold),
        onSelected: (bool selected) => setState(() => _selectedCategory = category),
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
        leading: Hero(
          tag: 'logo-${vacancy['id']}',
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppTheme.primaryGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.business, color: AppTheme.primaryGreen, size: 28),
          ),
        ),
        title: Text(vacancy['puesto'], style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vacancy['empresa']),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                Text(' ${vacancy['ubicacion']}  • ', style: const TextStyle(fontSize: 12)),
                Text('\$${vacancy['apoyo']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
              ],
            )
          ],
        ),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VacancyDetailPage(vacancy: vacancy))),
      ),
    );
  }

  Widget _buildPremiumEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Sin resultados', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          TextButton(onPressed: _clearSearchAndFilters, child: const Text('Limpiar todos los filtros')),
        ],
      ),
    );
  }
}
