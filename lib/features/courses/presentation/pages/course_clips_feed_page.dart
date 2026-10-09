import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/courses/domain/models/course_model.dart';
import 'package:red_teso/features/courses/presentation/pages/course_detail_page.dart';
import 'package:red_teso/features/courses/presentation/pages/course_xray_player_page.dart';
import 'package:red_teso/features/company/presentation/pages/student_detail_view_page.dart';

/// Feed de Cortos / Clips verticales estilo TikTok / Netflix Fast Laughs
/// Permite a las empresas deslizar de forma rápida e interactiva por demostraciones
/// de los cursos de la universidad y proyectos creados por los alumnos.
class CourseClipsFeedPage extends StatefulWidget {
  final List<CourseModel> courses;

  const CourseClipsFeedPage({
    super.key,
    required this.courses,
  });

  @override
  State<CourseClipsFeedPage> createState() => _CourseClipsFeedPageState();
}

class _CourseClipsFeedPageState extends State<CourseClipsFeedPage> {
  late List<_ClipItemData> _allClips;
  int _currentClipIndex = 0;

  @override
  void initState() {
    super.initState();
    _allClips = [];
    for (var course in widget.courses) {
      if (course.clips.isNotEmpty) {
        for (var clip in course.clips) {
          _allClips.add(_ClipItemData(clip: clip, course: course));
        }
      } else {
        // Si el curso no tiene clip explícito, crea un clip automático con su video
        _allClips.add(
          _ClipItemData(
            clip: CourseClip(
              id: 'clip_${course.id}',
              title: course.title,
              subtitle: course.description,
              videoUrl: course.bannerUrl,
              thumbnailUrl: course.bannerUrl,
              courseId: course.id,
              courseTitle: course.title,
            ),
            course: course,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_allClips.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
        body: Center(
          child: Text('No hay clips disponibles actualmente', style: GoogleFonts.inter(color: Colors.white)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: PageView.builder(
        scrollDirection: Axis.vertical,
        itemCount: _allClips.length,
        onPageChanged: (index) {
          setState(() {
            _currentClipIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final item = _allClips[index];
          return _SingleClipVideoWidget(
            key: ValueKey(item.clip.id),
            item: item,
            isCurrentPage: index == _currentClipIndex,
          );
        },
      ),
    );
  }
}

class _SingleClipVideoWidget extends StatefulWidget {
  final _ClipItemData item;
  final bool isCurrentPage;

  const _SingleClipVideoWidget({
    super.key,
    required this.item,
    required this.isCurrentPage,
  });

  @override
  State<_SingleClipVideoWidget> createState() => _SingleClipVideoWidgetState();
}

class _SingleClipVideoWidgetState extends State<_SingleClipVideoWidget> {
  VideoPlayerController? _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    final url = widget.item.clip.videoUrl;

    try {
      if (url.startsWith('http://') || url.startsWith('https://')) {
        _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
      } else if (url.isNotEmpty && File(url).existsSync()) {
        _videoController = VideoPlayerController.file(File(url));
      } else {
        _videoController = VideoPlayerController.networkUrl(
          Uri.parse('https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4'),
        );
      }

      await _videoController!.initialize();
      _videoController!.setLooping(true);
      if (widget.isCurrentPage) {
        await _videoController!.play();
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Error inicializando video en clip: $e');
    }
  }

  @override
  void didUpdateWidget(covariant _SingleClipVideoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isCurrentPage != oldWidget.isCurrentPage && _videoController != null && _isInitialized) {
      if (widget.isCurrentPage) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final clip = widget.item.clip;
    final course = widget.item.course;

    return Stack(
      children: [
        // 1. REPRODUCCIÓN DE VIDEO REAL EN PANTALLA COMPLETA VERTICAL
        Positioned.fill(
          child: _isInitialized && _videoController != null
              ? FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _videoController!.value.size.width,
                    height: _videoController!.value.size.height,
                    child: VideoPlayer(_videoController!),
                  ),
                )
              : _buildFallbackThumbnail(clip.thumbnailUrl),
        ),

        // 2. DEGRADADO OSCURO INFERIOR Y SUPERIOR TIPO TIKTOK
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.black.withOpacity(0.5),
                  Colors.transparent,
                  Colors.black.withOpacity(0.85),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 0.95],
              ),
            ),
          ),
        ),

        // 3. BADGE DEL CURSO TESOEM Y CONTROLES SUPERIORES
        Positioned(
          top: 50,
          left: 16,
          right: 16,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.school_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'CURSO TESOEM • ${course.category}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.swipe_vertical_rounded, color: Colors.white, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Desliza',
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // 4. BARRA DE ACCIONES LATERALES (LIKES, X-RAY, COMPARTIR)
        Positioned(
          right: 16,
          bottom: 110,
          child: Column(
            children: [
              _buildActionButton(
                icon: Icons.favorite_rounded,
                color: Colors.redAccent,
                label: clip.likes.toString(),
                onTap: () {},
              ),
              const SizedBox(height: 20),

              // Botón X-Ray Talento
              _buildActionButton(
                icon: Icons.blur_on_rounded,
                color: AppTheme.accentColor,
                label: 'X-Ray',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseXRayPlayerPage(course: course),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),

              // Botón Compartir
              _buildActionButton(
                icon: Icons.share_rounded,
                color: Colors.white,
                label: 'Enviar',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Enlace de curso copiado')),
                  );
                },
              ),
            ],
          ),
        ),

        // 5. INFORMACIÓN DEL CLIP, TÍTULO Y REDIRECCIÓN A DETALLES DEL CURSO
        Positioned(
          left: 16,
          right: 80,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (course.featuredStudents.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    final student = course.featuredStudents.first;
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
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircleAvatar(
                          radius: 10,
                          backgroundColor: AppTheme.accentColor,
                          child: Icon(Icons.person, size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Talento: ${course.featuredStudents.first.name}',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 10),
                      ],
                    ),
                  ),
                ),

              // Título del Corto
              Text(
                clip.title,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 6),

              // Subtítulo / Descripción
              Text(
                clip.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.3,
                ),
              ),

              const SizedBox(height: 16),

              // REDIRECCIÓN A INFORMACIÓN Y DETALLES DEL CURSO (Ficha Técnica + Cotización)
              GestureDetector(
                onTap: () {
                  _videoController?.pause();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CourseDetailPage(course: course),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppTheme.primaryColor,
                        Color(0xFF8B1E3F),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'VER INFORMACIÓN DEL CURSO 🎓',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackThumbnail(String url) {
    if (url.startsWith('http://') || url.startsWith('https://')) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
      );
    } else if (url.isNotEmpty && File(url).existsSync()) {
      return Image.file(
        File(url),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[900]),
      );
    }
    return Container(color: Colors.grey[900]);
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClipItemData {
  final CourseClip clip;
  final CourseModel course;

  _ClipItemData({required this.clip, required this.course});
}
