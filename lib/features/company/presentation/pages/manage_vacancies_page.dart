import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/company/presentation/pages/create_vacancy_page.dart';

class ManageVacanciesPage extends StatefulWidget {
  const ManageVacanciesPage({super.key});

  @override
  State<ManageVacanciesPage> createState() => _ManageVacanciesPageState();
}

class _ManageVacanciesPageState extends State<ManageVacanciesPage> {
  // Lista simulada de vacantes publicadas por esta empresa
  final List<Map<String, dynamic>> _myVacancies = [
    {
      'id': 'vac-1',
      'puesto': 'Desarrollador Flutter Junior',
      'tipo': 'Residencias',
      'estado': 'Activa',
      'postulados': 12,
      'fecha': 'Publicado hace 3 días',
      'descripcion': 'Buscamos un estudiante de Ingeniería en Sistemas Computacionales entusiasta por el desarrollo móvil.',
      'gpa': 8.5,
      'ingles': true,
      'requisitos': ['Flutter & Dart', 'Git', 'Promedio mínimo 8.5']
    },
    {
      'id': 'vac-2',
      'puesto': 'Soporte Técnico',
      'tipo': 'Servicio Social',
      'estado': 'Pausada',
      'postulados': 5,
      'fecha': 'Publicado hace 1 semana',
      'descripcion': 'Apoyo en mantenimiento preventivo y correctivo de hardware.',
      'gpa': 7.5,
      'ingles': false,
      'requisitos': ['Redes básicas', 'Hardware']
    },
  ];

  void _toggleVacancyStatus(int index) {
    setState(() {
      final current = _myVacancies[index]['estado'];
      _myVacancies[index]['estado'] = (current == 'Activa') ? 'Pausada' : 'Activa';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado de la vacante actualizado.'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _deleteVacancy(int index) {
    final title = _myVacancies[index]['puesto'];
    setState(() {
      _myVacancies.removeAt(index);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Vacante "$title" eliminada visualmente.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Mis Vacantes', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
      ),
      body: _myVacancies.isEmpty
          ? _buildEmptyState()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _myVacancies.length,
              itemBuilder: (context, index) {
                final v = _myVacancies[index];
                final isActive = v['estado'] == 'Activa';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isActive ? Colors.green[50] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                v['estado'],
                                style: TextStyle(
                                  color: isActive ? AppTheme.primaryGreen : Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(v['fecha'], style: TextStyle(color: Colors.grey[500], fontSize: 11)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          v['puesto'],
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(v['tipo'], style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Icon(Icons.people_outline, size: 18, color: AppTheme.primaryGreen),
                            const SizedBox(width: 8),
                            Text(
                              '${v['postulados']} alumnos postulados',
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CreateVacancyPage(vacancyToEdit: v),
                                      ),
                                    );
                                  },
                                  tooltip: 'Editar vacante',
                                ),
                                IconButton(
                                  icon: Icon(
                                    isActive ? Icons.pause_circle_outline : Icons.play_circle_outline,
                                    color: Colors.orange,
                                  ),
                                  onPressed: () => _toggleVacancyStatus(index),
                                  tooltip: isActive ? 'Pausar' : 'Activar',
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _deleteVacancy(index),
                                  tooltip: 'Eliminar',
                                ),
                              ],
                            ),
                            TextButton(
                              onPressed: () {
                                // Aquí se navegaría a la lista de postulados filtrada por esta vacante
                              },
                              child: const Text('VER POSTULADOS'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.list_alt, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text(
            'Aún no has publicado vacantes',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              // Navegar a la pestaña de creación
            },
            child: const Text('PUBLICAR MI PRIMERA VACANTE'),
          ),
        ],
      ),
    );
  }
}
