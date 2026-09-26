import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/company/presentation/pages/student_evaluation_page.dart';

class CompanyApplicantsPage extends StatefulWidget {
  const CompanyApplicantsPage({super.key});

  @override
  State<CompanyApplicantsPage> createState() => _CompanyApplicantsPageState();
}

class _CompanyApplicantsPageState extends State<CompanyApplicantsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Actualiza el estado de la postulación en la nube y notifica al alumno
  Future<void> _updateStatus(String docId, String newStatus, String studentId, String vacancyName) async {
    try {
      await _db.collection('applications').doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Enviar notificación automática en tiempo real al alumno
      if (studentId.isNotEmpty) {
        await _db.collection('notifications').add({
          'toUserId': studentId,
          'title': newStatus == 'Aceptado' ? '¡Felicidades! Postulación Aceptada 🎉' : 'Actualización de Postulación',
          'message': newStatus == 'Aceptado'
              ? 'Has sido ACEPTADO para la vacante "$vacancyName". Pronto se pondrán en contacto contigo.'
              : 'Tu postulación para "$vacancyName" ha sido descartada.',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Text('Postulación $newStatus con éxito', style: GoogleFonts.inter()),
            ],
          ),
          backgroundColor: newStatus == 'Aceptado' ? AppTheme.primaryColor : Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Error al actualizar estado: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('Inicia sesión para ver los postulados')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Postulaciones Recibidas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection('applications')
            .where('companyId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar las postulaciones'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }

          final docs = snapshot.data!.docs;

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
                        color: AppTheme.primaryColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.people_outline_rounded, size: 64, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Aún no hay candidatos postulados',
                      style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cuando los alumnos de Sistemas se postulen a tus vacantes, aparecerán aquí en tiempo real.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13.5, color: const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final app = docs[index].data() as Map<String, dynamic>;
              final docId = docs[index].id;
              final studentName = app['studentName'] ?? 'Alumno Registrado';
              final studentId = app['studentId'] ?? '';
              final vacancyName = app['vacancyName'] ?? 'Vacante';
              final status = app['status'] ?? 'Pendiente';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                                  studentName,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Vacante: $vacancyName',
                                  style: GoogleFonts.inter(
                                    color: const Color(0xFF64748B),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _buildStatusBadge(status),
                        ],
                      ),

                      const Divider(height: 28),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (status == 'Pendiente') ...[
                            TextButton.icon(
                              onPressed: () => _updateStatus(docId, 'Rechazado', studentId, vacancyName),
                              icon: const Icon(Icons.close_rounded, size: 16, color: Colors.red),
                              label: Text('DESCARTAR', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton.icon(
                              onPressed: () => _updateStatus(docId, 'Aceptado', studentId, vacancyName),
                              icon: const Icon(Icons.check_rounded, size: 16),
                              label: Text('ACEPTAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          IconButton(
                            icon: const Icon(Icons.star_outline_rounded, color: Colors.amber),
                            tooltip: 'Evaluar Alumno',
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentEvaluationPage(student: app),
                                ),
                              );
                            },
                          ),
                        ],
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

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'Aceptado') color = AppTheme.primaryColor;
    if (status == 'Rechazado') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
