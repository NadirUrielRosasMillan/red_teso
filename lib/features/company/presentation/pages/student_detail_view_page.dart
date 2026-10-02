import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/company/presentation/widgets/contact_student_modal.dart';
import 'package:red_teso/features/company/presentation/widgets/invite_student_modal.dart';
import 'package:red_teso/features/company/presentation/widgets/rate_student_modal.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentDetailViewPage extends StatelessWidget {
  final Map<String, dynamic> student;

  const StudentDetailViewPage({super.key, required this.student});

  void _openDocumentDialog(BuildContext context, String title, String? fileName, String? fileUrl) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre del Archivo:', style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF64748B))),
            const SizedBox(height: 2),
            Text(
              fileName ?? 'Documento_Oficial.pdf',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppTheme.primaryColor, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Documento verificado y autenticado por el alumno en RedTESO.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('CERRAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              if (fileUrl != null && fileUrl.isNotEmpty) {
                final uri = Uri.parse(fileUrl);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
            icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.white),
            label: Text('ABRIR DOCUMENTO PDF', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = student;
    final studentId = s['uid'] ?? s['id'] ?? s['studentId'];
    final name = s['name'] ?? 'Alumno Registrado';
    final career = s['career'] ?? 'Ingeniería en Sistemas Computacionales';
    final gpa = s['gpa']?.toString() ?? 'N/A';
    final modality = s['modality'] ?? 'Residencias';
    final speaksEnglish = s['speaksEnglish'] == true ? 'Sí (Avanzado)' : 'Básico';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Perfil del Candidato', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        foregroundColor: const Color(0xFF0F172A),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tarjeta de Cabecera
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6)),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                    child: Text(
                      name[0],
                      style: GoogleFonts.outfit(fontSize: 36, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    career,
                    style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                    textAlign: TextAlign.center,
                  ),
                  if (s['role'] != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        s['role'],
                        style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Métricas académicas
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricItem('Promedio', gpa, Icons.star_rounded),
                  Container(height: 30, width: 1, color: Colors.grey[200]),
                  _buildMetricItem('Modalidad', modality, Icons.school_rounded),
                  Container(height: 30, width: 1, color: Colors.grey[200]),
                  _buildMetricItem('Inglés', speaksEnglish, Icons.translate_rounded),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Botones de Acción
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () {
                  InviteStudentModal.show(context, student: s);
                },
                icon: const Icon(Icons.mark_email_read_rounded, color: Colors.white, size: 20),
                label: Text(
                  'INVITAR A VACANTE DIRECTA 📩',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      RateStudentModal.show(context, student: s);
                    },
                    icon: const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                    label: Text(
                      'EVALUAR ⭐',
                      style: GoogleFonts.outfit(color: Colors.amber[900], fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.amber[700]!, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ContactStudentModal.show(context, student: s);
                    },
                    icon: const Icon(Icons.send_rounded, color: AppTheme.primaryColor, size: 18),
                    label: Text(
                      'CONTACTAR ✉️',
                      style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Sección Documentos Oficiales en PDF (CV y Kárdex)
            Text(
              'Documentos Verificados del Candidato 📄',
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            _buildRealTimeDocuments(context, studentId),

            const SizedBox(height: 28),

            // Sección Evaluaciones y Reseñas de Empresas
            Text(
              'Evaluaciones y Reseñas de Empresas ⭐',
              style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
            const SizedBox(height: 12),

            _buildRealTimeEvaluations(studentId),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildRealTimeDocuments(BuildContext context, String? studentId) {
    if (studentId == null || studentId.isEmpty) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(studentId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final cvName = data['cvFileName'];
        final cvUrl = data['cvUrl'];
        final kardexName = data['kardexFileName'];
        final kardexUrl = data['kardexUrl'];

        final hasCv = cvName != null && cvName.toString().isNotEmpty;
        final hasKardex = kardexName != null && kardexName.toString().isNotEmpty;

        if (!hasCv && !hasKardex) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: Colors.grey, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'El candidato aún no ha adjuntado archivos PDF en su perfil.',
                    style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            if (hasCv)
              _buildDocCard(
                context,
                title: 'Curriculum Vitae (CV en PDF)',
                fileName: cvName.toString(),
                fileUrl: cvUrl?.toString(),
              ),
            if (hasCv && hasKardex) const SizedBox(height: 10),
            if (hasKardex)
              _buildDocCard(
                context,
                title: 'Kárdex Oficial TESOEM',
                fileName: kardexName.toString(),
                fileUrl: kardexUrl?.toString(),
              ),
          ],
        );
      },
    );
  }

  Widget _buildDocCard(BuildContext context, {required String title, required String fileName, String? fileUrl}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F172A))),
                Text(fileName, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => _openDocumentDialog(context, title, fileName, fileUrl),
            icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.white),
            label: Text('VER PDF', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeEvaluations(String? studentId) {
    if (studentId == null || studentId.isEmpty) {
      return const Text('Sin evaluaciones registradas.');
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('evaluations')
          .where('studentId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const Text('Error cargando reseñas.');
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                const Icon(Icons.rate_review_outlined, size: 40, color: Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Aún no cuenta con evaluaciones escritas por empresas',
                  style: GoogleFonts.inter(fontSize: 12.5, color: const Color(0xFF64748B)),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final e = docs[index].data() as Map<String, dynamic>;
            final companyName = e['companyName'] ?? 'Empresa Colaboradora';
            final rating = (e['rating'] ?? 5.0).toDouble();
            final comment = e['comment'] ?? 'Sin comentarios';
            final modality = e['modality'] ?? 'Residencias Profesional';

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        companyName,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: const Color(0xFF0F172A)),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.amber[800], fontSize: 13.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      modality,
                      style: GoogleFonts.inter(fontSize: 11, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '"$comment"',
                    style: GoogleFonts.inter(fontSize: 12.5, height: 1.4, color: const Color(0xFF334155), fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMetricItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 22),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
        Text(label, style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF64748B))),
      ],
    );
  }
}
