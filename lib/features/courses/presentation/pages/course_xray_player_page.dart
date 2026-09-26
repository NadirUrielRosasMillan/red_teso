import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/courses/domain/models/course_model.dart';
import 'package:red_teso/features/company/presentation/pages/student_detail_view_page.dart';

/// Reproductor de Video Interactivo con interfaz X-Ray estilo Apple TV+
/// Permite pausar el video o tocar "X-Ray" para ver los alumnos que aparecen en escena
class CourseXRayPlayerPage extends StatefulWidget {
  final CourseModel course;

  const CourseXRayPlayerPage({
    super.key,
    required this.course,
  });

  @override
  State<CourseXRayPlayerPage> createState() => _CourseXRayPlayerPageState();
}

class _CourseXRayPlayerPageState extends State<CourseXRayPlayerPage> {
  bool _isPlaying = true;
  bool _showXRay = true;
  double _currentProgress = 0.35; // 35% del video

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Dark Slate / Apple TV+ vibe
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A),
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.course.title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Reproductor Interactivo X-Ray • TESOEM',
              style: GoogleFonts.inter(
                fontSize: 11,
                color: Colors.white60,
              ),
            ),
          ],
        ),
        actions: [
          // Botón directo para activar/desactivar X-Ray Apple TV+ Style
          IconButton(
            icon: Icon(
              _showXRay ? Icons.subtitles_rounded : Icons.subtitles_outlined,
              color: _showXRay ? AppTheme.accentColor : Colors.white,
            ),
            tooltip: 'Modo X-Ray Talento',
            onPressed: () {
              setState(() {
                _showXRay = !_showXRay;
              });
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. ÁREA DE REPRODUCCIÓN DE VIDEO CON MARCO
            Expanded(
              flex: 5,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Imagen de fondo del video / Banner con degradado cinematográfico
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(widget.course.bannerUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                  // Overlay oscuro de reproducción
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.7),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),

                  // Botón central Play/Pause interactivo
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isPlaying = !_isPlaying;
                        if (!_isPlaying) {
                          _showXRay = true; // Auto-activa X-Ray al pausar
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2),
                      ),
                      child: Icon(
                        _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 48,
                      ),
                    ),
                  ),

                  // Badge de Apple TV+ Style X-Ray en la esquina superior izquierda del video
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.65),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accentColor, width: 1),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.blur_on_rounded, color: AppTheme.accentColor, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'X-RAY TALENTO',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Barra de progreso del video
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderThemeData(
                            trackHeight: 3,
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                            activeTrackColor: AppTheme.primaryColor,
                            inactiveTrackColor: Colors.white24,
                            thumbColor: Colors.white,
                          ),
                          child: Slider(
                            value: _currentProgress,
                            onChanged: (val) {
                              setState(() {
                                _currentProgress = val;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 2. PANEL INTERACTIVO APPLE TV+ X-RAY (TALENTO EN ESCENA)
            AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              height: _showXRay ? 280 : 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Encabezado del Panel X-Ray
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppTheme.accentColor.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.people_alt_rounded,
                                  color: AppTheme.accentColor,
                                  size: 18,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'TALENTO EN ESTA ESCENA (${widget.course.featuredStudents.length})',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: Icon(
                              _showXRay ? Icons.keyboard_arrow_down_rounded : Icons.keyboard_arrow_up_rounded,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              setState(() {
                                _showXRay = !_showXRay;
                              });
                            },
                          ),
                        ],
                      ),

                      if (_showXRay) ...[
                        const SizedBox(height: 14),

                        // Lista Horizontal de Tarjetas de Alumnos (X-Ray Cards estilo Apple TV+)
                        SizedBox(
                          height: 170,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: widget.course.featuredStudents.length,
                            itemBuilder: (context, index) {
                              final student = widget.course.featuredStudents[index];

                              return Container(
                                width: 260,
                                margin: const EdgeInsets.only(right: 14),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.18),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 22,
                                          backgroundImage: student.avatarUrl.isNotEmpty
                                              ? NetworkImage(student.avatarUrl)
                                              : null,
                                          child: student.avatarUrl.isEmpty
                                              ? Text(student.name[0])
                                              : null,
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                student.name,
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 14,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              Text(
                                                student.roleInCourse,
                                                style: GoogleFonts.inter(
                                                  color: AppTheme.accentColor,
                                                  fontSize: 11.5,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        '🎓 ${student.career} • GPA: ${student.gpa}',
                                        style: GoogleFonts.inter(
                                          color: Colors.white70,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),

                                    // Botón directo para ir al perfil del alumno
                                    GestureDetector(
                                      onTap: () {
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
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.symmetric(vertical: 8),
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              AppTheme.primaryColor,
                                              Color(0xFF8B1E3F),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Center(
                                          child: Text(
                                            'Ver Perfil Completo 👤',
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
