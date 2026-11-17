import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/courses/domain/models/course_model.dart';
import 'package:red_teso/features/courses/presentation/pages/course_pdf_brochure_page.dart';
import 'package:red_teso/features/courses/presentation/pages/course_xray_player_page.dart';
import 'package:red_teso/features/courses/presentation/widgets/course_quote_modal.dart';
import 'package:red_teso/features/company/presentation/pages/student_detail_view_page.dart';

/// Vista Detallada Oficial del Curso (Diseño Cisco Academy / Clean UI)
class CourseDetailPage extends StatelessWidget {
  final CourseModel course;

  const CourseDetailPage({
    super.key,
    required this.course,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgWhite, // Fondo blanco principal
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // AppBar flexible (Portada grande limpia)
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            backgroundColor: AppTheme.bgWhite,
            foregroundColor: AppTheme.textPrimaryLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(200),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimaryLight, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildDetailHeaderImage(course.bannerUrl),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppTheme.bgWhite.withAlpha(180),
                          AppTheme.bgWhite,
                        ],
                        stops: const [0.3, 0.8, 1.0],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Contenido Detallado del Curso
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- ENCABEZADO CISCO STYLE ---
                  Row(
                    children: [
                      Text(
                        'RedTESO ',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textSecondaryLight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        'Academy',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: AppTheme.textPrimaryLight,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTurquoise.withAlpha(20),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.primaryTurquoise.withAlpha(50)),
                        ),
                        child: Text(
                          course.category,
                          style: GoogleFonts.plusJakartaSans(
                            color: AppTheme.primaryTurquoise,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Título del Curso
                  Text(
                    course.title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 32,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.textPrimaryLight,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Descripción introductoria
                  Text(
                    course.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      color: AppTheme.textSecondaryLight,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- BLOQUES DE MODALIDAD (Self-Paced / Instructor) ---
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
                            border: Border.all(color: AppTheme.borderLight, width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.menu_book_rounded, color: AppTheme.textPrimaryLight, size: 28),
                              const SizedBox(height: 12),
                              Text('A tu propio ritmo', style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Aprende cuando quieras.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondaryLight, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppTheme.bgWhite,
                            borderRadius: const BorderRadius.horizontal(right: Radius.circular(8)),
                            border: Border.all(color: AppTheme.borderLight, width: 1),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.co_present_rounded, color: AppTheme.textSecondaryLight, size: 28),
                              const SizedBox(height: 12),
                              Text('Con instructor', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondaryLight, fontWeight: FontWeight.bold, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text('Guiado paso a paso.', style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondaryLight, fontSize: 11)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Botón Get Started Principal
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        CourseQuoteModal.show(context, course: course);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentCyan,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Cotizar Acceso Corporativo',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      '1,072,724 ya inscritos en la red',
                      style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),

                  const SizedBox(height: 32),
                  const Divider(color: AppTheme.borderLight),
                  const SizedBox(height: 24),

                  // --- LISTA DE METADATOS TIPO CISCO ---
                  _buildIconListItem(Icons.lock_open_rounded, course.price == 'Gratis' ? 'Free' : course.price),
                  _buildIconListItem(Icons.schedule_rounded, course.duration),
                  _buildIconListItem(Icons.bar_chart_rounded, course.level),
                  _buildIconListItem(Icons.devices_rounded, 'En línea (Self-paced)'),

                  const SizedBox(height: 24),
                  const Divider(color: AppTheme.borderLight),
                  const SizedBox(height: 24),

                  // Logros (Insignias)
                  Text(
                    'Logros y Certificaciones',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Insignias que obtendrás al finalizar.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondaryLight),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildBadgeIcon(Icons.verified_rounded),
                      _buildBadgeIcon(Icons.workspace_premium_rounded),
                      _buildBadgeIcon(Icons.military_tech_rounded),
                      _buildBadgeIcon(Icons.shield_rounded),
                      _buildBadgeIcon(Icons.token_rounded),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Reproductor X-Ray Minimalista
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseXRayPlayerPage(course: course),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryTurquoise,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryTurquoise.withAlpha(100),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Ver Demo Interactiva',
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                                Text(
                                  'Explora el contenido con tecnología X-Ray',
                                  style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondaryLight, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Ficha PDF
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CoursePdfBrochurePage(course: course),
                          ),
                        );
                      },
                      icon: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primaryTurquoise, size: 18),
                      label: Text(
                        'Descargar Broshure (PDF)',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.primaryTurquoise),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderLight),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Módulos Limpios (Temario)
                  Text(
                    'Skills You Will Learn',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildModuleItem('1', 'Fundamentos Teórico-Prácticos & Arquitectura Corporativa'),
                  _buildModuleItem('2', 'Implementación con Casos Reales e Infraestructura Cloud'),
                  _buildModuleItem('3', 'Optimización, Seguridad y Despliegue en Producción'),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconListItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryTurquoise, size: 22),
          const SizedBox(width: 16),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              color: AppTheme.textPrimaryLight,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeIcon(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryTurquoise.withAlpha(20),
        shape: BoxShape.circle,
        border: Border.all(color: AppTheme.primaryTurquoise, width: 1.5),
      ),
      child: Icon(icon, color: AppTheme.primaryTurquoise, size: 28),
    );
  }

  Widget _buildModuleItem(String number, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            number,
            style: GoogleFonts.plusJakartaSans(color: AppTheme.primaryTurquoise, fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: AppTheme.textPrimaryLight),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailHeaderImage(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppTheme.primaryBlue,
          child: const Center(child: Icon(Icons.school_rounded, color: Colors.white, size: 64)),
        ),
      );
    } else if (!kIsWeb && url.isNotEmpty && File(url).existsSync()) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: AppTheme.primaryBlue,
          child: const Center(child: Icon(Icons.school_rounded, color: Colors.white, size: 64)),
        ),
      );
    }
    return Container(
      color: AppTheme.primaryBlue,
      child: const Center(child: Icon(Icons.school_rounded, color: Colors.white, size: 64)),
    );
  }
}
