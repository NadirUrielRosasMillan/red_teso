import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/core/widgets/liquid_glass_ambient_background.dart';

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
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('¿Eliminar Postulación?', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        content: Text('¿Estás seguro de eliminar la postulación para "$vacancyName"? Esta acción la removerá de tu historial.', style: GoogleFonts.inter(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCELAR', style: GoogleFonts.inter(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('ELIMINAR', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
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
      return Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: Center(child: Text('Inicia sesión para ver tus postulaciones', style: GoogleFonts.inter(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Mis Postulaciones', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF090D16).withOpacity(0.85),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LiquidGlassAmbientBackground(
        child: StreamBuilder<QuerySnapshot>(
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
                      const Icon(Icons.sync_problem_rounded, size: 56, color: AppTheme.accentColor),
                      const SizedBox(height: 14),
                      Text(
                        'Sincronizando con la nube...',
                        style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Tus postulaciones se están actualizando en tiempo real.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return _buildShimmerSkeletonList();
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
                          color: AppTheme.primaryGreen.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.assignment_turned_in_rounded, size: 60, color: AppTheme.accentColor),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Aún no te has postulado a vacantes',
                        style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Explora las oportunidades disponibles para Residencias y Servicio Social y postúlate con un solo toque.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
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

                return GlassmorphicCard(
                  glowColor: statusInfo['color'] as Color,
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
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  app['companyName'] ?? 'Empresa Colaboradora',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: AppTheme.accentColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(statusInfo),
                        ],
                      ),
                      const Divider(height: 24, color: Colors.white12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded, size: 15, color: Colors.white70),
                              const SizedBox(width: 6),
                              Text(
                                'Fecha de postulación: $dateStr',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                            tooltip: 'Eliminar del Historial',
                            onPressed: () => _confirmDeleteApplication(context, docId, app['vacancyName'] ?? 'Vacante'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: (statusInfo['color'] as Color).withOpacity(0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: (statusInfo['color'] as Color).withOpacity(0.35)),
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
                                  color: Colors.white,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate(delay: (index * 70).ms).fadeIn(duration: 400.ms, curve: Curves.easeOut).slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildShimmerSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.08),
          highlightColor: Colors.white.withOpacity(0.18),
          child: Container(
            height: 120,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }

  Map<String, dynamic> _getStatusInfo(String status) {
    switch (status) {
      case 'Interesado':
      case 'Aceptado':
        return {'color': AppTheme.primaryGreen, 'icon': Icons.check_circle_rounded, 'text': 'Aceptado'};
      case 'En Entrevista':
        return {'color': Colors.amber, 'icon': Icons.event_available_rounded, 'text': 'En Entrevista'};
      case 'En Revisión':
        return {'color': Colors.blueAccent, 'icon': Icons.hourglass_empty_rounded, 'text': 'En Revisión'};
      case 'Descartado':
      case 'Rechazado':
        return {'color': Colors.redAccent, 'icon': Icons.cancel_rounded, 'text': 'Descartado'};
      default:
        return {'color': Colors.orangeAccent, 'icon': Icons.send_rounded, 'text': 'Enviado'};
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
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info['icon'], size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            info['text'],
            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}
