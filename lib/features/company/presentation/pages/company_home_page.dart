import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reclutamiento TESOEM', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
              'Filtra candidatos según tus criterios',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // Sección de Filtros
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Criterios de Prioridad', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),

                  // Filtro Promedio
                  Text('Promedio mínimo: ${_minGpa.toStringAsFixed(1)}'),
                  Slider(
                    value: _minGpa,
                    min: 7.0,
                    max: 10.0,
                    divisions: 30,
                    activeColor: AppTheme.primaryGreen,
                    onChanged: (val) => setState(() => _minGpa = val),
                  ),

                  // Filtros Rápidos
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Solo Mujeres'),
                        selected: _filterGender == 'Femenino',
                        onSelected: (val) => setState(() => _filterGender = val ? 'Femenino' : 'Todos'),
                      ),
                      FilterChip(
                        label: const Text('Inglés Obligatorio'),
                        selected: _requireEnglish,
                        onSelected: (val) => setState(() => _requireEnglish = val),
                      ),
                    ],
                  ),

                  DropdownButton<String>(
                    isExpanded: true,
                    value: _filterModality,
                    items: ['Todos', 'Servicio Social', 'Residencias', 'Recién Egresado']
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) => setState(() => _filterModality = val!),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Resultados de búsqueda',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(onPressed: () {}, child: const Text('Ver todos')),
              ],
            ),
            const SizedBox(height: 8),
            _buildFilteredStudentList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFilteredStudentList() {
    // Datos de ejemplo
    final students = [
      {'nombre': 'Ana García', 'gpa': 9.8, 'sexo': 'Femenino', 'ingles': true, 'mod': 'Residencias'},
      {'nombre': 'Carlos Ruiz', 'gpa': 8.5, 'sexo': 'Masculino', 'ingles': false, 'mod': 'Servicio Social'},
      {'nombre': 'María López', 'gpa': 9.2, 'sexo': 'Femenino', 'ingles': true, 'mod': 'Recién Egresado'},
      {'nombre': 'Juan Pérez', 'gpa': 7.9, 'sexo': 'Masculino', 'ingles': true, 'mod': 'Residencias'},
    ];

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final s = students[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
              child: Text(s['nombre'].toString()[0], style: const TextStyle(color: AppTheme.primaryGreen)),
            ),
            title: Text(s['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Carrera: Ing. Sistemas Computacionales'),
                Text('${s['mod']} | Promedio: ${s['gpa']}'),
                if (s['ingles'] as bool)
                  const Text('✅ Inglés Fluido', style: TextStyle(color: Colors.blue, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 20),
                Text(s['sexo'] == 'Femenino' ? '👩' : '👨'),
              ],
            ),
            onTap: () {
              // Abrir perfil detallado
            },
          ),
        );
      },
    );
  }
}
