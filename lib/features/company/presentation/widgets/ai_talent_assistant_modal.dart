import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/services/gemini_ai_service.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/company/presentation/pages/student_detail_view_page.dart';
import 'package:red_teso/features/company/presentation/widgets/invite_student_modal.dart';

class TalentChatMessage {
  final String text;
  final bool isUser;
  final List<Map<String, dynamic>>? studentCards;

  TalentChatMessage({
    required this.text,
    required this.isUser,
    this.studentCards,
  });
}

/// Asistente Virtual Inteligente con Búsqueda Semántica de Talento en Formato Chat para Reclutadores
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
  final ScrollController _scrollController = ScrollController();
  late AnimationController _glowController;

  bool _isAnalyzing = false;
  final List<TalentChatMessage> _chatMessages = [];

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

    _chatMessages.add(
      TalentChatMessage(
        text: '¡Hola! 👋 Soy el Asistente IA de Talento RedTESO.\n\nPuedo ayudarte a encontrar alumnos y candidatos universitarios según sus habilidades técnicas, ubicación, promedio o modalidad. ¿Qué tipo de talento busca tu empresa hoy?',
        isUser: false,
      ),
    );
  }

  @override
  void dispose() {
    _queryController.dispose();
    _scrollController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 150), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _processAiQuery(String queryText) async {
    if (queryText.trim().isEmpty) return;

    final userMessageText = queryText.trim();
    _queryController.clear();

    setState(() {
      _chatMessages.add(TalentChatMessage(text: userMessageText, isUser: true));
      _isAnalyzing = true;
    });
    _scrollToBottom();

    final trimmedQuery = userMessageText.toLowerCase();

    final isGreeting = RegExp(r'^(hola|holaa|oye|oyee|buenas|buenos dias|buenas tardes|buenas noches|hey|que tal|saludos|como estas|perro|fifi)\b').hasMatch(trimmedQuery);
    final isWhoAreYou = RegExp(r'(quien eres|que haces|que puedes hacer|como me ayudas|ayuda|funciones)\b').hasMatch(trimmedQuery);
    final isThanks = RegExp(r'^(gracias|muchas gracias|thx|thank you|ok gracias)\b').hasMatch(trimmedQuery);

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

    if (!GeminiAiService.hasApiKey && (isGreeting || isWhoAreYou || isThanks)) {
      await Future.delayed(const Duration(milliseconds: 400));
      String response = '';
      if (isGreeting) {
        response = '¡Hola! 👋 Soy el Asistente IA de Talento RedTESO. ¿Qué tipo de candidato o habilidad busca tu empresa hoy?';
      } else if (isWhoAreYou) {
        response = '🤖 ¡Hola! Soy el Asistente IA de Talento RedTESO.\n\nPuedo analizar los perfiles de estudiantes de TESOEM y recomendarte candidatos por habilidades (ej. SQL, Flutter, Python, Ciberseguridad), promedio o zona geográfica.\n\n¡Prueba consultando algo como "Alumnos en Ciberseguridad con promedio alto"!';
      } else {
        response = '¡Con gusto! 😊 Quedo a tu disposición para ayudarte a conectar con el mejor talento de TESOEM.';
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _chatMessages.add(TalentChatMessage(text: response, isUser: false));
        });
        _scrollToBottom();
      }
      return;
    }

    // 1. CONSULTA CON GEMINI REAL
    if (GeminiAiService.hasApiKey) {
      final geminiRes = await GeminiAiService.queryTalent(
        userPrompt: userMessageText,
        students: combinedStudents,
      );

      final matchedFromGemini = combinedStudents
          .where((s) => geminiRes.recommendedIds.contains(s['uid']))
          .toList();

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _chatMessages.add(
            TalentChatMessage(
              text: geminiRes.explanation,
              isUser: false,
              studentCards: matchedFromGemini,
            ),
          );
        });
        _scrollToBottom();
      }
      return;
    }

    await Future.delayed(const Duration(milliseconds: 600));

    final terms = trimmedQuery.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();
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

      scored[s] = score;
    }

    final sorted = scored.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    List<Map<String, dynamic>> matches = sorted.where((e) => e.value > 0).map((e) => e.key).toList();

    String explanation = '';
    if (matches.isNotEmpty) {
      explanation = '🤖 Identifiqué a los siguientes candidatos destacados para tu empresa:';
      matches = matches.take(3).toList();
    } else {
      explanation = '🤖 Cuéntame más sobre el perfil o habilidades requeridas para recomendarte a los alumnos más idóneos.';
    }

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _chatMessages.add(
          TalentChatMessage(
            text: explanation,
            isUser: false,
            studentCards: matches,
          ),
        );
      });
      _scrollToBottom();
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
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(10)),
                ),

                // Encabezado
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
                              'Chat conversacional para reclutamiento universitario',
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

                // Historial de Mensajes
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20.0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _chatMessages.length + (_isAnalyzing ? 1 : 0) + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Column(
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
                            const SizedBox(height: 20),
                            const Divider(color: Colors.white12),
                            const SizedBox(height: 12),
                          ],
                        );
                      }

                      final msgIndex = index - 1;

                      if (msgIndex < _chatMessages.length) {
                        final msg = _chatMessages[msgIndex];
                        return _buildTalentChatBubble(msg);
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(16),
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
                                'La IA está analizando los perfiles de los alumnos...',
                                style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
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
                              hintText: 'Escribe tu consulta o requisitos...',
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

  Widget _buildTalentChatBubble(TalentChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
          ),
          child: Text(
            msg.text,
            style: GoogleFonts.inter(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ),
      );
    }

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16, right: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(color: Colors.white12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppTheme.accentColor, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      msg.text,
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 13.5, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
            if (msg.studentCards != null && msg.studentCards!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                children: msg.studentCards!.map((s) => _buildAiStudentCard(s)).toList(),
              ),
            ],
          ],
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
