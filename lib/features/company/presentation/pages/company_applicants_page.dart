import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';
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

  // Actualiza el estado de la postulación en la nube y notifica en tiempo real al alumno
  Future<void> _updateStatus(String docId, String newStatus, String studentId, String vacancyName) async {
    try {
      await _db.collection('applications').doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Enviar notificación automática en tiempo real al alumno
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

        await _db.collection('notifications').add({
          'toUserId': studentId,
          'title': title,
          'message': message,
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
        });
      }

      if (!mounted) return;

      Color snackColor = AppTheme.primaryColor;
      if (newStatus == 'En Entrevista') snackColor = Colors.amber[800]!;
      if (newStatus == 'Descartado' || newStatus == 'Rechazado') snackColor = Colors.red;

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
        stream: _db.collection('applications').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar las postulaciones'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
          }

          final rawDocs = snapshot.data?.docs ?? [];

          // Filtrar postulaciones dirigidas a esta empresa y omitir simulaciones / pruebas de 'Alumno TESOEM'
          final allDocs = rawDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final cId = data['companyId'] ?? '';
            final sName = (data['studentName'] ?? '').toString().trim();

            // Omitir postulaciones simuladas de prueba con nombres genéricos
            final isSimulation = sName == 'Alumno TESOEM' || sName == 'Alumno Registrado' || sName.isEmpty;

            final isMyCompany = cId == user.uid || cId.toString().isEmpty;
            return isMyCompany && !isSimulation;
          }).toList();

          // Calcular conteo por estado
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

          // Filtrar lista según chip seleccionado
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
              // Barra Horizontal de Filtros por Estado (Chips)
              Container(
                color: Colors.white,
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

              const Divider(height: 1),

              // Lista de Postulaciones Filtradas
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

                          return GestureDetector(
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
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(24),
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
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Fila Nombre + Badge de Estado
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
                                                  color: const Color(0xFF0F172A),
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Vacante: $vacancyName',
                                                style: GoogleFonts.inter(
                                                  color: const Color(0xFF64748B),
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

                                    const Divider(height: 24),

                                    // Fila de Acciones Rápidas Unificadas
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
                                            icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
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
                                            icon: const Icon(Icons.close_rounded, color: Colors.red, size: 20),
                                            tooltip: 'Descartar',
                                            onPressed: () => _updateStatus(docId, 'Descartado', studentId, vacancyName),
                                          ),
                                        ],

                                        const SizedBox(width: 6),

                                        IconButton(
                                          icon: const Icon(Icons.send_rounded, color: AppTheme.primaryColor, size: 20),
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
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, int count, IconData icon) {
    final isSelected = _selectedFilter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        avatar: Icon(icon, size: 15, color: isSelected ? Colors.white : AppTheme.primaryColor),
        label: Text('$label ($count)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : const Color(0xFF0F172A))),
        selected: isSelected,
        selectedColor: AppTheme.primaryColor,
        backgroundColor: Colors.white,
        shape: StadiumBorder(side: BorderSide(color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0))),
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
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.people_outline_rounded, size: 60, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 18),
            Text(
              'No hay candidatos en esta sección',
              style: GoogleFonts.outfit(fontSize: 19, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 6),
            Text(
              'Las postulaciones de los alumnos aparecerán en tiempo real bajo la pestaña correspondiente.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    String label = status.toUpperCase();

    if (status == 'En Entrevista') {
      color = Colors.amber[800]!;
      label = '🎯 EN ENTREVISTA';
    } else if (status == 'Aceptado') {
      color = AppTheme.primaryColor;
      label = '✅ ACEPTADO';
    } else if (status == 'Descartado' || status == 'Rechazado') {
      color = Colors.red;
      label = '❌ DESCARTADO';
    } else if (status == 'Pendiente' || status == 'Enviado') {
      color = Colors.orange;
      label = '⏳ PENDIENTE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 10.5,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
