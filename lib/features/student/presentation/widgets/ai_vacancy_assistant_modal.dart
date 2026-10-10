import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/services/gemini_ai_service.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/student/presentation/pages/vacancy_detail_page.dart';

class AiChatMessage {
  final String text;
  final bool isUser;
  final List<Map<String, dynamic>>? vacancyCards;

  AiChatMessage({
    required this.text,
    required this.isUser,
    this.vacancyCards,
  });
}

/// Asistente Virtual Inteligente con Búsqueda Semántica de Vacantes en Formato Chat para Estudiantes
class AiVacancyAssistantModal extends StatefulWidget {
  const AiVacancyAssistantModal({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AiVacancyAssistantModal(),
    );
  }

  @override
  State<AiVacancyAssistantModal> createState() => _AiVacancyAssistantModalState();
}

class _AiVacancyAssistantModalState extends State<AiVacancyAssistantModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _glowController;

  bool _isAnalyzing = false;
  final List<AiChatMessage> _chatMessages = [];

  final List<String> _presetPrompts = [
    '💻 Vacantes de Servicio Social en Desarrollo Web o Mobile',
    '📍 Vacantes cerca de Chalco o Ixtapaluca con apoyo económico',
    '🎓 Oportunidades para Recién Egresados en Sistemas',
    '🔒 Vacantes en Ciberseguridad, Redes o Soporte Técnico',
  ];

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    // Saludo inicial de bienvenida de la IA
    _chatMessages.add(
      AiChatMessage(
        text: '¡Hola! 👋 Soy tu Asistente Inteligente de RedTESO.\n\nPuedo ayudarte a encontrar vacantes de Servicio Social, Residencias Profesionales o Empleos para egresados. ¿En qué área o tecnología te gustaría buscar hoy?',
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

  /// Procesa la consulta en lenguaje natural analizando Firestore /vacancies
  Future<void> _processAiQuery(String queryText) async {
    if (queryText.trim().isEmpty) return;

    final userMessageText = queryText.trim();
    _queryController.clear();

    setState(() {
      _chatMessages.add(AiChatMessage(text: userMessageText, isUser: true));
      _isAnalyzing = true;
    });
    _scrollToBottom();

    final trimmedQuery = userMessageText.toLowerCase();

    // Detección de saludos e interacción conversacional cotidiana
    final isGreeting = RegExp(r'^(hola|holaa|holaaa|buenas|buenos dias|buenas tardes|buenas noches|hey|que tal|saludos|que onda|oye|fifi|fium)\b').hasMatch(trimmedQuery);
    final isWhoAreYou = RegExp(r'(quien eres|que haces|que puedes hacer|como me ayudas|ayuda|funciones)\b').hasMatch(trimmedQuery);
    final isThanks = RegExp(r'^(gracias|muchas gracias|thx|thank you|ok gracias)\b').hasMatch(trimmedQuery);

    if (!GeminiAiService.hasApiKey && (isGreeting || isWhoAreYou || isThanks)) {
      await Future.delayed(const Duration(milliseconds: 500));
      String response = '';
      if (isGreeting) {
        response = '¡Hola! 👋 Qué gusto saludarte. ¿Qué tipo de vacante o tecnología te gustaría consultar hoy?';
      } else if (isWhoAreYou) {
        response = '🤖 ¡Hola! Soy el Asistente IA de RedTESO.\n\nPuedo analizar la oferta de empresas vinculadas con TESOEM y recomendarte las mejores vacantes por área (ej. Flutter, Python, SQL, Ciberseguridad).\n\n¡Prueba escribiendo "Vacantes de Servicio Social en desarrollo web"!';
      } else {
        response = '¡Con mucho gusto! 😊 Estoy aquí para ayudarte a impulsar tu carrera profesional en TESOEM.';
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _chatMessages.add(AiChatMessage(text: response, isUser: false));
        });
        _scrollToBottom();
      }
      return;
    }

    try {
      final snapshot = await FirebaseFirestore.instance.collection('vacancies').get();
      List<Map<String, dynamic>> allVacancies = snapshot.docs.map((d) {
        final data = d.data();
        return {...data, 'id': d.id};
      }).toList();

      if (allVacancies.length < 3) {
        allVacancies.addAll(_fallbackVacancies);
      }

      // 1. INTENTO DE CONSULTA CON GEMINI REAL
      if (GeminiAiService.hasApiKey) {
        final geminiRes = await GeminiAiService.queryVacancies(
          userPrompt: userMessageText,
          vacancies: allVacancies,
        );

        final matchedFromGemini = allVacancies
            .where((v) => geminiRes.recommendedIds.contains(v['id']))
            .toList();

        if (mounted) {
          setState(() {
            _isAnalyzing = false;
            _chatMessages.add(
              AiChatMessage(
                text: geminiRes.explanation,
                isUser: false,
                vacancyCards: matchedFromGemini,
              ),
            );
          });
          _scrollToBottom();
        }
        return;
      }

      await Future.delayed(const Duration(milliseconds: 600));

      // Sistema de scoring de relevancia por Inteligencia Artificial (Fallback local)
      final terms = trimmedQuery.split(RegExp(r'\s+')).where((t) => t.length > 2).toList();
      final scoredVacancies = <Map<String, dynamic>, double>{};

      for (var v in allVacancies) {
        double score = 0.0;
        final title = (v['puesto'] ?? '').toString().toLowerCase();
        final company = (v['empresa'] ?? '').toString().toLowerCase();
        final desc = (v['descripcion'] ?? '').toString().toLowerCase();
        final type = (v['tipo'] ?? '').toString().toLowerCase();
        final location = (v['ubicacion'] ?? '').toString().toLowerCase();
        final requirements = (v['requisitos'] ?? []).toString().toLowerCase();

        final fullText = '$title $company $desc $type $location $requirements';

        for (var term in terms) {
          if (title.contains(term)) score += 3.0;
          if (type.contains(term)) score += 2.5;
          if (location.contains(term)) score += 2.0;
          if (requirements.contains(term)) score += 2.0;
          if (fullText.contains(term)) score += 1.0;
        }

        if (trimmedQuery.contains('servicio') && type.contains('servicio')) score += 4.0;
        if (trimmedQuery.contains('residencia') && type.contains('residencia')) score += 4.0;
        if ((trimmedQuery.contains('egresado') || trimmedQuery.contains('empleo')) && (type.contains('egresado') || type.contains('empleo'))) score += 4.0;
        if ((trimmedQuery.contains('chalco') || trimmedQuery.contains('reyes')) && (location.contains('chalco') || location.contains('reyes'))) score += 3.5;
        if (trimmedQuery.contains('auto') && (title.contains('auto') || desc.contains('auto'))) score += 4.0;

        scoredVacancies[v] = score;
      }

      final sortedList = scoredVacancies.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
      List<Map<String, dynamic>> matches = sortedList.where((e) => e.value > 0).map((e) => e.key).toList();

      String explanation = '';
      if (matches.isNotEmpty) {
        explanation = '🤖 Encontré las siguientes oportunidades en TESOEM afines a tu búsqueda:';
        matches = matches.take(3).toList();
      } else {
        explanation = '🤖 Entendido. Platícame más sobre qué tecnología, zona o modalidad te interesa para recomendarte la mejor opción.';
      }

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _chatMessages.add(
            AiChatMessage(
              text: explanation,
              isUser: false,
              vacancyCards: matches,
            ),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Error en IA Vacancy Assistant: $e');
      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _chatMessages.add(
            AiChatMessage(
              text: 'Ocurrió un inconveniente al consultar las vacantes. Te comparto las más destacadas:',
              isUser: false,
              vacancyCards: _fallbackVacancies.take(2).toList(),
            ),
          );
        });
        _scrollToBottom();
      }
    }
  }

  static final List<Map<String, dynamic>> _fallbackVacancies = [
    {
      'id': 'v_fallback_1',
      'puesto': 'Desarrollador Junior Flutter / Firebase',
      'empresa': 'Tech Solutions México',
      'tipo': 'Residencias',
      'ubicacion': 'Chalco (Híbrido)',
      'sueldo': '\$8,000 / mes + Beca',
      'descripcion': 'Buscamos estudiante de Ing. Sistemas Computacionales con conocimientos en Flutter y Firebase para desarrollo de apps móviles.',
      'requisitos': 'Flutter, Dart, Git, Firebase, Promedio +8.5',
    },
    {
      'id': 'v_fallback_2',
      'puesto': 'Auxiliar de Bases de Datos & SQL',
      'empresa': 'Corporativo Logístico del Oriente',
      'tipo': 'Servicio Social',
      'ubicacion': 'Ixtapaluca, Edo. Méx.',
      'sueldo': 'Apoyo para pasajes \$3,500/mes',
      'descripcion': 'Soporte en mantenimiento y optimización de bases de datos PostgreSQL y MySQL.',
      'requisitos': 'SQL, Consultas complejas, Trabajo en equipo',
    },
  ];

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
                                colors: [AppTheme.primaryGreen, AppTheme.accentColor],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryGreen.withOpacity(0.4 + _glowController.value * 0.3),
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
                              'Asistente IA de Vacantes 🤖✨',
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: 19, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              'Chat conversacional e inteligente en español',
                              style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.5),
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

                // Área de Mensajes e Historial de Chat
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20.0),
                    physics: const BouncingScrollPhysics(),
                    itemCount: _chatMessages.length + (_isAnalyzing ? 1 : 0) + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Sugerencias rápidas arriba
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Sugerencias de búsqueda rápida:',
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
                        return _buildChatBubble(msg);
                      }

                      // Indicador de "Escribiendo..."
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
                            const CircularProgressIndicator(color: AppTheme.primaryGreen, strokeWidth: 2.5),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                'La IA está redactando la respuesta...',
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

                // Campo de entrada de texto
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
                              hintText: 'Escribe tu duda o consulta...',
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
                            gradient: LinearGradient(colors: [AppTheme.primaryGreen, AppTheme.accentColor]),
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

  Widget _buildChatBubble(AiChatMessage msg) {
    if (msg.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 14, left: 40),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
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
            if (msg.vacancyCards != null && msg.vacancyCards!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Column(
                children: msg.vacancyCards!.map((v) => _buildAiVacancyCard(v)).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAiVacancyCard(Map<String, dynamic> v) {
    final title = v['puesto'] ?? 'Vacante';
    final company = v['empresa'] ?? 'Empresa';
    final type = v['tipo'] ?? 'Servicio Social';
    final location = v['ubicacion'] ?? 'Remoto';
    final salary = v['sueldo'] ?? 'Convenio TESOEM';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.work_outline_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    Text('$company • $type', style: GoogleFonts.inter(color: AppTheme.accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, color: Colors.white70, size: 14),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  location,
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 11.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.payments_outlined, color: Colors.amber, size: 14),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  salary,
                  style: GoogleFonts.inter(color: Colors.amber, fontSize: 11.5, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => VacancyDetailPage(vacancy: v)),
                );
              },
              icon: const Icon(Icons.visibility_rounded, size: 16, color: Colors.white),
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('VER VACANTE Y POSTULARME 📄', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
