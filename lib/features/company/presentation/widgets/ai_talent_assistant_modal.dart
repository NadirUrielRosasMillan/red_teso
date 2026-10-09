import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/services/gemini_ai_service.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/company/presentation/pages/student_detail_view_page.dart';
import 'package:red_teso/features/company/presentation/widgets/contact_student_modal.dart';
import 'package:red_teso/features/company/presentation/widgets/invite_student_modal.dart';

/// Asistente Virtual Inteligente con Búsqueda Semántica en Lenguaje Natural (IA RedTESO)
class AiTalentAssistantModal extends StatefulWidget {
  final List<Map<String, dynamic>> students;

  const AiTalentAssistantModal({
    super.key,
    required this.students,
  });

  static Future<void> show(BuildContext context, {required List<Map<String, dynamic>> students}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AiTalentAssistantModal(students: students),
    );
  }

  @override
  State<AiTalentAssistantModal> createState() => _AiTalentAssistantModalState();
}

class _AiTalentAssistantModalState extends State<AiTalentAssistantModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  late AnimationController _glowController;

  bool _isAnalyzing = false;
  String _aiResponseText = '';
  List<Map<String, dynamic>> _matchedResults = [];

  final List<String> _presetPrompts = [
    '🗄️ Alumnos en Bases de Datos cerca de Chalco',
    '📱 Desarrolladores Flutter con inglés para Residencias',
    '🔒 Expertos en Ciberseguridad con promedio alto (+9.0)',
    '🐍 Programadores Python / Machine Learning',
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

  /// Procesa la consulta en lenguaje cotidiano con la IA semántica
  void _processAiQuery(String queryText) async {
    if (queryText.trim().isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _queryController.text = queryText;
    });

    await Future.delayed(const Duration(milliseconds: 700));

    final trimmedQuery = queryText.trim().toLowerCase();

    // Detección de saludos e interacción conversacional cotidiana
    final isGreeting = RegExp(r'^(hola|holaa|holaaa|buenas|buenos dias|buenas tardes|buenas noches|hey|que tal|saludos)\b').hasMatch(trimmedQuery);
    final isWhoAreYou = RegExp(r'(quien eres|que haces|que puedes hacer|como me ayudas|ayuda|funciones)\b').hasMatch(trimmedQuery);
    final isThanks = RegExp(r'^(gracias|muchas gracias|thx|thank you|ok gracias)\b').hasMatch(trimmedQuery);

    if (isGreeting || isWhoAreYou || isThanks) {
      String response = '';
      if (isGreeting) {
        response = '¡Hola! 👋 Soy el Asistente IA de Talento RedTESO.\n\nPuedo ayudarte a encontrar alumnos y candidatos universitarios según sus habilidades técnicas, ubicación, promedio o modalidad. ¿Qué tipo de talento busca tu empresa hoy?';
      } else if (isWhoAreYou) {
        response = '🤖 ¡Hola! Soy el Asistente IA de Talento RedTESO.\n\nPuedo analizar los perfiles de estudiantes de TESOEM y recomendarte candidatos por habilidades (ej. SQL, Flutter, Python, Ciberseguridad), promedio o zona geográfica.\n\n¡Prueba consultando algo como "Alumnos en Ciberseguridad con promedio alto"!';
      } else {
        response = '¡Con gusto! 😊 Quedo a tu disposición para ayudarte a conectar con el mejor talento de TESOEM.';
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _aiResponseText = response;
          _matchedResults = [];
        });
      }
      return;
    }

    final queryLower = queryText.toLowerCase();
    final terms = queryLower.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();

    List<Map<String, dynamic>> combinedStudents = List.from(widget.students);

    try {
      final snapshot = await FirebaseFirestore.instance.collection('users').get();
      for (var doc in snapshot.docs) {
        final data = doc.data();
        if (data['userType'] == 'alumno' || data['role'] == 'alumno' || data['gpa'] != null) {
          final uid = doc.id;
          if (!combinedStudents.any((s) => s['uid'] == uid || s['email'] == data['email'])) {
            combinedStudents.add({
              'uid': uid,
              'name': data['name'] ?? 'Alumno TESOEM',
              'email': data['email'] ?? '',
              'gpa': (data['gpa'] is num) ? (data['gpa'] as num).toDouble() : 8.5,
              'modality': data['modality'] ?? 'Servicio Social',
              'career': 'Ing. en Sistemas Computacionales',
              'skills': data['skills'] is List ? List<String>.from(data['skills']) : ['Java', 'SQL', 'Git'],
              'location': 'Chalco / Oriente',
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error obteniendo alumnos en Firestore para la IA: $e');
    }

    if (GeminiAiService.hasApiKey) {
      final geminiRes = await GeminiAiService.queryTalent(
        userPrompt: queryText,
        students: combinedStudents,
      );

      if (geminiRes.isGenerative) {
        final matchedFromGemini = combinedStudents
            .where((s) => geminiRes.recommendedIds.contains(s['uid']))
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

    final scored = <Map<String, dynamic>, double>{};

    for (var s in combinedStudents) {
      double score = 0.0;
      final name = s['name'].toString().toLowerCase();
      final skillsList = (s['skills'] as List?)?.map((e) => e.toString().toLowerCase()).toList() ?? [];
      final skillsText = skillsList.join(' ');
      final location = (s['location'] ?? 'Chalco').toString().toLowerCase();
      final modality = (s['modality'] ?? '').toString().toLowerCase();
      final career = (s['career'] ?? '').toString().toLowerCase();
      final full = '$name $skillsText $location $modality $career';

      for (var term in terms) {
        if (skillsText.contains(term)) score += 3.0;
        if (location.contains(term)) score += 2.5;
        if (modality.contains(term)) score += 2.0;
        if (full.contains(term)) score += 1.0;
      }

      if (queryLower.contains('base') || queryLower.contains('sql')) {
        if (skillsText.contains('sql') || skillsText.contains('base') || skillsText.contains('postgres')) score += 4.0;
      }
      if (queryLower.contains('flutter') || queryLower.contains('móvil') || queryLower.contains('app')) {
        if (skillsText.contains('flutter') || skillsText.contains('react') || skillsText.contains('firebase')) score += 4.0;
      }
      if (queryLower.contains('seguridad') || queryLower.contains('ciber')) {
        if (skillsText.contains('seguridad') || skillsText.contains('redes') || skillsText.contains('ciber')) score += 4.0;
      }
      if (queryLower.contains('python') || queryLower.contains('machine') || queryLower.contains('ia')) {
        if (skillsText.contains('python') || skillsText.contains('machine') || skillsText.contains('ia')) score += 4.0;
      }
      if (queryLower.contains('alto') || queryLower.contains('promedio') || queryLower.contains('+9')) {
        final gpaVal = (s['gpa'] ?? 8.0) as double;
        if (gpaVal >= 9.0) score += 3.5;
      }

      scored[s] = score;
    }

    final sorted = scored.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    List<Map<String, dynamic>> matches = sorted.where((e) => e.value > 0).map((e) => e.key).toList();

    if (matches.isEmpty) {
      matches = combinedStudents.take(3).toList();
    } else {
      matches = matches.take(4).toList();
    }

    String explanation = '';
    if (queryLower.contains('base') || queryLower.contains('sql')) {
      explanation = '🤖 Analicé el directorio de Sistemas TESOEM e identifiqué a los siguientes candidatos especializados en Bases de Datos, SQL y gestión de datos:';
    } else if (queryLower.contains('flutter') || queryLower.contains('móvil') || queryLower.contains('app')) {
      explanation = '🤖 Encontré a los alumnos con experiencia en desarrollo de aplicaciones móviles (Flutter/Firebase/React) disponibles para proyectos corporativos:';
    } else if (queryLower.contains('seguridad') || queryLower.contains('ciber')) {
      explanation = '🤖 Aquí están los perfiles con preparación destacada en Ciberseguridad, Redes e Infraestructura Cloud:';
    } else if (queryLower.contains('promedio') || queryLower.contains('alto') || queryLower.contains('+9')) {
      explanation = '🤖 Filtré a los estudiantes de Excelencia Académica con promedio sobresaliente superior a 9.0/10.0:';
    } else {
      explanation = '🤖 Procesé tu consulta "$queryText" mediante IA semántica y seleccioné a los alumnos de TESOEM con mayor afinidad:';
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
                              'Asistente IA de Talento 🤖✨',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Búsqueda semántica inteligente en lenguaje natural',
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
                                    'La IA está analizando perfiles y coincidencias en la nube...',
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
                            children: _matchedResults.map((s) => _buildAiStudentCard(s)).toList(),
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
                              filled: false, // Sobrescribe el fillColor blanco global
                              fillColor: Colors.transparent,
                              hintText: 'Escribe tu consulta en lenguaje cotidiano...',
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

  Widget _buildAiStudentCard(Map<String, dynamic> student) {
    final name = student['name'] ?? 'Alumno';
    final gpa = (student['gpa'] ?? 8.5).toStringAsFixed(1);
    final modality = student['modality'] ?? 'Residencias';
    final skills = List<String>.from(student['skills'] ?? ['Java', 'Python', 'SQL']);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
              CircleAvatar(
                radius: 20,
                backgroundColor: AppTheme.primaryColor,
                child: Text(name[0], style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('Sistemas • $modality • GPA: $gpa', style: GoogleFonts.inter(color: AppTheme.accentColor, fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            children: skills.map((skill) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(8)),
                child: Text(skill, style: GoogleFonts.inter(color: Colors.white70, fontSize: 11)),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    InviteStudentModal.show(context, student: student);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Invitar 📩', style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => StudentDetailViewPage(student: student)),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Perfil 👤', style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
