import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/services/gemini_ai_service.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/courses/domain/models/course_model.dart';
import 'package:red_teso/features/courses/presentation/pages/course_detail_page.dart';
import 'package:red_teso/features/courses/presentation/widgets/course_quote_modal.dart';

/// Asistente Virtual Inteligente con Búsqueda Semántica para Cursos Corporativos
class AiCourseAssistantModal extends StatefulWidget {
  final List<CourseModel> courses;

  const AiCourseAssistantModal({
    super.key,
    required this.courses,
  });

  static Future<void> show(BuildContext context, {required List<CourseModel> courses}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiCourseAssistantModal(courses: courses),
    );
  }

  @override
  State<AiCourseAssistantModal> createState() => _AiCourseAssistantModalState();
}

class _AiCourseAssistantModalState extends State<AiCourseAssistantModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  late AnimationController _glowController;

  bool _isAnalyzing = false;
  String _aiResponseText = '';
  List<CourseModel> _matchedResults = [];

  final List<String> _presetPrompts = [
    '☁️ Quiero un curso avanzado de Cloud & DevOps con AWS',
    '🤖 Busco capacitación en Inteligencia Artificial y Python',
    '🔒 Necesito un curso de Ciberseguridad y Hacking Ético',
    '📱 Capacitación en aplicaciones móviles con Flutter',
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _processAiQuery(String queryText) async {
    if (queryText.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _queryController.text = queryText;
    });

    final trimmedQuery = queryText.trim().toLowerCase();

    // Detección mejorada de saludos y platica casual (ej: "oye", "hola", "buenas")
    final isGreeting = RegExp(r'^(hola|holaa|oye|oyee|buenas|buenos dias|buenas tardes|buenas noches|hey|que tal|saludos|como estas)\b').hasMatch(trimmedQuery);
    final isWhoAreYou = RegExp(r'(quien eres|que haces|que puedes hacer|como me ayudas|ayuda|funciones)\b').hasMatch(trimmedQuery);
    final isThanks = RegExp(r'^(gracias|muchas gracias|thx|thank you|ok gracias)\b').hasMatch(trimmedQuery);

    if (isGreeting || isWhoAreYou || isThanks) {
      await Future.delayed(const Duration(milliseconds: 400));
      String response = '';
      if (isGreeting) {
        response = '¡Hola! 👋 Soy tu Asesor Virtual de Cursos TESOEM.\n\nPuedo orientarte sobre las mejores capacitaciones ejecutivas para tu empresa. ¿En qué área o tecnología necesitas información hoy?';
      } else if (isWhoAreYou) {
        response = '🤖 ¡Hola! Soy el Asistente IA de Cursos TESOEM.\n\nPuedo analizar la oferta de capacitaciones corporativas y recomendarte diplomados o certificaciones en Cloud, IA, Ciberseguridad o Desarrollo Móvil.\n\n¡Prueba preguntando "Quiero un curso de Ciberseguridad"!';
      } else {
        response = '¡Un placer atenderte! 😊 Si deseas cotizar o consultar información de algún curso, estoy a tus órdenes.';
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _aiResponseText = response;
          _matchedResults = []; // NO MUESTRA CURSOS SIN SER SOLICITADOS
        });
      }
      return;
    }

    // 1. CONSULTA REAL CON GEMINI 1.5 FLASH AI
    if (GeminiAiService.hasApiKey) {
      final coursesMap = widget.courses.map((c) => {
        'id': c.id,
        'title': c.title,
        'category': c.category,
        'description': c.description,
        'price': c.price,
        'duration': c.duration,
        'level': c.level,
      }).toList();

      final geminiRes = await GeminiAiService.queryCourses(
        userPrompt: queryText,
        courses: coursesMap,
      );

      if (geminiRes.isGenerative) {
        final matchedFromGemini = widget.courses
            .where((c) => geminiRes.recommendedIds.contains(c.id))
            .toList();

        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _aiResponseText = geminiRes.explanation;
            _matchedResults = matchedFromGemini;
          });
        }
        return;
      } else {
        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _aiResponseText = geminiRes.explanation;
            _matchedResults = [];
          });
        }
        return;
      }
    }

    await Future.delayed(const Duration(milliseconds: 600));

    final query = queryText.toLowerCase();
    List<CourseModel> matches = [];
    String explanation = '';

    final isCloud = query.contains('cloud') || query.contains('aws') || query.contains('devops') || query.contains('kubernetes');
    final isAi = query.contains('inteligencia') || query.contains('ia') || query.contains('python') || query.contains('machine');
    final isSecurity = query.contains('seguridad') || query.contains('ciber') || query.contains('hacking');
    final isMobile = query.contains('móvil') || query.contains('flutter') || query.contains('app');

    matches = widget.courses.where((c) {
      final title = c.title.toLowerCase();
      final desc = c.description.toLowerCase();
      final cat = c.category.toLowerCase();

      if (isCloud) return title.contains('cloud') || desc.contains('aws') || cat.contains('cloud');
      if (isAi) return title.contains('inteligencia') || desc.contains('python') || cat.contains('ia');
      if (isSecurity) return title.contains('ciberseguridad') || desc.contains('seguridad') || cat.contains('seguridad');
      if (isMobile) return title.contains('móvil') || desc.contains('flutter') || cat.contains('móvil');

      return title.contains(query) || desc.contains(query) || cat.contains(query);
    }).toList();

    if (isCloud) {
      explanation = 'Analicé la oferta académica de la Universidad TESOEM y seleccioné los programas ejecutivos en Arquitectura Cloud, AWS e Infraestructura DevOps:';
    } else if (isAi) {
      explanation = 'Encontré el programa oficial de Capacitación en Inteligencia Artificial y Machine Learning para empresas:';
    } else if (isSecurity) {
      explanation = 'Aquí está el curso especializado en Ciberseguridad Empresarial y Auditoría Hacking Ético con certificación oficial TESOEM:';
    } else {
      explanation = 'Procesé tu consulta "${queryText}" y seleccioné las mejores opciones de capacitación para tu empresa:';
    }

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _aiResponseText = explanation;
        _matchedResults = matches;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.82,
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A), // Dark Slate Noche
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Column(
              children: [
                // Indicador superior
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                ),

                // Encabezado IA
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Row(
                    children: [
                      AnimatedBuilder(
                        animation: _glowController,
                        builder: (context, child) {
                          return Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [AppTheme.primaryColor, AppTheme.accentColor],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentColor.withOpacity(0.4 + _glowController.value * 0.3),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 26),
                          );
                        },
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Asistente IA de Cursos 🤖✨',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Busca cursos corporativos en lenguaje natural',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: Colors.white70),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),

                const Divider(color: Colors.white12, height: 1),

                // Contenido Conversacional
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20.0),
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sugerencias rápidas para consultar:',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),

                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _presetPrompts.map((prompt) {
                            return GestureDetector(
                              onTap: () => _processAiQuery(prompt),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1E293B),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                                ),
                                child: Text(
                                  prompt,
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w500),
                                ),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 24),

                        if (_isAnalyzing) ...[
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white12),
                            ),
                            child: Row(
                              children: [
                                const CircularProgressIndicator(color: AppTheme.accentColor, strokeWidth: 2.5),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    'La IA está analizando los planes de capacitación de la Universidad TESOEM...',
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_aiResponseText.isNotEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 20),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.4)),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentColor, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _aiResponseText,
                                    style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5, height: 1.4),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Column(
                            children: _matchedResults.map((c) => _buildAiCourseCard(c)).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Campo de Entrada de Texto
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF1E293B),
                    border: Border(top: BorderSide(color: Colors.white12)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: TextField(
                            controller: _queryController,
                            style: GoogleFonts.inter(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.bold),
                            cursorColor: AppTheme.accentColor,
                            decoration: InputDecoration(
                              filled: false,
                              fillColor: Colors.transparent,
                              hintText: 'Escribe el curso que busca tu empresa...',
                              hintStyle: GoogleFonts.inter(color: Colors.white60, fontSize: 13),
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                            ),
                            onSubmitted: (val) => _processAiQuery(val),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [AppTheme.primaryColor, AppTheme.accentColor]),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
                        ),
                        onPressed: () => _processAiQuery(_queryController.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAiCourseCard(CourseModel course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.school_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      '${course.category} • ${course.price}',
                      style: GoogleFonts.inter(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
                  ),
                  child: Text('Ver Reseña 📄', style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5)),
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
                  ),
                  child: Text('Cotizar 💼', style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
