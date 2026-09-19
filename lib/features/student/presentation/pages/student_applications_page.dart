import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class StudentApplicationsPage extends StatelessWidget {
  const StudentApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Lista simulada de postulaciones con estados (Requisito 9.1.11)
    final List<Map<String, dynamic>> applications = [
      {
        'puesto': 'Desarrollador Flutter Junior',
        'empresa': 'Tech Solutions TESOEM',
        'tipo': 'Residencias',
        'fecha': 'Hace 2 días',
        'estado': 'Interesado', // Verde
        'color': AppTheme.primaryGreen,
        'icono': Icons.check_circle_outline,
        'mensaje': 'La empresa ha revisado tu kárdex y se pondrá en contacto contigo para una entrevista.'
      },
      {
        'puesto': 'Soporte Técnico e Infraestructura',
        'empresa': 'Innovación Digital S.A.',
        'tipo': 'Servicio Social',
        'fecha': 'Hace 5 días',
        'estado': 'En Revisión', // Azul
        'color': Colors.blue,
        'icono': Icons.hourglass_empty,
        'mensaje': 'Tu postulación está siendo evaluada por el departamento de Recursos Humanos.'
      },
      {
        'puesto': 'Analista de Datos Interno',
        'empresa': 'Banco Comercial del Oriente',
        'tipo': 'Empleo Egresados',
        'fecha': 'Hace 1 semana',
        'estado': 'Enviado', // Amarillo/Naranja
        'color': Colors.orange,
        'icono': Icons.send_outlined,
        'mensaje': 'Tu CV fue recibido con éxito por el reclutador.'
      },
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mis Postulaciones', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: applications.length,
        itemBuilder: (context, index) {
          final app = applications[index];
          final Color statusColor = app['color'] as Color;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encabezado de la tarjeta
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app['puesto'] as String,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              app['empresa'] as String,
                              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      // Etiqueta de estado con colores (Requisito 9.1.11)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: statusColor, width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(app['icono'] as IconData, size: 14, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              app['estado'] as String,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  // Detalles adicionales
                  Row(
                    children: [
                      Icon(Icons.label_outline, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 6),
                      Text(app['tipo'] as String, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      const Spacer(),
                      Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(app['fecha'] as String, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Mensaje de seguimiento informativo
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            app['mensaje'] as String,
                            style: TextStyle(fontSize: 12, color: Colors.grey[700], height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
