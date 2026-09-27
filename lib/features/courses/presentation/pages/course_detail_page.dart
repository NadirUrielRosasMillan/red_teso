import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/courses/domain/models/course_model.dart';
import 'package:red_teso/features/courses/presentation/pages/course_pdf_brochure_page.dart';
import 'package:red_teso/features/courses/presentation/pages/course_xray_player_page.dart';
import 'package:red_teso/features/courses/presentation/widgets/course_quote_modal.dart';
import 'package:red_teso/features/company/presentation/pages/student_detail_view_page.dart';

/// Vista Detallada Oficial del Curso (Ficha Técnica & Reseña Completa)
class CourseDetailPage extends StatelessWidget {
  final CourseModel course;

  const CourseDetailPage({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar flexible con la imagen de portada del curso
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.network(
                    course.bannerUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppTheme.primaryColor,
                        child: const Center(
                          child: Icon(Icons.school_rounded, color: Colors.white, size: 64),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.75),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            course.category,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${course.rating} / 5.0 (Excelente)',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido Detallado del Curso
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título del Curso
                  Text(
                    course.title,
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                      height: 1.25,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Tarjeta de Precio, Nivel y Duración
                  Container(
                    padding: const EdgeInsets.all(18),
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
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Inversión Empresarial', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                              const SizedBox(height: 2),
                              Text(
                                course.price,
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(height: 36, width: 1, color: Colors.grey[300]),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(left: 16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Duración y Nivel', style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[600])),
                                const SizedBox(height: 2),
                                Text(
                                  '${course.duration} • ${course.level}',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // BOTÓN DESTACADO PARA VER/DESCARGAR FICHA TÉCNICA PDF
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CoursePdfBrochurePage(course: course),
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 20),
                      label: Text(
                        'VER / DESCARGAR FICHA TÉCNICA PDF 📄',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF334155), // Dark Slate PDF button
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Reseña / Descripción Completa del Curso
                  Text(
                    'Reseña y Objetivo del Curso',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      course.description,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF334155),
                        height: 1.6,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Estructura del Temario Corporativo
                  Text(
                    'Módulos de Capacitación',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildModuleItem('Módulo 1', 'Fundamentos Teórico-Prácticos & Arquitectura Corporativa'),
                  _buildModuleItem('Módulo 2', 'Implementación con Casos Reales e Infraestructura Cloud'),
                  _buildModuleItem('Módulo 3', 'Optimización, Seguridad y Despliegue en Producción'),

                  const SizedBox(height: 24),

                  // Talento en este Curso (Alumnos Colaboradores)
                  if (course.featuredStudents.isNotEmpty) ...[
                    Text(
                      'Talento e Instructores TESOEM (${course.featuredStudents.length})',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),

                    Column(
                      children: course.featuredStudents.map((student) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                                child: Text(
                                  student.name[0],
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      student.name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      '${student.roleInCourse} • GPA: ${student.gpa}',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: AppTheme.primaryColor,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => StudentDetailViewPage(
                                        student: {
                                          'name': student.name,
                                          'modality': 'Residencias',
                                          'gpa': student.gpa,
                                          'gender': 'Femenino',
                                          'speaksEnglish': true,
                                          'career': student.career,
                                          'role': student.roleInCourse,
                                        },
                                      ),
                                    ),
                                  );
                                },
                                child: const Text('Ver Perfil 👤'),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ],

                  const SizedBox(height: 100), // Espacio para el panel flotante inferior
                ],
              ),
            ),
          ),
        ],
      ),

      // Panel Flotante Inferior de Acciones Principales (Ver X-Ray y Cotizar)
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseXRayPlayerPage(course: course),
                    ),
                  );
                },
                icon: const Icon(Icons.play_circle_fill_rounded, color: AppTheme.primaryColor),
                label: Text(
                  'VER X-RAY 🎬',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  CourseQuoteModal.show(context, course: course);
                },
                icon: const Icon(Icons.request_quote_rounded, color: Colors.white),
                label: Text(
                  'COTIZAR 💼',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModuleItem(String tag, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              tag,
              style: GoogleFonts.outfit(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
            ),
          ),
        ],
      ),
    );
  }
}
