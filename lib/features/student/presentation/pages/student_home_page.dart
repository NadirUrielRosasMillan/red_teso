import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/core/widgets/notification_bell.dart';
import 'package:red_teso/core/widgets/liquid_glass_ambient_background.dart';
import 'package:red_teso/features/student/presentation/pages/vacancy_detail_page.dart';
import 'package:red_teso/features/student/presentation/widgets/ai_vacancy_assistant_modal.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final _searchController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String _selectedCategory = 'Todos';

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('RedTESO Estudiante', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFF090D16).withOpacity(0.85),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          const NotificationBell(color: Colors.white),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 100),
        child: FloatingActionButton(
          onPressed: () => AiVacancyAssistantModal.show(context),
          backgroundColor: AppTheme.primaryGreen,
          elevation: 8,
          tooltip: 'Asistente IA de Vacantes 🤖',
          child: const Icon(Icons.psychology_rounded, color: Colors.white, size: 26),
        ),
      ).animate().scale(delay: 300.ms, duration: 400.ms, curve: Curves.easeOutBack),
      body: LiquidGlassAmbientBackground(
        child: Column(
          children: [
            _buildStudentHeader(user?.uid)
                .animate()
                .fadeIn(duration: 500.ms)
                .slideY(begin: -0.1, end: 0, curve: Curves.easeOut),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                  boxShadow: [
                    BoxShadow(color: AppTheme.primaryGreen.withOpacity(0.15), blurRadius: 12, spreadRadius: 0),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                  cursorColor: AppTheme.accentColor,
                  decoration: InputDecoration(
                    hintText: 'Buscar vacantes o empresas...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: Colors.white54),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.accentColor),
                    filled: false,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 150.ms, duration: 400.ms),

            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ['Todos', 'Servicio Social', 'Residencias', 'Empleo Egresados']
                    .map((cat) => _buildCategoryChip(cat))
                    .toList(),
              ),
            ).animate().fadeIn(delay: 200.ms, duration: 400.ms),

            const SizedBox(height: 16),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _db.collection('vacancies').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text('Error al cargar vacantes', style: GoogleFonts.inter(color: Colors.white)));
                  }
                  if (!snapshot.hasData) {
                    return _buildShimmerSkeletonList();
                  }

                  final docs = snapshot.data!.docs.toList();
                  docs.sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>;
                    final bData = b.data() as Map<String, dynamic>;
                    final aTime = aData['createdAt'] as Timestamp?;
                    final bTime = bData['createdAt'] as Timestamp?;
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return -1;
                    if (bTime == null) return 1;
                    return bTime.compareTo(aTime);
                  });

                  final vacancies = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final matchesCat = _selectedCategory == 'Todos' || data['tipo'] == _selectedCategory;
                    final searchLower = _searchController.text.toLowerCase();
                    final matchesSearch = (data['puesto'] ?? '').toString().toLowerCase().contains(searchLower) ||
                        (data['empresa'] ?? '').toString().toLowerCase().contains(searchLower);
                    return matchesCat && matchesSearch;
                  }).toList();

                  if (vacancies.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.work_off_outlined, size: 54, color: Colors.white38),
                            const SizedBox(height: 12),
                            Text('No se encontraron vacantes', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                            Text('Prueba con otra búsqueda o categoría', style: GoogleFonts.inter(color: Colors.white60, fontSize: 12.5)),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: vacancies.length,
                    itemBuilder: (context, index) {
                      final data = vacancies[index].data() as Map<String, dynamic>;
                      final item = {...data, 'id': vacancies[index].id};

                      return _buildVacancyCard(item)
                          .animate(delay: (index * 70).ms)
                          .fadeIn(duration: 400.ms, curve: Curves.easeOut)
                          .slideY(begin: 0.15, end: 0, curve: Curves.easeOut);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentHeader(String? uid) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) return const SizedBox(height: 100);
        final data = snapshot.data!.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppTheme.primaryGreen, Color(0xFF1B5E20)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.4),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white24,
                    child: Text(
                      data['name']?[0] ?? 'U',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['name'] ?? 'Usuario',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Ing. Sistemas Computacionales',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        Text(data['gpa']?.toString() ?? '0.0', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Text('Promedio', style: GoogleFonts.inter(color: Colors.white60, fontSize: 9)),
                      ],
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Progreso Académico', style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500)),
                  Text('75%', style: GoogleFonts.inter(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: 0.75,
                  backgroundColor: Colors.white24,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryChip(String category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(category, style: GoogleFonts.inter(color: isSelected ? Colors.white : AppTheme.accentColor, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        onSelected: (val) => setState(() => _selectedCategory = category),
        backgroundColor: Colors.white.withOpacity(0.08),
        selectedColor: AppTheme.primaryGreen,
        shape: StadiumBorder(side: BorderSide(color: isSelected ? AppTheme.primaryGreen : Colors.white.withOpacity(0.18))),
      ),
    );
  }

  Widget _buildVacancyCard(Map<String, dynamic> v) {
    return GlassmorphicCard(
      glowColor: AppTheme.primaryGreen,
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => VacancyDetailPage(vacancy: v))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.business_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(v['puesto'] ?? 'Vacante', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 15.5, color: Colors.white)),
                const SizedBox(height: 2),
                Text('${v['empresa'] ?? 'Empresa'} • ${v['ubicacion'] ?? 'Remoto'}', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(v['tipo'] ?? 'Servicio Social', style: GoogleFonts.inter(fontSize: 11.5, color: AppTheme.accentColor, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white60),
        ],
      ),
    );
  }

  Widget _buildShimmerSkeletonList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 4,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.white.withOpacity(0.08),
          highlightColor: Colors.white.withOpacity(0.18),
          child: Container(
            height: 90,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        );
      },
    );
  }
}
