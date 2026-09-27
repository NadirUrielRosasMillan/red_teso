import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/company/presentation/widgets/contact_student_modal.dart';

class StudentDetailViewPage extends StatelessWidget {
  final Map<String, dynamic> student;

  const StudentDetailViewPage({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final s = student;
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
          children: [
            // Tarjeta de Cabecera
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6)),
                ],
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 46,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
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
                        color: AppTheme.primaryColor.withOpacity(0.1),
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

            const SizedBox(height: 36),

            // Botón Principal para Contactar y Agendar Entrevista
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () {
                  ContactStudentModal.show(context, student: s);
                },
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                label: Text(
                  'CONTACTAR ALUMNO / ENTREVISTA ✉️',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  elevation: 2,
                ),
              ),
            ),
          ],
        ),
      ),
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
