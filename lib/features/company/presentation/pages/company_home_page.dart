import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/core/widgets/notification_bell.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/company/presentation/pages/student_detail_view_page.dart';
import 'package:red_teso/features/company/presentation/widgets/contact_student_modal.dart';
import 'package:red_teso/features/company/presentation/widgets/ai_talent_assistant_modal.dart';
import 'package:red_teso/features/company/presentation/widgets/invite_student_modal.dart';

class CompanyHomePage extends StatefulWidget {
  const CompanyHomePage({super.key});

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();

  String _searchQuery = '';
  String _selectedModality = 'Todos';
  bool _requireHighGpa = false;
  bool _requireEnglish = false;
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

  void _resetFilters() {
    setState(() {
      _searchQuery = '';
      _selectedModality = 'Todos';
      _requireHighGpa = false;
      _requireEnglish = false;
    });
  }

  void _applyTechFilter(String tech) {
    setState(() {
      if (_searchQuery.toLowerCase() == tech.toLowerCase()) {
        _searchQuery = '';
      } else {
        _searchQuery = tech;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Buscador de Talento',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 20, color: const Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        actions: [
          const NotificationBell(color: AppTheme.primaryColor),
          const SizedBox(width: 8),
        ],
      ),

      // Botón de Acción Flotante Inteligente cuando se hace scroll
      floatingActionButton: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: _isScrolled
            ? Padding(
                padding: const EdgeInsets.only(bottom: 100), // Por encima del dock flotante Liquid Glass
                child: FloatingActionButton(
                  key: const ValueKey('floating_ai_talent_btn'),
                  onPressed: () => AiTalentAssistantModal.show(context, students: _sampleStudents),
                  backgroundColor: const Color(0xFF0F172A),
                  elevation: 6,
                  tooltip: 'IA REDTESO 🤖',
                  child: const Icon(Icons.psychology_rounded, color: AppTheme.accentColor, size: 24),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('empty_ai_talent_btn')),
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

                // 1. BOTÓN DE BÚSQUEDA SEMÁNTICA CON IA REDTESO 🤖✨
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 250),
                  opacity: _isScrolled ? 0.3 : 1.0,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        AiTalentAssistantModal.show(context, students: _sampleStudents);
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
                                    'Búsqueda Semántica con IA RedTESO 🤖✨',
                                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Ej. "Busco alumno en bases de datos cerca de Chalco"',
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

                // 2. CHIPS DE TECNOLOGÍAS RÁPIDAS
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Text('Tecnologías: ', style: GoogleFonts.inter(fontSize: 11.5, fontWeight: FontWeight.bold, color: const Color(0xFF64748B))),
                      ...['Python', 'Flutter', 'AWS', 'Java', 'React', 'Ciberseguridad', 'SQL'].map((tech) {
                        final isSelected = _searchQuery.toLowerCase() == tech.toLowerCase();
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: ActionChip(
                            label: Text(tech),
                            backgroundColor: isSelected ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                            labelStyle: GoogleFonts.inter(
                              color: isSelected ? Colors.white : const Color(0xFF334155),
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                              ),
                            ),
                            onPressed: () => _applyTechFilter(tech),
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),

                const SizedBox(height: 6),

                // 3. CHIPS DE FILTRO RÁPIDO (Modalidad, GPA, Inglés)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      ...['Todos', 'Residencias', 'Servicio Social', 'Recién Egresado'].map((modality) {
                        final isSelected = _selectedModality == modality;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(modality),
                            selected: isSelected,
                            selectedColor: AppTheme.primaryColor,
                            labelStyle: GoogleFonts.inter(
                              color: isSelected ? Colors.white : const Color(0xFF475569),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12.5,
                            ),
                            onSelected: (val) => setState(() => _selectedModality = modality),
                          ),
                        );
                      }),
                      FilterChip(
                        label: const Text('🌟 GPA 9.0+'),
                        selected: _requireHighGpa,
                        selectedColor: AppTheme.accentColor,
                        checkmarkColor: Colors.white,
                        labelStyle: GoogleFonts.inter(
                          color: _requireHighGpa ? Colors.white : const Color(0xFF475569),
                          fontWeight: _requireHighGpa ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12.5,
                        ),
                        onSelected: (val) => setState(() => _requireHighGpa = val),
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('🗣️ Inglés'),
                        selected: _requireEnglish,
                        selectedColor: AppTheme.primaryColor,
                        checkmarkColor: Colors.white,
                        labelStyle: GoogleFonts.inter(
                          color: _requireEnglish ? Colors.white : const Color(0xFF475569),
                          fontWeight: _requireEnglish ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12.5,
                        ),
                        onSelected: (val) => setState(() => _requireEnglish = val),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
              ],
            ),
          ),

          // 4. LISTA DE TALENTOS EN TIEMPO REAL DESDE FIRESTORE
          StreamBuilder<QuerySnapshot>(
            stream: _db.collection('users').where('type', isEqualTo: 'alumno').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('Error de conexión a la nube')),
                );
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                );
              }

              final docs = snapshot.data?.docs ?? [];

              // Mapea los documentos de Firestore
              List<Map<String, dynamic>> studentsList = docs.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return {
                  'uid': doc.id,
                  'name': data['name'] ?? 'Alumno Registrado',
                  'email': data['email'] ?? '',
                  'gpa': (data['gpa'] ?? 8.5).toDouble(),
                  'modality': data['modality'] ?? 'Residencias',
                  'gender': data['gender'] ?? 'Femenino',
                  'speaksEnglish': data['speaksEnglish'] ?? false,
                  'career': data['career'] ?? 'Ing. en Sistemas Computacionales',
                  'skills': data['skills'] ?? ['Java', 'Python', 'React', 'Ciberseguridad', 'Flutter', 'AWS', 'SQL'],
                  'location': data['location'] ?? 'Chalco',
                };
              }).toList();

              // Si aún no hay alumnos en Firestore, incluye perfiles de demostración para pruebas
              if (studentsList.isEmpty) {
                studentsList = _sampleStudents;
              }

              // Aplicación de Filtros Inteligentes
              final filtered = studentsList.where((s) {
                final name = s['name'].toString().toLowerCase();
                final career = s['career'].toString().toLowerCase();
                final skills = (s['skills'] as List).join(' ').toLowerCase();
                final query = _searchQuery.toLowerCase().trim();

                final matchesQuery = query.isEmpty ||
                    name.contains(query) ||
                    career.contains(query) ||
                    skills.contains(query);

                final matchesModality =
                    _selectedModality == 'Todos' || s['modality'] == _selectedModality;

                final matchesGpa = !_requireHighGpa || (s['gpa'] as double) >= 9.0;
                final matchesEnglish = !_requireEnglish || (s['speaksEnglish'] as bool);

                return matchesQuery && matchesModality && matchesGpa && matchesEnglish;
              }).toList();

              if (filtered.isEmpty) {
                return SliverToBoxAdapter(child: _buildEmptyState());
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final student = filtered[index];
                      return _buildExecutiveTalentCard(student);
                    },
                    childCount: filtered.length,
                  ),
                ),
              );
            },
          ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 100), // Espacio para el dock flotante Liquid Glass
          ),
        ],
      ),
    );
  }

  /// Construye la tarjeta ejecutiva estilo LinkedIn / Glassmorphic para cada alumno
  Widget _buildExecutiveTalentCard(Map<String, dynamic> student) {
    final name = student['name'] ?? 'Alumno';
    final gpa = (student['gpa'] ?? 8.5).toStringAsFixed(1);
    final modality = student['modality'] ?? 'Residencias';
    final speaksEnglish = student['speaksEnglish'] ?? false;
    final skills = List<String>.from(student['skills'] ?? ['Java', 'Python', 'React', 'Flutter', 'AWS', 'SQL']);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailViewPage(student: student),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. FOTO/AVATAR DE PERFIL CON MARCO GUINDA Y BADGE DORADO DE PROMEDIO
              Row(
                children: [
                  Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.primaryColor, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: AppTheme.primaryColor.withOpacity(0.12),
                          child: Text(
                            name[0],
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      // Badge Dorado de Promedio GPA
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F172A),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.accentColor, width: 1.2),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                            const SizedBox(width: 2),
                            Text(
                              gpa,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 10.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 14),

                  // NOMBRE Y DISPONIBILIDAD
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ing. en Sistemas Computacionales',
                          style: GoogleFonts.inter(
                            fontSize: 12.5,
                            color: const Color(0xFF64748B),
                          ),
                        ),
                        const SizedBox(height: 6),

                        // INSIGNIA EN VIVO DE DISPONIBILIDAD
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFECFDF5), // Emerald light
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Disponible para $modality',
                                style: GoogleFonts.inter(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF047857),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // 2. SKILLS & TECNOLOGÍAS DEL ALUMNO (Highlight si coincide con la búsqueda)
              Text(
                'Habilidades Tecnológicas:',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF334155),
                ),
              ),
              const SizedBox(height: 6),

              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ...skills.map((skill) {
                    final isMatched = _searchQuery.isNotEmpty &&
                        skill.toLowerCase().contains(_searchQuery.toLowerCase().trim());

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isMatched ? AppTheme.primaryColor : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isMatched ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Text(
                        skill,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          fontWeight: isMatched ? FontWeight.bold : FontWeight.w600,
                          color: isMatched ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    );
                  }),
                  if (speaksEnglish)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.g_translate_rounded, size: 12, color: AppTheme.primaryColor),
                          const SizedBox(width: 4),
                          Text(
                            'Inglés Avanzado',
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const Divider(height: 28),

              // 3. ACCIÓN UNIFICADA: INVITAR A VACANTE DIRECTA 📩
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    InviteStudentModal.show(context, student: student);
                  },
                  icon: const Icon(Icons.mark_email_read_rounded, size: 18, color: Colors.white),
                  label: Text(
                    'INVITAR A VACANTE DIRECTA 📩',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white, letterSpacing: 0.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(32),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          const Icon(Icons.person_search_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'No se encontraron alumnos',
            style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 6),
          Text(
            'No hay candidatos que coincidan con "$_searchQuery" o con los filtros aplicados.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _resetFilters,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Restablecer Filtros'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  // Lista de alumnos de demostración con tecnologías específicas y ubicación
  static final List<Map<String, dynamic>> _sampleStudents = [
    {
      'uid': 'student_demo_1',
      'name': 'Carlos Eduardo Mendoza',
      'email': 'carlos.mendoza@tesoem.edu.mx',
      'gpa': 9.6,
      'modality': 'Residencias',
      'gender': 'Masculino',
      'speaksEnglish': true,
      'career': 'Ing. en Sistemas Computacionales',
      'skills': ['Bases de Datos', 'SQL', 'Kubernetes', 'AWS', 'Docker', 'Python'],
      'location': 'Chalco',
    },
    {
      'uid': 'student_demo_2',
      'name': 'Valeria Gómez Peña',
      'email': 'valeria.gomez@tesoem.edu.mx',
      'gpa': 9.4,
      'modality': 'Residencias',
      'gender': 'Femenino',
      'speaksEnglish': true,
      'career': 'Ing. en Sistemas Computacionales',
      'skills': ['Flutter', 'React', 'Firebase', 'Terraform', 'SQL', 'Git'],
      'location': 'Ixtapaluca',
    },
    {
      'uid': 'student_demo_3',
      'name': 'Alejandro Ruiz Peralta',
      'email': 'alejandro.ruiz@tesoem.edu.mx',
      'gpa': 9.8,
      'modality': 'Recién Egresado',
      'gender': 'Masculino',
      'speaksEnglish': true,
      'career': 'Ing. en Sistemas Computacionales',
      'skills': ['Python', 'Ciberseguridad', 'Machine Learning', 'OpenCV', 'React', 'Java'],
      'location': 'Valle de Chalco',
    },
  ];
}
