import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class CompanyApplicantsPage extends StatefulWidget {
  const CompanyApplicantsPage({super.key});

  @override
  State<CompanyApplicantsPage> createState() => _CompanyApplicantsPageState();
}

class _CompanyApplicantsPageState extends State<CompanyApplicantsPage> {
  // Lista simulada de postulantes a las vacantes de la empresa (Requisito 9.1.12)
  final List<Map<String, dynamic>> _applicants = [
    {
      'id': '1',
      'nombre': 'Ana García Solís',
      'puesto': 'Desarrollador Flutter Junior',
      'gpa': 9.8,
      'ingles': true,
      'mod': 'Residencias',
      'estado': 'Pendiente',
    },
    {
      'id': '2',
      'nombre': 'Carlos Ruiz Mendoza',
      'puesto': 'Soporte Técnico e Infraestructura',
      'gpa': 8.5,
      'ingles': false,
      'mod': 'Servicio Social',
      'estado': 'Aceptado',
    },
    {
      'id': '3',
      'nombre': 'Juan Pérez Gómez',
      'puesto': 'Desarrollador Flutter Junior',
      'gpa': 7.9,
      'ingles': true,
      'mod': 'Residencias',
      'estado': 'Rechazado',
    },
  ];

  void _updateStatus(String id, String newStatus) {
    setState(() {
      final index = _applicants.indexWhere((element) => element['id'] == id);
      if (index != -1) {
        _applicants[index]['estado'] = newStatus;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Estado actualizado a $newStatus visualmente.'),
        backgroundColor: newStatus == 'Aceptado' ? AppTheme.primaryGreen : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Postulaciones Recibidas', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gestión de Candidatos',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const Text(
              'Revisa y da seguimiento a los alumnos interesados en tus vacantes:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _applicants.length,
              itemBuilder: (context, index) {
                final a = _applicants[index];
                Color statusColor = Colors.orange;
                if (a['estado'] == 'Aceptado') statusColor = AppTheme.primaryGreen;
                if (a['estado'] == 'Rechazado') statusColor = Colors.red;

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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                              child: Text(a['nombre'][0], style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(a['nombre'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text('Vacante: ${a['puesto']}', style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Text('${a['mod']} | Promedio: ${a['gpa']}', style: const TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: statusColor),
                              ),
                              child: Text(
                                a['estado'] as String,
                                style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11),
                              ),
                            )
                          ],
                        ),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton.icon(
                              onPressed: () => _updateStatus(a['id'] as String, 'Rechazado'),
                              icon: const Icon(Icons.close, color: Colors.red, size: 18),
                              label: const Text('Descartar', style: TextStyle(color: Colors.red)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(a['id'] as String, 'Aceptado'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              icon: const Icon(Icons.check, color: Colors.white, size: 18),
                              label: const Text('Aceptar Perfil', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
