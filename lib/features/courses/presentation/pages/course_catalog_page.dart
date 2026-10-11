import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/core/widgets/liquid_glass_ambient_background.dart';
import 'package:red_teso/features/courses/data/mock_courses_data.dart';
import 'package:red_teso/features/courses/domain/models/course_model.dart';
import 'package:red_teso/features/courses/presentation/pages/course_clips_feed_page.dart';
import 'package:red_teso/features/courses/presentation/pages/course_detail_page.dart';
import 'package:red_teso/features/courses/presentation/pages/course_xray_player_page.dart';
import 'package:red_teso/features/courses/presentation/widgets/ai_course_assistant_modal.dart';
import 'package:red_teso/features/courses/presentation/widgets/course_quote_modal.dart';
import 'package:red_teso/features/company/presentation/pages/student_detail_view_page.dart';

/// Catálogo Oficial de Cursos Universitarios TESOEM para Empresas
class CourseCatalogPage extends StatefulWidget {
  const CourseCatalogPage({super.key});

  @override
  State<CourseCatalogPage> createState() => _CourseCatalogPageState();
}

class _CourseCatalogPageState extends State<CourseCatalogPage> {
  final List<CourseModel> _courses = [];
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

  void _clearFilters() {
    setState(() {
      _selectedCategory = 'Todos';
      _selectedLevel = 'Todos';
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('courses').snapshots(),
      builder: (context, snapshot) {
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

        final filteredCourses = allCourses.where((course) {
          final matchesCategory = _selectedCategory == 'Todos' ||
              course.category.toLowerCase().contains(_selectedCategory.toLowerCase());

          final matchesLevel = _selectedLevel == 'Todos' ||
              course.level.toLowerCase().contains(_selectedLevel.toLowerCase());

          return matchesCategory && matchesLevel;
        }).toList();

        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: const Color(0xFF090D16).withOpacity(0.85),
            foregroundColor: Colors.white,
            elevation: 0,
            title: Text(
              'Cursos TESOEM para Empresas',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.white,
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Center(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
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

          floatingActionButton: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
            child: _isScrolled
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 100),
                    child: FloatingActionButton(
                      key: const ValueKey('floating_ai_btn'),
                      onPressed: () => AiCourseAssistantModal.show(context, courses: allCourses),
                      backgroundColor: const Color(0xFF0F172A),
                      elevation: 6,
                      tooltip: 'IA REDTESO 🤖',
                      child: const Icon(Icons.psychology_rounded, color: AppTheme.accentColor, size: 24),
                    ),
                  )
                : const SizedBox.shrink(key: ValueKey('empty_ai_btn')),
          ),

          body: LiquidGlassAmbientBackground(
            child: CustomScrollView(
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

              if (filteredCourses.isEmpty)
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
        ),
        );
      },
    );
  }

  Widget _buildCompactCourseCard(CourseModel course) {
    return GlassmorphicCard(
      glowColor: AppTheme.primaryColor,
      padding: EdgeInsets.zero,
      margin: EdgeInsets.zero,
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
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: _buildCourseBannerImage(course.bannerUrl, height: 150),
              ),
              Positioned(
                top: 10,
                left: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    course.level,
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                      const SizedBox(width: 3),
                      Text(
                        '${course.rating}',
                        style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
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
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
                    ),
                  ),
                ),
              ),
            ],
          ),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white, height: 1.25),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${course.category} • ${course.duration}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11.5, color: Colors.white70),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    course.price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentColor),
                  ),
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => CourseDetailPage(course: course)),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white38),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text('Ficha 📄', style: GoogleFonts.inter(color: Colors.white, fontSize: 11)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            CourseQuoteModal.show(context, course: course);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                          child: Text('Cotizar 💼', style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
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
          colors: [AppTheme.primaryColor, Color(0xFF4A1022)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.school_rounded, color: Colors.white, size: 48),
      ),
    );
  }
}
