import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:red_teso/core/services/fcm_notification_service.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/core/widgets/liquid_glass_ambient_background.dart';
import 'package:red_teso/features/company/presentation/pages/student_detail_view_page.dart';
import 'package:red_teso/features/company/presentation/widgets/contact_student_modal.dart';
import 'package:red_teso/features/company/presentation/widgets/rate_student_modal.dart';

class CompanyApplicantsPage extends StatefulWidget {
  const CompanyApplicantsPage({super.key});

  @override
  State<CompanyApplicantsPage> createState() => _CompanyApplicantsPageState();
}

class _CompanyApplicantsPageState extends State<CompanyApplicantsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedFilter = 'Todos';

  Future<void> _updateStatus(String docId, String newStatus, String studentId, String vacancyName) async {
    try {
      await _db.collection('applications').doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (studentId.isNotEmpty) {
        String title = 'Actualización de Postulación';
        String message = 'Tu proceso para "$vacancyName" ha sido actualizado.';

        if (newStatus == 'En Entrevista') {
          title = '¡Invitación a Entrevista! 🎯✨';
          message = 'Has avanzado a la etapa de ENTREVISTA para la vacante "$vacancyName". ¡La empresa se pondrá en contacto contigo muy pronto!';
        } else if (newStatus == 'Aceptado') {
          title = '¡Felicidades! Postulación Aceptada 🎉';
          message = 'Has sido ACEPTADO para la vacante "$vacancyName". Pronto se pondrán en contacto contigo.';
        } else if (newStatus == 'Descartado' || newStatus == 'Rechazado') {
          title = 'Proceso Finalizado';
          message = 'Tu postulación para "$vacancyName" ha finalizado.';
        }

        await FcmNotificationService.sendPushNotification(
          targetUserId: studentId,
          title: title,
          message: message,
        );
      }

      if (!mounted) return;

      Color snackColor = AppTheme.primaryColor;
      if (newStatus == 'En Entrevista') snackColor = Colors.amber;
      if (newStatus == 'Descartado' || newStatus == 'Rechazado') snackColor = Colors.redAccent;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text('Postulación actualizada a "$newStatus"', style: GoogleFonts.inter()),
              ),
            ],
          ),
          backgroundColor: snackColor,
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
      return Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: Center(child: Text('Inicia sesión para ver los postulados', style: GoogleFonts.inter(color: Colors.white))),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Postulaciones Recibidas', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF090D16).withOpacity(0.85),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: LiquidGlassAmbientBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('applications').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Error al cargar las postulaciones', style: GoogleFonts.inter(color: Colors.white)));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildShimmerSkeletonList();
            }

            final rawDocs = snapshot.data?.docs ?? [];

            final allDocs = rawDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final cId = data['companyId'] ?? '';
              final sName = (data['studentName'] ?? '').toString().trim();

              final isSimulation = sName == 'Alumno TESOEM' || sName == 'Alumno Registrado' || sName.isEmpty;
              final isMyCompany = cId == user.uid || cId.toString().isEmpty;
              return isMyCompany && !isSimulation;
            }).toList();

            final totalCount = allDocs.length;
            final pendingCount = allDocs.where((d) {
              final st = (d.data() as Map<String, dynamic>)['status'] ?? 'Pendiente';
              return st == 'Pendiente' || st == 'Enviado';
            }).length;
            final interviewCount = allDocs.where((d) {
              return (d.data() as Map<String, dynamic>)['status'] == 'En Entrevista';
            }).length;
            final acceptedCount = allDocs.where((d) {
              return (d.data() as Map<String, dynamic>)['status'] == 'Aceptado';
            }).length;
            final rejectedCount = allDocs.where((d) {
              final st = (d.data() as Map<String, dynamic>)['status'] ?? '';
              return st == 'Descartado' || st == 'Rechazado';
            }).length;

            final filteredDocs = allDocs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final st = data['status'] ?? 'Pendiente';

              if (_selectedFilter == 'Pendientes') return st == 'Pendiente' || st == 'Enviado';
              if (_selectedFilter == 'En Entrevista') return st == 'En Entrevista';
              if (_selectedFilter == 'Aceptados') return st == 'Aceptado';
              if (_selectedFilter == 'Descartados') return st == 'Descartado' || st == 'Rechazado';
              return true;
            }).toList();

            return Column(
              children: [
                // Chips de Filtro
                Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      children: [
                        _buildFilterChip('Todos', totalCount, Icons.list_alt_rounded),
                        _buildFilterChip('Pendientes', pendingCount, Icons.hourglass_top_rounded),
                        _buildFilterChip('En Entrevista', interviewCount, Icons.event_available_rounded),
                        _buildFilterChip('Aceptados', acceptedCount, Icons.check_circle_rounded),
                        _buildFilterChip('Descartados', rejectedCount, Icons.cancel_rounded),
                      ],
                    ),
                  ),
                ),

                const Divider(height: 1, color: Colors.white12),

                Expanded(
                  child: filteredDocs.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final app = filteredDocs[index].data() as Map<String, dynamic>;
                            final docId = filteredDocs[index].id;
                            final studentName = app['studentName'] ?? 'Alumno Registrado';
                            final studentId = app['studentId'] ?? '';
                            final vacancyName = app['vacancyName'] ?? 'Vacante';
                            final status = app['status'] ?? 'Pendiente';

                            return GlassmorphicCard(
                              glowColor: AppTheme.primaryColor,
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => StudentDetailViewPage(
                                      student: {
                                        'uid': studentId,
                                        'name': studentName,
                                        'email': app['studentEmail'],
                                      },
                                    ),
                                  ),
                                );
                              },
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
                                              studentName,
                                              style: GoogleFonts.outfit(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Vacante: $vacancyName',
                                              style: GoogleFonts.inter(
                                                color: AppTheme.accentColor,
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      _buildStatusBadge(status),
                                    ],
                                  ),

                                  const Divider(height: 24, color: Colors.white12),

                                  Row(
                                    children: [
                                      if (status == 'Pendiente' || status == 'Enviado') ...[
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateStatus(docId, 'En Entrevista', studentId, vacancyName),
                                            icon: const Icon(Icons.event_available_rounded, size: 15, color: Colors.white),
                                            label: Text(
                                              'ENTREVISTA 🎯',
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.amber[800],
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateStatus(docId, 'Aceptado', studentId, vacancyName),
                                            icon: const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                                            label: Text(
                                              'ACEPTAR ✅',
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryColor,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                                          tooltip: 'Descartar',
                                          onPressed: () => _updateStatus(docId, 'Descartado', studentId, vacancyName),
                                        ),
                                      ] else if (status == 'En Entrevista') ...[
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: () => _updateStatus(docId, 'Aceptado', studentId, vacancyName),
                                            icon: const Icon(Icons.check_circle_rounded, size: 15, color: Colors.white),
                                            label: Text(
                                              'ACEPTAR CANDIDATO ✅',
                                              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                                            ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: AppTheme.primaryColor,
                                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                              padding: const EdgeInsets.symmetric(vertical: 10),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        IconButton(
                                          icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                                          tooltip: 'Descartar',
                                          onPressed: () => _updateStatus(docId, 'Descartado', studentId, vacancyName),
                                        ),
                                      ],

                                      const SizedBox(width: 6),

                                      IconButton(
                                        icon: const Icon(Icons.send_rounded, color: AppTheme.accentColor, size: 20),
                                        tooltip: 'Contactar Mensaje',
                                        onPressed: () {
                                          ContactStudentModal.show(context, student: app);
                                        },
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 22),
                                        tooltip: 'Evaluar Alumno ⭐',
                                        onPressed: () {
                                          RateStudentModal.show(context, student: app);
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ).animate(delay: (index * 70).ms).fadeIn(duration: 400.ms, curve: Curves.easeOut).slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
                          },
                        ),
                ),
              ],
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

  Widget _buildFilterChip(String label, int count, IconData icon) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        showCheckmark: false,
        avatar: Icon(icon, size: 15, color: isSelected ? Colors.white : AppTheme.accentColor),
        label: Text(
          '$label ($count)',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        selected: isSelected,
        selectedColor: AppTheme.primaryColor,
        backgroundColor: const Color(0xFF1E293B),
        shape: StadiumBorder(
          side: BorderSide(
            color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.25),
          ),
        ),
        onSelected: (_) {
          setState(() => _selectedFilter = label);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 60, color: AppTheme.accentColor),
            ),
            const SizedBox(height: 18),
            Text(
              'No hay candidatos en esta sección',
              style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 6),
            Text(
              'Las postulaciones de los alumnos aparecerán en tiempo real bajo la pestaña correspondiente.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orangeAccent;
    String label = status.toUpperCase();

    if (status == 'En Entrevista') {
      color = Colors.amber;
      label = '🎯 EN ENTREVISTA';
    } else if (status == 'Aceptado') {
      color = AppTheme.primaryGreen;
      label = '✅ ACEPTADO';
    } else if (status == 'Descartado' || status == 'Rechazado') {
      color = Colors.redAccent;
      label = '❌ DESCARTADO';
    } else if (status == 'Pendiente' || status == 'Enviado') {
      color = Colors.orangeAccent;
      label = '⏳ PENDIENTE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 10.5,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
