import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/courses/data/mock_courses_data.dart';
import 'package:red_teso/features/courses/domain/models/course_model.dart';
import 'package:red_teso/features/courses/presentation/pages/course_clips_feed_page.dart';
import 'package:red_teso/features/courses/presentation/pages/course_detail_page.dart';
import 'package:red_teso/features/courses/presentation/pages/course_xray_player_page.dart';
import 'package:red_teso/features/courses/presentation/widgets/ai_course_assistant_modal.dart';
import 'package:red_teso/features/courses/presentation/widgets/course_quote_modal.dart';
import 'package:red_teso/features/company/presentation/pages/student_detail_view_page.dart';

/// Catálogo Oficial de Cursos Universitaros TESOEM para Empresas
/// Incluye Buscador Semántico por IA, Filtros por Nivel, solicitudes de cotización y acceso al Feed de Cortos (TikTok style)
class CourseCatalogPage extends StatefulWidget {
  const CourseCatalogPage({super.key});

  @override
  State<CourseCatalogPage> createState() => _CourseCatalogPageState();
}

class _CourseCatalogPageState extends State<CourseCatalogPage> {
  final List<CourseModel> _courses = MockCoursesData.sampleCourses;
  final ScrollController _scrollController = ScrollController();

  String _selectedCategory = 'Todos';
  String _selectedLevel = 'Todos';
  bool _isScrolled = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.offset > 70 && !_isScrolled) {
        setState(() => _isScrolled = true);
      } else if (_scrollController.offset <= 70 && _isScrolled) {
        setState(() => _isScrolled = false);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Búsqueda y filtrado inteligente combinado por categoría y nivel
  List<CourseModel> get _filteredCourses {
    return _courses.where((course) {
      final matchesCategory = _selectedCategory == 'Todos' ||
          course.category.toLowerCase().contains(_selectedCategory.toLowerCase());

      final matchesLevel = _selectedLevel == 'Todos' ||
          course.level.toLowerCase().contains(_selectedLevel.toLowerCase());

      return matchesCategory && matchesLevel;
    }).toList();
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'Todos';
      _selectedLevel = 'Todos';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        title: Text(
          'Cursos TESOEM para Empresas',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: const Color(0xFF0F172A),
          ),
        ),
        actions: [
          // Botón destacado para abrir el Feed de Cortos / Clips
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Center(
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseClipsFeedPage(courses: _courses),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.movie_filter_rounded, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        'CLIPS 🎬',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),

      // Botón de Acción Flotante Inteligente cuando hace scroll
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: _isScrolled
            ? Padding(
                padding: const EdgeInsets.only(bottom: 100), // Para quedar por encima del dock flotante Liquid Glass
                child: FloatingActionButton(
                  key: const ValueKey('floating_ai_btn'),
                  onPressed: () => AiCourseAssistantModal.show(context, courses: _courses),
                  backgroundColor: const Color(0xFF0F172A),
      elevation: 6,
                  tooltip: 'IA REDTESO 🤖',
                  child: const Icon(Icons.psychology_rounded, color: AppTheme.accentColor, size: 24),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty_ai_btn')),
      ),

      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),

                // 1. TARJETA ENCABEZADO DE BÚSQUEDA SEMÁNTICA CON IA REDTESO 🤖✨
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _isScrolled ? 0.3 : 1.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        AiCourseAssistantModal.show(context, courses: _courses);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF0F172A),
                              Color(0xFF1E293B),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.accentColor.withOpacity(0.5), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.accentColor.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor]),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Asistente IA para Cursos 🤖✨',
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Escribe en lenguaje cotidiano: "Quiero un curso de AWS o Ciberseguridad"',
                                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.accentColor, size: 14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // 2. FILTROS POR CATEGORÍA
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: ['Todos', 'Sistemas', 'IA', 'Seguridad', 'Móvil', 'Gestión'].map((category) {
                      final isSelected = _selectedCategory == category;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          selectedColor: AppTheme.primaryColor,
                          labelStyle: GoogleFonts.inter(
                            color: isSelected ? Colors.white : const Color(0xFF475569),
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 12.5,
                          ),
                          onSelected: (val) {
                            setState(() {
                              _selectedCategory = category;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),

                const SizedBox(height: 8),

                // 3. FILTROS POR NIVEL DE DIFICULTAD (Básico, Intermedio, Avanzado)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('Nivel: ', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                      ...['Todos', 'Básico', 'Intermedio', 'Avanzado'].map((level) {
                        final isSelected = _selectedLevel == level;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: FilterChip(
                            label: Text(level),
                            selected: isSelected,
                            selectedColor: AppTheme.accentColor,
                            checkmarkColor: Colors.white,
                            labelStyle: GoogleFonts.inter(
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            onSelected: (val) {
                              setState(() {
                                _selectedLevel = level;
                              });
                            },
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
              ],
            ),
          ),

          // 4. LISTADO SLIVER DE CURSOS O ESTADO VACÍO (EMPTY STATE)
          if (_filteredCourses.isEmpty)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.manage_search_rounded, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      'No se encontraron cursos',
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No hay cursos que coincidan con los filtros seleccionados.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Limpiar Filtros'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final course = _filteredCourses[index];
                    return _buildCourseCard(course);
                  },
                  childCount: _filteredCourses.length,
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100), // Espacio para el dock flotante Liquid Glass
          ),
        ],
      ),
    );
  }

  /// Construye la tarjeta individual de cada curso
  Widget _buildCourseCard(CourseModel course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CourseDetailPage(course: course),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner del Curso con Insignia de Nivel
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: Image.network(
                      course.bannerUrl,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 160,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryColor, Color(0xFF4A1022)],
                            ),
                          ),
                          child: const Center(
                            child: Icon(Icons.school_rounded, color: Colors.white, size: 48),
                          ),
                        );
                      },
                    ),
                  ),

                  // Insignia de Nivel (Básico, Intermedio, Avanzado)
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        course.level,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  // Insignia de Calificación
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '${course.rating}',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Detalles del Curso
              Padding(
                padding: const EdgeInsets.all(18.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: const Color(0xFF64748B),
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Alumnos Participantes (X-Ray Preview Chips)
                    if (course.featuredStudents.isNotEmpty) ...[
                      Text(
                        'Talento en este curso:',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: course.featuredStudents.map((s) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => StudentDetailViewPage(
                                    student: {
                                      'name': s.name,
                                      'modality': 'Residencias',
                                      'gpa': s.gpa,
                                      'gender': 'Femenino',
                                      'speaksEnglish': true,
                                      'career': s.career,
                                      'role': s.roleInCourse,
                                    },
                                  ),
                                ),
                              );
                            },
                            child: Chip(
                              avatar: CircleAvatar(
                                backgroundColor: AppTheme.primaryColor.withOpacity(0.15),
                                child: Text(
                                  s.name.isNotEmpty ? s.name[0] : 'A',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ),
                              label: Text('${s.name} (${s.gpa})'),
                              labelStyle: GoogleFonts.inter(fontSize: 11.5),
                              backgroundColor: const Color(0xFFF1F5F9),
                            ),
                          );
                        }).toList(),
                      ),
                    ],

                    const Divider(height: 24),

                    // Precio y Botón para Abrir Reproductor X-Ray
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              course.price,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                            Text(
                              course.duration,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),

                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CourseXRayPlayerPage(course: course),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_circle_fill_rounded, size: 18, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  'VER X-RAY 🎬',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Botón Destacado de Solicitar Cotización Corporativa
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          CourseQuoteModal.show(context, course: course);
                        },
                        icon: const Icon(Icons.request_quote_rounded, color: AppTheme.primaryColor, size: 18),
                        label: Text(
                          'SOLICITAR COTIZACIÓN CORPORATIVA 💼',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                            color: AppTheme.primaryColor,
                            letterSpacing: 0.5,
                          ),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}
