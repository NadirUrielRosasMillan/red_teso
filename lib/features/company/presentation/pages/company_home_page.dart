import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/company/presentation/pages/student_detail_view_page.dart';
import 'package:red_teso/core/widgets/notification_bell.dart';

class CompanyHomePage extends StatefulWidget {
  const CompanyHomePage({super.key});

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  // Estados para filtros
  double _minGpa = 8.0;
  String _filterGender = 'Todos';
  bool _requireEnglish = false;
  String _filterModality = 'Todos';

  void _resetFilters() {
    setState(() {
      _minGpa = 7.0;
      _filterGender = 'Todos';
      _requireEnglish = false;
      _filterModality = 'Todos';
    });
  }

  @override
  Widget build(BuildContext context) {
    // Datos de ejemplo simulados
    final allStudents = [
      {'nombre': 'Ana García Solís', 'gpa': 9.8, 'sexo': 'Femenino', 'ingles': true, 'mod': 'Residencias', 'correo': 'ana.garcia@tesoem.edu.mx', 'habilidades': ['Flutter', 'Dart', 'Firebase', 'UI/UX']},
      {'nombre': 'Carlos Ruiz Mendoza', 'gpa': 8.5, 'sexo': 'Masculino', 'ingles': false, 'mod': 'Servicio Social', 'correo': 'carlos.ruiz@tesoem.edu.mx', 'habilidades': ['Java', 'SQL', 'Git']},
      {'nombre': 'María López Hernández', 'gpa': 9.2, 'sexo': 'Femenino', 'ingles': true, 'mod': 'Recién Egresado', 'correo': 'maria.lopez@tesoem.edu.mx', 'habilidades': ['Python', 'Data Science', 'Machine Learning']},
      {'nombre': 'Juan Pérez Gómez', 'gpa': 7.9, 'sexo': 'Masculino', 'ingles': true, 'mod': 'Residencias', 'correo': 'juan.perez@tesoem.edu.mx', 'habilidades': ['Node.js', 'React', 'MongoDB']},
    ];

    final filteredStudents = allStudents.where((s) {
      final matchesGpa = (s['gpa'] as double) >= _minGpa;
      final matchesGender = _filterGender == 'Todos' || s['sexo'] == _filterGender;
      final matchesEnglish = !_requireEnglish || (s['ingles'] as bool);
      final matchesModality = _filterModality == 'Todos' || s['mod'] == _filterModality;
      return matchesGpa && matchesGender && matchesEnglish && matchesModality;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Buscador de Talento', style: TextStyle(fontWeight: FontWeight.bold)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Talento en Sistemas',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Ajusta las prioridades de contratación para filtrar candidatos:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune, color: AppTheme.primaryGreen, size: 20),
                      SizedBox(width: 8),
                      Text('Filtros de Prioridad Universitaria', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ],
                  ),
                  const Divider(height: 24),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Promedio mínimo:', style: TextStyle(color: Colors.grey[700])),
                      Text(
                        _minGpa.toStringAsFixed(1),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen, fontSize: 16),
                      ),
                    ],
                  ),
                  Slider(
                    value: _minGpa,
                    min: 7.0,
                    max: 10.0,
                    divisions: 30,
                    activeColor: AppTheme.primaryGreen,
                    inactiveColor: AppTheme.primaryGreen.withOpacity(0.1),
                    onChanged: (val) => setState(() => _minGpa = val),
                  ),

                  Text('Estado Académico / Modalidad:', style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _filterModality,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      fillColor: Colors.white,
                      filled: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[300]!)),
                    ),
                    items: ['Todos', 'Servicio Social', 'Residencias', 'Recién Egresado']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _filterModality = val!),
                  ),
                  const SizedBox(height: 16),

                  Text('Criterios adicionales prioritarios:', style: TextStyle(color: Colors.grey[700])),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      FilterChip(
                        label: const Text('Solo Mujeres (Inclusión)'),
                        selected: _filterGender == 'Femenino',
                        selectedColor: AppTheme.primaryGreen,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(color: _filterGender == 'Femenino' ? Colors.white : Colors.black87),
                        onSelected: (val) => setState(() => _filterGender = val ? 'Femenino' : 'Todos'),
                      ),
                      FilterChip(
                        label: const Text('Inglés Obligatorio'),
                        selected: _requireEnglish,
                        selectedColor: AppTheme.primaryGreen,
                        checkmarkColor: Colors.white,
                        labelStyle: TextStyle(color: _requireEnglish ? Colors.white : Colors.black87),
                        onSelected: (val) => setState(() => _requireEnglish = val),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Candidatos coincidentes (${filteredStudents.length})',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ],
            ),
            const SizedBox(height: 12),

            filteredStudents.isEmpty
                ? _buildPremiumCompanyEmptyState()
                : ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final s = filteredStudents[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 1,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          leading: CircleAvatar(
                            radius: 24,
                            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                            child: Text(
                              s['nombre'].toString()[0],
                              style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                          title: Text(s['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text('${s['mod']} | Promedio: ${s['gpa']}', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 4,
                                children: (s['habilidades'] as List<String>).take(3).map((h) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
                                    child: Text(h, style: const TextStyle(fontSize: 10, color: Colors.black54)),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (s['ingles'] as bool)
                                const Tooltip(
                                  message: 'Inglés Fluido',
                                  child: Icon(Icons.g_translate, color: Colors.blue, size: 18),
                                ),
                              const SizedBox(height: 4),
                              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey[400]),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentDetailViewPage(student: s),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumCompanyEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_search_outlined, size: 64, color: Colors.orange),
            ),
            const SizedBox(height: 16),
            const Text(
              'Sin coincidencias de talento',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ningún estudiante cumple exactamente con los criterios actuales. Intenta suavizar el promedio mínimo o remover filtros adicionales.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey, height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _resetFilters,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text('RESTABLECER FILTROS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}
