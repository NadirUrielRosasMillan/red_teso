import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/core/widgets/liquid_glass_ambient_background.dart';
import 'package:red_teso/features/courses/data/mock_courses_data.dart';
import 'package:red_teso/features/courses/domain/models/course_model.dart';
import 'package:red_teso/features/courses/presentation/pages/course_clips_feed_page.dart';
import 'package:red_teso/features/courses/presentation/pages/course_detail_page.dart';
import 'package:red_teso/features/courses/presentation/pages/course_xray_player_page.dart';
import 'package:red_teso/features/courses/presentation/widgets/ai_course_assistant_modal.dart';
import 'package:red_teso/features/courses/presentation/widgets/course_quote_modal.dart';

/// Catálogo Oficial de Cursos Universitarios TESOEM para Empresas
class CourseCatalogPage extends StatefulWidget {
  const CourseCatalogPage({super.key});

  @override
  State<CourseCatalogPage> createState() => _CourseCatalogPageState();
}

class _CourseCatalogPageState extends State<CourseCatalogPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
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
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      _searchController.clear();
      _selectedCategory = 'Todos';
      _selectedLevel = 'Todos';
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('courses').snapshots(),
      builder: (context, snapshot) {
        // ====== DIAGNÓSTICO ======
        debugPrint('=== CURSOS STREAM ===');
        debugPrint('Estado: ${snapshot.connectionState}');
        debugPrint('hasData: ${snapshot.hasData}');
        debugPrint('hasError: ${snapshot.hasError}');
        debugPrint('Error: ${snapshot.error}');
        debugPrint('Docs recibidos: ${snapshot.data?.docs.length ?? 0}');
        debugPrint('=======================');
        // =========================

        List<CourseModel> allCourses = [];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          allCourses = snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final video = (data['videoUrl'] != null && data['videoUrl'].toString().isNotEmpty)
                ? data['videoUrl'].toString()
                : 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4';
            final banner = (data['bannerUrl'] != null && data['bannerUrl'].toString().isNotEmpty)
                ? data['bannerUrl'].toString()
                : 'https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800';

            return CourseModel(
              id: doc.id,
              title: data['title'] ?? 'Curso TESOEM',
              category: data['category'] ?? 'Sistemas',
              description: data['description'] ?? 'Programa oficial de capacitación universitaria.',
              price: data['price'] ?? 'Por cotizar',
              duration: data['duration'] ?? '40 Horas',
              level: data['level'] ?? 'Avanzado',
              bannerUrl: banner,
              rating: 5.0,
              featuredStudents: [],
              clips: [
                CourseClip(
                  id: 'clip_${doc.id}',
                  title: 'Demo de ${data['title'] ?? 'Curso'}',
                  subtitle: data['description'] ?? 'Muestra ejecutiva del programa académico.',
                  videoUrl: video,
                  thumbnailUrl: banner,
                  courseId: doc.id,
                  courseTitle: data['title'] ?? 'Curso TESOEM',
                ),
              ],
            );
          }).toList();
        }

        // Si Firestore viene vacío o no tiene cursos, usar MockCoursesData como respaldo
        if (allCourses.isEmpty) {
          allCourses = List.from(MockCoursesData.sampleCourses);
        }

        debugPrint('>>> allCourses.length: ${allCourses.length}');

        final filteredCourses = allCourses.where((course) {
          final matchesSearch = _searchQuery.isEmpty ||
              course.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              course.description.toLowerCase().contains(_searchQuery.toLowerCase());

          final matchesCategory = _selectedCategory == 'Todos' ||
              course.category.toLowerCase().contains(_selectedCategory.toLowerCase());

          final matchesLevel = _selectedLevel == 'Todos' ||
              course.level.toLowerCase().contains(_selectedLevel.toLowerCase());

          return matchesSearch && matchesCategory && matchesLevel;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            foregroundColor: AppTheme.textPrimaryLight,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Cursos TESOEM para Empresas',
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CourseClipsFeedPage(courses: allCourses),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.movie_filter_rounded, size: 16, color: AppTheme.primaryTurquoise),
                          const SizedBox(width: 6),
                          Text(
                            'CLIPS 🎬',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryTurquoise,
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

          floatingActionButton: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: _isScrolled
                ? Padding(
              padding: const EdgeInsets.only(bottom: 100),
              child: FloatingActionButton(
                key: const ValueKey('floating_ai_btn'),
                onPressed: () => AiCourseAssistantModal.show(context, courses: allCourses),
                backgroundColor: AppTheme.surfaceLight,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppTheme.borderLight),
                ),
                tooltip: 'IA REDTESO 🤖',
                child: const Icon(Icons.psychology_rounded, color: AppTheme.primaryTurquoise, size: 24),
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

                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 250),
                      opacity: _isScrolled ? 0.3 : 1.0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                        child: GestureDetector(
                          onTap: () {
                            AiCourseAssistantModal.show(context, courses: allCourses);
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.borderLight, width: 1),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryTurquoise.withAlpha(20),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.psychology_rounded, color: AppTheme.primaryTurquoise, size: 22),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Asistente IA para Cursos',
                                        style: GoogleFonts.spaceGrotesk(color: AppTheme.textPrimaryLight, fontSize: 14, fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        'Busca de forma natural: "curso de AWS o Ciberseguridad"',
                                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondaryLight, fontSize: 11.5),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.textSecondaryLight, size: 14),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // --- SEARCH BAR (Laravel Style) ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimaryLight, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Buscar por título o descripción...',
                          hintStyle: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondaryLight, fontSize: 14),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondaryLight, size: 20),
                          filled: true,
                          fillColor: AppTheme.surfaceLight,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.borderLight),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.borderLight),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: const BorderSide(color: AppTheme.primaryTurquoise),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

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
                              backgroundColor: AppTheme.bgWhite,
                              selectedColor: AppTheme.primaryTurquoise,
                              side: BorderSide(color: isSelected ? AppTheme.primaryTurquoise : AppTheme.borderLight),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              labelStyle: GoogleFonts.plusJakartaSans(
                                color: isSelected ? Colors.white : AppTheme.textPrimaryLight,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                fontSize: 12.5,
                              ),
                              showCheckmark: false,
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

                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Text('Nivel: ', style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryLight)),
                            ...['Todos', 'Básico', 'Intermedio', 'Avanzado'].map((level) {
                              final isSelected = _selectedLevel == level;
                              return Padding(
                                padding: const EdgeInsets.only(right: 6.0),
                                child: FilterChip(
                                  label: Text(level),
                                  selected: isSelected,
                                  backgroundColor: AppTheme.bgWhite,
                                  selectedColor: AppTheme.primaryTurquoise,
                                  checkmarkColor: Colors.white,
                                  side: BorderSide(color: isSelected ? AppTheme.primaryTurquoise : AppTheme.borderLight),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  labelStyle: GoogleFonts.plusJakartaSans(
                                    color: isSelected ? Colors.white : AppTheme.textPrimaryLight,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

                if (filteredCourses.isEmpty)
                  SliverToBoxAdapter(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.manage_search_rounded, size: 64, color: AppTheme.textSecondaryLight),
                          const SizedBox(height: 16),
                          Text(
                            'No se encontraron cursos',
                            style: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryLight),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No hay cursos que coincidan con tu búsqueda y filtros.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppTheme.textSecondaryLight),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                            label: Text('Limpiar Búsqueda', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryTurquoise,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (MediaQuery.of(context).size.width > 700)
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 380,
                        mainAxisSpacing: 20,
                        crossAxisSpacing: 20,
                        mainAxisExtent: 420,
                      ),
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final course = filteredCourses[index];
                          return _buildCompactCourseCard(course)
                              .animate(delay: (index * 60).ms)
                              .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                              .slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
                        },
                        childCount: filteredCourses.length,
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                            (context, index) {
                          final course = filteredCourses[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: _buildCompactCourseCard(course)
                                .animate(delay: (index * 80).ms)
                                .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                                .slideY(begin: 0.15, end: 0, curve: Curves.easeOut),
                          );
                        },
                        childCount: filteredCourses.length,
                      ),
                    ),
                  ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactCourseCard(CourseModel course) {
    return SizedBox(
      height: 420,
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CourseDetailPage(course: course),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.bgWhite,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderLight, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- PORTADA (IMAGEN) ---
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                    child: _buildCourseBannerImage(course.bannerUrl, height: 160),
                  ),
                  // Nivel del curso
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.bgWhite.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppTheme.borderLight),
                      ),
                      child: Text(
                        course.level.toUpperCase(),
                        style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimaryLight, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  // Botón de Play Centro
                  Positioned.fill(
                    child: Center(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CourseXRayPlayerPage(course: course),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.bgWhite.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: AppTheme.primaryTurquoise, width: 1.5),
                          ),
                          child: const Icon(Icons.play_arrow_rounded, color: AppTheme.primaryTurquoise, size: 28),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // --- CONTENIDO DE LA TARJETA ---
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Categoría y flecha superior
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceLight,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: Text(
                              course.category,
                              style: GoogleFonts.plusJakartaSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.primaryTurquoise),
                            ),
                          ),
                          const Icon(Icons.arrow_outward_rounded, color: AppTheme.textSecondaryLight, size: 16),
                        ],
                      ),
                      const SizedBox(height: 10),

                      // Título
                      Text(
                        course.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimaryLight, height: 1.2),
                      ),
                      const SizedBox(height: 6),

                      // Resumen / Descripción corta
                      Text(
                        course.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppTheme.textSecondaryLight, height: 1.4),
                      ),
                      
                      const Spacer(),

                      // Valoración y Precio
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${course.rating}',
                                style: GoogleFonts.plusJakartaSans(color: AppTheme.textPrimaryLight, fontSize: 13, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                ' (24)', // Simulación de reseñas
                                style: GoogleFonts.plusJakartaSans(color: AppTheme.textSecondaryLight, fontSize: 12),
                              ),
                            ],
                          ),
                          Text(
                            course.price,
                            style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryTurquoise),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),
                      const Divider(color: AppTheme.borderLight, height: 1),
                      const SizedBox(height: 12),

                      // Footer: Metadata y Botón de Acción
                      Row(
                        children: [
                          // Meta: Duración
                          const Icon(Icons.schedule_rounded, size: 14, color: AppTheme.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            course.duration.split(' ').first + 'h',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondaryLight),
                          ),
                          const SizedBox(width: 12),
                          // Meta: Inscritos
                          const Icon(Icons.people_outline_rounded, size: 14, color: AppTheme.textSecondaryLight),
                          const SizedBox(width: 4),
                          Text(
                            '120+',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppTheme.textSecondaryLight),
                          ),
                          const Spacer(),
                          // Botón Cotizar Limpio
                          InkWell(
                            onTap: () {
                              CourseQuoteModal.show(context, course: course);
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryTurquoise,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Cotizar',
                                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseBannerImage(String bannerUrl, {double height = 160}) {
    if (bannerUrl.startsWith('http://') || bannerUrl.startsWith('https://')) {
      return Image.network(
        bannerUrl,
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderBanner(height: height),
      );
    } else if (!kIsWeb && bannerUrl.isNotEmpty && File(bannerUrl).existsSync()) {
      return Image.file(
        File(bannerUrl),
        height: height,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildPlaceholderBanner(height: height),
      );
    }
    return _buildPlaceholderBanner(height: height);
  }

  Widget _buildPlaceholderBanner({double height = 160}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryTurquoise, AppTheme.darkTurquoise],
        ),
      ),
      child: const Center(
        child: Icon(Icons.school_rounded, color: Colors.white, size: 48),
      ),
    );
  }
}