import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/courses/domain/models/course_model.dart';
import 'package:red_teso/features/courses/presentation/widgets/course_quote_modal.dart';

/// Visor e Previsualización de Ficha Técnica / Temario PDF del Curso
/// Estilo Liquid Glass (Cristal Líquido Premium & Elegante) diseñado para Empresarios y Ejecutivos
class CoursePdfBrochurePage extends StatefulWidget {
  final CourseModel course;

  const CoursePdfBrochurePage({
    super.key,
    required this.course,
  });

  @override
  State<CoursePdfBrochurePage> createState() => _CoursePdfBrochurePageState();
}

class _CoursePdfBrochurePageState extends State<CoursePdfBrochurePage> with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    // Animación de pulso continuo del resplandor de cristal líquido
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _downloadPdf(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.download_done_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '¡Ficha Técnica de "${widget.course.title}" guardada en descargas!',
                style: GoogleFonts.inter(),
              ),
            ),
          ],
        ),
        backgroundColor: AppTheme.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Slate Noche Ejecutivo
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F172A).withOpacity(0.9),
        elevation: 0,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ficha_Tecnica_TESOEM_${widget.course.id}.pdf',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.5),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Documento Oficial para Recursos Humanos • TESOEM',
              style: GoogleFonts.inter(fontSize: 10.5, color: Colors.white60),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.accentColor),
            tooltip: 'Descargar PDF',
            onPressed: () => _downloadPdf(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Colors.white),
            tooltip: 'Compartir Documento',
            onPressed: () => _downloadPdf(context),
          ),
        ],
      ),
      body: Stack(
        children: [
          // 1. RESPLANDOR LIQUID GLASS AMBIENTAL DE FONDO
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              final glowValue = _glowController.value;
              return Stack(
                children: [
                  Positioned(
                    top: 40 + glowValue * 20,
                    left: -50,
                    child: Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.primaryColor.withOpacity(0.35),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.5),
                            blurRadius: 90,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 100 - glowValue * 20,
                    right: -40,
                    child: Container(
                      width: 280,
                      height: 280,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accentColor.withOpacity(0.25),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.accentColor.withOpacity(0.4),
                            blurRadius: 100,
                            spreadRadius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          // 2. DOCUMENTO EN TARJETA DE CRISTAL LÍQUIDO FROSTED GLASS
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            physics: const BouncingScrollPhysics(),
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 600),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Container(
                      padding: const EdgeInsets.all(24.0),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95), // Cristal blanco esmerilado
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.8),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 30,
                            offset: const Offset(0, 15),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Encabezado Oficial Institucional TESOEM
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'TECNOLÓGICO DE ESTUDIOS SUPERIORES',
                                      style: GoogleFonts.outfit(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    Text(
                                      'DE ORIENTE DEL ESTADO DE MÉXICO',
                                      style: GoogleFonts.outfit(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF475569),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'DIRECCIÓN DE CAPACITACIÓN CORPORATIVA',
                                      style: GoogleFonts.inter(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppTheme.primaryColor,
                                      Color(0xFF4A1022),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.3),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Text(
                                  'HOJA TÉCNICA 2025',
                                  style: GoogleFonts.inter(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 14),
                          const Divider(thickness: 2, color: AppTheme.primaryColor),
                          const SizedBox(height: 14),

                          // Título Oficial del Curso
                          Text(
                            widget.course.title,
                            style: GoogleFonts.outfit(
                              fontSize: 21,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0F172A),
                              height: 1.25,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            'Programa Ejecutivo de Formación Tecnológica Avanzada',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // Cuadro de Resumen Ejecutivo Liquid Glass
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('MODALIDAD', style: GoogleFonts.inter(fontSize: 9.5, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                      Text(widget.course.duration, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                    ],
                                  ),
                                ),
                                Container(height: 28, width: 1, color: Colors.grey[300]),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('NIVEL TÉCNICO', style: GoogleFonts.inter(fontSize: 9.5, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                        Text(widget.course.level, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A))),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(height: 28, width: 1, color: Colors.grey[300]),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('INVERSIÓN', style: GoogleFonts.inter(fontSize: 9.5, color: Colors.grey[600], fontWeight: FontWeight.bold)),
                                        Text(widget.course.price, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Objetivo y Reseña
                          Text(
                            '1. OBJETIVO DEL CURSO Y COMPETENCIAS',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.course.description,
                            style: GoogleFonts.inter(fontSize: 12, color: const Color(0xFF334155), height: 1.5),
                          ),

                          const SizedBox(height: 18),

                          // Desglose del Temario
                          Text(
                            '2. TEMARIO MÓDULO POR MÓDULO',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          _buildPdfModuleRow('Módulo I', 'Fundamentos Teóricos & Arquitectura Empresarial', '12 Horas'),
                          _buildPdfModuleRow('Módulo II', 'Casos Prácticos de Negocio & Infraestructura Cloud', '18 Horas'),
                          _buildPdfModuleRow('Módulo III', 'Seguridad, Optimización y Despliegue en Producción', '10 Horas'),

                          const SizedBox(height: 18),

                          // Instructores y Colaboradores TESOEM
                          Text(
                            '3. ACADÉMICOS E INSTRUCTORES COLABORADORES',
                            style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                          ),
                          const SizedBox(height: 8),
                          if (widget.course.featuredStudents.isNotEmpty)
                            Column(
                              children: widget.course.featuredStudents.map((s) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppTheme.primaryColor),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          '${s.name} • ${s.roleInCourse}',
                                          style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF334155)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            )
                          else
                            Text(
                              'Cuerpo docente especializado de la División de Ingeniería en Sistemas Computacionales TESOEM.',
                              style: GoogleFonts.inter(fontSize: 11.5, color: const Color(0xFF334155)),
                            ),

                          const SizedBox(height: 24),
                          const Divider(),
                          const SizedBox(height: 10),

                          // Sello y Validez Oficial
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Acreditación y Certificación:', style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.grey[700])),
                                    Text('Reconocimiento Oficial TESOEM • Normatividad STPS', style: GoogleFonts.inter(fontSize: 9, color: Colors.grey[600])),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Text('SELLO TESOEM 🎓', style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Dock Inferior de Acciones Liquid Glass (Frosted Blur)
      bottomNavigationBar: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A).withOpacity(0.85),
              border: Border(
                top: BorderSide(color: Colors.white.withOpacity(0.15), width: 1),
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _downloadPdf(context),
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('DESCARGAR PDF 📥', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        CourseQuoteModal.show(context, course: widget.course);
                      },
                      icon: const Icon(Icons.request_quote_rounded, color: Colors.white, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('COTIZAR 💼', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accentColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        elevation: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPdfModuleRow(String tag, String title, String hours) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(tag, style: GoogleFonts.outfit(fontSize: 9.5, fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)))),
          const SizedBox(width: 4),
          Text(hours, style: GoogleFonts.inter(fontSize: 10.5, color: Colors.grey[600], fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
