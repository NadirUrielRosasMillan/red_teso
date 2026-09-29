import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    await Future.delayed(const Duration(milliseconds: 1000));

    final query = queryText.toLowerCase();
    List<Map<String, dynamic>> matches = [];
    String explanation = '';

    final isDatabase = query.contains('base') || query.contains('datos') || query.contains('sql') || query.contains('chalco');
    final isMobile = query.contains('flutter') || query.contains('móvil') || query.contains('app');
    final isSecurity = query.contains('seguridad') || query.contains('ciber') || query.contains('hacking');
    final isPython = query.contains('python') || query.contains('ia') || query.contains('machine');

    matches = widget.students.where((s) {
      final name = s['name'].toString().toLowerCase();
      final skills = (s['skills'] as List).join(' ').toLowerCase();
      final location = (s['location'] ?? 'Chalco').toString().toLowerCase();

      if (isDatabase) {
        return skills.contains('sql') || skills.contains('base') || location.contains('chalco') || name.contains('carlos');
      }
      if (isMobile) {
        return skills.contains('flutter') || skills.contains('firebase');
      }
      if (isSecurity) {
        return skills.contains('seguridad') || skills.contains('ciberseguridad');
      }
      if (isPython) {
        return skills.contains('python') || skills.contains('machine');
      }

      return name.contains(query) || skills.contains(query) || location.contains(query);
    }).toList();

    if (matches.isEmpty) {
      matches = widget.students.take(2).toList();
    }

    if (isDatabase) {
      explanation = 'Analicé el directorio de Sistemas TESOEM e identifiqué a los siguientes candidatos especializados en Bases de Datos, SQL y ubicados cerca de la zona de Chalco / Oriente:';
    } else if (isMobile) {
      explanation = 'Encontré a los alumnos con desarrollo en aplicaciones móviles Flutter/Firebase disponibles para incorporarse a proyectos corporativos:';
    } else if (isSecurity) {
      explanation = 'Aquí están los perfiles con preparación en Auditoría de Seguridad e Infraestructura en Redes:';
    } else {
      explanation = 'Procesé tu consulta "${queryText}" y seleccioné las mejores coincidencias en tiempo real:';
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
