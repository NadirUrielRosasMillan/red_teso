import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class StudentApplicationsPage extends StatelessWidget {
  const StudentApplicationsPage({super.key});

  DateTime? _getDateTime(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is DateTime) return val;
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  Future<void> _confirmDeleteApplication(BuildContext context, String docId, String vacancyName) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar Postulación?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Text('¿Estás seguro de eliminar la postulación para "$vacancyName"? Esta acción la removerá de tu historial.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('CANCELAR'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('ELIMINAR', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance.collection('applications').doc(docId).delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Postulación "$vacancyName" eliminada del historial'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        debugPrint('Error al eliminar postulación: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final FirebaseFirestore db = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver tus postulaciones')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Mis Postulaciones', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: db
            .collection('applications')
            .where('studentId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sync_problem_rounded, size: 56, color: AppTheme.primaryGreen),
                    const SizedBox(height: 14),
                    Text(
                      'Sincronizando con la nube...',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tus postulaciones se están actualizando en tiempo real.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen));
          }

          final docs = snapshot.data?.docs.toList() ?? [];

          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;
            final aTime = _getDateTime(aData['createdAt']);
            final bTime = _getDateTime(bData['createdAt']);
            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return -1;
            if (bTime == null) return 1;
            return bTime.compareTo(aTime);
          });

          if (docs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.assignment_turned_in_rounded, size: 60, color: AppTheme.primaryGreen),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      'Aún no te has postulado a vacantes',
                      style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Explora las oportunidades disponibles para Residencias y Servicio Social y postúlate con un solo toque.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final docId = docs[index].id;
              final app = docs[index].data() as Map<String, dynamic>;
              final statusStr = app['status'] ?? 'Enviado';
              final statusInfo = _getStatusInfo(statusStr);

              String dateStr = 'Reciente';
              final date = _getDateTime(app['createdAt']);
              if (date != null) {
                dateStr = DateFormat('dd/MM/yyyy').format(date);
              }

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app['vacancyName'] ?? 'Vacante TESOEM',
                                  style: GoogleFonts.outfit(
                                    fontSize: 17.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  app['companyName'] ?? 'Empresa Colaboradora',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.primaryGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(statusInfo),
                        ],
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 15, color: Color(0xFF64748B)),
                              const SizedBox(width: 6),
                              Text(
                                'Fecha de postulación: $dateStr',
                                style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                            tooltip: 'Eliminar del Historial',
                            onPressed: () => _confirmDeleteApplication(context, docId, app['vacancyName'] ?? 'Vacante'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (statusInfo['color'] as Color).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: (statusInfo['color'] as Color).withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.info_outline_rounded, size: 17, color: statusInfo['color'] as Color),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _getStatusMessage(statusStr),
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  color: const Color(0xFF334155),
                                  height: 1.4,
                                ),
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
        return {'color': AppTheme.primaryGreen, 'icon': Icons.check_circle_rounded, 'text': 'Aceptado'};
      case 'En Entrevista':
        return {'color': Colors.amber[800]!, 'icon': Icons.event_available_rounded, 'text': 'En Entrevista'};
      case 'En Revisión':
        return {'color': Colors.blue, 'icon': Icons.hourglass_empty_rounded, 'text': 'En Revisión'};
      case 'Descartado':
      case 'Rechazado':
        return {'color': Colors.red, 'icon': Icons.cancel_rounded, 'text': 'Descartado'};
      default:
        return {'color': Colors.orange, 'icon': Icons.send_rounded, 'text': 'Enviado'};
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'Interesado':
      case 'Aceptado':
        return '¡Felicidades! La empresa ha aceptado tu postulación y pronto se pondrán en contacto contigo.';
      case 'En Entrevista':
        return '¡Excelente noticia! La empresa te ha invitado a avanzar a la etapa de entrevista. Revisa tu panel de notificaciones.';
      case 'En Revisión':
        return 'Tu postulación está siendo evaluada por el equipo de reclutamiento de la empresa.';
      case 'Descartado':
      case 'Rechazado':
        return 'Gracias por tu interés. En esta ocasión el proceso para esta vacante ha finalizado.';
      default:
        return 'Tu postulación ha sido recibida con éxito por la empresa.';
    }
  }

  Widget _buildStatusBadge(Map<String, dynamic> info) {
    final Color color = info['color'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info['icon'], size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            info['text'],
            style: GoogleFonts.inter(color: color, fontWeight: FontWeight.bold, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
