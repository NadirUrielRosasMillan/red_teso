import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:intl/intl.dart';

class StudentApplicationsPage extends StatelessWidget {
  const StudentApplicationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) return const Center(child: Text('Inicia sesión para ver tus postulaciones'));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Mis Postulaciones', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.primaryGreen,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('applications')
            .where('studentId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_late_outlined, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'Aún no te has postulado a ninguna vacante',
                    style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final app = docs[index].data() as Map<String, dynamic>;
              final statusInfo = _getStatusInfo(app['status'] ?? 'Enviado');

              String dateStr = 'Reciente';
              if (app['createdAt'] != null) {
                final date = (app['createdAt'] as Timestamp).toDate();
                dateStr = DateFormat('dd/MM/yyyy').format(date);
              }

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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app['vacancyName'] ?? 'Vacante',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  app['companyName'] ?? 'Empresa',
                                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(statusInfo),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(dateStr, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 12),
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
                                _getStatusMessage(app['status'] ?? 'Enviado'),
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
          );
        },
      ),
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'Interesado':
      case 'Aceptado':
        return {'color': AppTheme.primaryGreen, 'icon': Icons.check_circle_outline, 'text': status};
      case 'En Revisión':
        return {'color': Colors.blue, 'icon': Icons.hourglass_empty, 'text': status};
      case 'Rechazado':
        return {'color': Colors.red, 'icon': Icons.cancel_outlined, 'text': status};
      default:
        return {'color': Colors.orange, 'icon': Icons.send_outlined, 'text': 'Enviado'};
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'Interesado':
      case 'Aceptado':
        return '¡Felicidades! La empresa está interesada en tu perfil y pronto se pondrán en contacto.';
      case 'En Revisión':
        return 'Tu postulación está siendo evaluada por el equipo de reclutamiento.';
      case 'Rechazado':
        return 'Gracias por tu interés. En esta ocasión la empresa ha decidido no continuar con tu proceso.';
      default:
        return 'Tu postulación ha sido recibida con éxito por la empresa.';
    }
  }

  Widget _buildStatusBadge(Map<String, dynamic> info) {
    final Color color = info['color'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info['icon'], size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            info['text'],
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
