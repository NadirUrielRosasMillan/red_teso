import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/core/widgets/liquid_glass_ambient_background.dart';
import 'package:red_teso/features/company/presentation/pages/company_dashboard_page.dart';
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
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.picture_as_pdf_rounded, color: Colors.redAccent, size: 28),
            const SizedBox(width: 10),
            Expanded(child: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textPrimaryLight))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre del Archivo:', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.nexusTextMuted)),
            const SizedBox(height: 2),
            Text(
              fileName ?? 'Documento_Oficial.pdf',
              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.nexusGreenLight.withOpacity(0.3),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.nexusGreen.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_rounded, color: AppTheme.nexusGreen, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Documento verificado y autenticado por el alumno en NEXUS Talento.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textPrimaryLight, fontWeight: FontWeight.w600),
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
            child: Text('CERRAR', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.nexusTextMuted)),
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
            icon: const Icon(Icons.open_in_new_rounded, size: 16, color: Colors.black),
            label: Text('ABRIR DOCUMENTO PDF', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.black)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.nexusGreenLight,
              foregroundColor: Colors.black,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimaryLight, size: 26),
          tooltip: 'Regresar',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const CompanyDashboardPage()),
              );
            }
          },
        ),
        title: Text('Perfil del Candidato', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight)),
        foregroundColor: AppTheme.textPrimaryLight,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: LiquidGlassAmbientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tarjeta de Cabecera
              GlassmorphicCard(
                glowColor: AppTheme.primaryColor,
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 46,
                      backgroundColor: AppTheme.nexusGreenLight,
                      child: Text(
                        name[0],
                        style: GoogleFonts.outfit(fontSize: 36, color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      name,
                      style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      career,
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.nexusTextMuted),
                      textAlign: TextAlign.center,
                    ),
                    if (s['role'] != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.nexusGreenLight.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          s['role'],
                          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Métricas académicas
              GlassmorphicCard(
                glowColor: AppTheme.primaryGreen,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetricItem('Promedio', gpa, Icons.star_rounded),
                    Container(height: 30, width: 1, color: const Color(0xFFE0E5E2)),
                    _buildMetricItem('Modalidad', modality, Icons.school_rounded),
                    Container(height: 30, width: 1, color: const Color(0xFFE0E5E2)),
                    _buildMetricItem('Inglés', speaksEnglish, Icons.translate_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Botones de Acción
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () {
                    InviteStudentModal.show(context, student: s);
                  },
                  icon: const Icon(Icons.mark_email_read_rounded, color: Colors.black, size: 20),
                  label: Text(
                    'INVITAR A VACANTE DIRECTA 📩',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14.5, letterSpacing: 0.5, color: Colors.black),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.nexusGreenLight,
                    foregroundColor: Colors.black,
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
                      icon: const Icon(Icons.star_rounded, color: Colors.black, size: 18),
                      label: Text(
                        'EVALUAR ⭐',
                        style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.nexusGreen, width: 1.5),
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
                      icon: const Icon(Icons.send_rounded, color: Colors.black, size: 18),
                      label: Text(
                        'CONTACTAR ✉️',
                        style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.nexusGreen, width: 1.5),
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
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight),
              ),
              const SizedBox(height: 12),

              _buildRealTimeDocuments(context, studentId),

              const SizedBox(height: 28),

              // Sección Evaluaciones y Reseñas de Empresas
              Text(
                'Evaluaciones y Reseñas de Empresas ⭐',
                style: GoogleFonts.outfit(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight),
              ),
              const SizedBox(height: 12),

              _buildRealTimeEvaluations(studentId),

              const SizedBox(height: 20),
            ],
          ),
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
              color: const Color(0xFFF6F8F7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E5E2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline_rounded, color: AppTheme.nexusTextMuted, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'El candidato aún no ha adjuntado archivos PDF en su perfil.',
                    style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.nexusTextMuted),
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
    return GlassmorphicCard(
      glowColor: AppTheme.primaryColor,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.nexusGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.nexusGreen, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryLight)),
                Text(fileName, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.nexusGreenSecondary, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openDocumentDialog(context, title, fileName, fileUrl),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.nexusGreenLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.visibility_rounded, size: 14, color: Colors.black),
                  const SizedBox(width: 4),
                  Text('VER PDF', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 11.5, color: Colors.black)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRealTimeEvaluations(String? studentId) {
    if (studentId == null || studentId.isEmpty) {
      return Text('Sin evaluaciones registradas.', style: GoogleFonts.inter(color: AppTheme.nexusTextMuted));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('evaluations')
          .where('studentId', isEqualTo: studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Text('Error cargando reseñas.', style: GoogleFonts.inter(color: AppTheme.nexusTextMuted));
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppTheme.nexusGreen));
        }

        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) {
          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF6F8F7),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE0E5E2)),
            ),
            child: Column(
              children: [
                const Icon(Icons.rate_review_outlined, size: 40, color: AppTheme.nexusTextMuted),
                const SizedBox(height: 8),
                Text(
                  'Aún no cuenta con evaluaciones escritas por empresas',
                  style: GoogleFonts.inter(fontSize: 12.5, color: AppTheme.nexusTextMuted),
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

            return GlassmorphicCard(
              glowColor: AppTheme.primaryGreen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        companyName,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimaryLight),
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight, fontSize: 13.5),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.nexusGreenLight.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      modality,
                      style: GoogleFonts.inter(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '"$comment"',
                    style: GoogleFonts.inter(fontSize: 12.5, height: 1.4, color: AppTheme.nexusTextMuted, fontStyle: FontStyle.italic),
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
        Icon(icon, color: AppTheme.nexusGreen, size: 22),
        const SizedBox(height: 6),
        Text(value, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight)),
        Text(label, style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.nexusTextMuted)),
      ],
    );
  }
}
