
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' hide AuthProvider;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import 'package:red_teso/core/widgets/notification_bell.dart';
import 'package:red_teso/features/student/presentation/pages/vacancy_detail_page.dart';
import 'package:red_teso/features/student/presentation/widgets/ai_vacancy_assistant_modal.dart';

class StudentHomePage extends StatefulWidget {
  const StudentHomePage({super.key});

  @override
  State<StudentHomePage> createState() => _StudentHomePageState();
}

class _StudentHomePageState extends State<StudentHomePage> {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _selectedCategory = 'Todos';

  static const Color _background = Color(0xFFF8F1E8);
  static const Color _wine = Color(0xFF741C3D);
  static const Color _wineLight = Color(0xFF9D3458);
  static const Color _gold = Color(0xFFE6B968);
  static const Color _text = Color(0xFF3A1725);
  static const Color _muted = Color(0xFF75636B);
  static const Color _border = Color(0xFFE8DDE1);

  final List<String> _categories = const [
    'Todos',
    'Servicio Social',
    'Residencias',
    'Empleo Egresados',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _wine,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 39,
              height: 39,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_gold, Color(0xFFFFDDA0)],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.hub_rounded,
                color: _wine,
                size: 25,
              ),
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RedTESO',
                  style: GoogleFonts.outfit(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                Text(
                  'PORTAL ESTUDIANTIL',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.7,
                    color: _gold,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: const [
          NotificationBell(color: Colors.white),
          SizedBox(width: 15),
        ],
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 90),
        child: Tooltip(
          message: 'Abre el asistente de IA para explorar oportunidades',
          child: FloatingActionButton.extended(
            heroTag: 'student_ai_assistant',
            onPressed: () => AiVacancyAssistantModal.show(context),
            backgroundColor: _wine,
            foregroundColor: _gold,
            elevation: 7,
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text(
              'Asistente IA',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ).animate().scale(
            delay: 200.ms,
            duration: 400.ms,
            curve: Curves.easeOutBack,
          ),

      body: Stack(
        children: [
          const Positioned.fill(
            child: CustomPaint(
              painter: _AmbientPainter(),
            ),
          ),
          SafeArea(
            top: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 850;

                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      children: [
                        _buildStudentHeader(user?.uid, wide)
                            .animate()
                            .fadeIn(duration: 400.ms),

                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 28 : 18,
                            17,
                            wide ? 28 : 18,
                            10,
                          ),
                          child: _buildSearch(),
                        ),

                        SizedBox(
                          height: 43,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.symmetric(
                              horizontal: wide ? 28 : 18,
                            ),
                            children: _categories
                                .map(_buildCategoryChip)
                                .toList(),
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            wide ? 28 : 20,
                            17,
                            wide ? 28 : 20,
                            10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 5,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _wine,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Oportunidades para ti',
                                      style: GoogleFonts.outfit(
                                        color: _text,
                                        fontSize: wide ? 25 : 22,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'El siguiente paso de tu carrera comienza aquí.',
                                      style: GoogleFonts.inter(
                                        color: _muted,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  border: Border.all(color: _border),
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Icon(
                                  Icons.work_outline_rounded,
                                  color: _wine,
                                  size: 21,
                                ),
                              ),
                            ],
                          ),
                        ),

                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _db.collection('vacancies').snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.hasError) {
                                return _buildEmpty(
                                  icon: Icons.cloud_off_rounded,
                                  title: 'No pudimos cargar las vacantes',
                                  subtitle:
                                      'Comprueba tu conexión e inténtalo de nuevo.',
                                );
                              }

                              if (!snapshot.hasData) {
                                return _buildLoading();
                              }

                              final docs = snapshot.data!.docs.toList();

                              docs.sort((a, b) {
                                final aData =
                                    a.data() as Map<String, dynamic>;
                                final bData =
                                    b.data() as Map<String, dynamic>;

                                final aTime =
                                    aData['createdAt'] as Timestamp?;
                                final bTime =
                                    bData['createdAt'] as Timestamp?;

                                if (aTime == null && bTime == null) return 0;
                                if (aTime == null) return 1;
                                if (bTime == null) return -1;

                                return bTime.compareTo(aTime);
                              });

                              final search =
                                  _searchController.text.trim().toLowerCase();

                              final vacancies = docs.where((doc) {
                                final data =
                                    doc.data() as Map<String, dynamic>;

                                final type =
                                    (data['tipo'] ?? '').toString();
                                final title = (data['puesto'] ?? '')
                                    .toString()
                                    .toLowerCase();
                                final company = (data['empresa'] ?? '')
                                    .toString()
                                    .toLowerCase();

                                final matchesCategory =
                                    _selectedCategory == 'Todos' ||
                                        type == _selectedCategory;

                                final matchesSearch =
                                    title.contains(search) ||
                                        company.contains(search);

                                return matchesCategory && matchesSearch;
                              }).toList();

                              if (vacancies.isEmpty) {
                                return _buildEmpty(
                                  icon: Icons.travel_explore_rounded,
                                  title: 'No encontramos coincidencias',
                                  subtitle:
                                      'Prueba otra búsqueda o cambia de categoría.',
                                  action: TextButton.icon(
                                    onPressed: () {
                                      setState(() {
                                        _searchController.clear();
                                        _selectedCategory = 'Todos';
                                      });
                                    },
                                    icon: const Icon(
                                      Icons.refresh_rounded,
                                      color: _wine,
                                    ),
                                    label: Text(
                                      'Limpiar filtros',
                                      style: GoogleFonts.inter(
                                        color: _wine,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                );
                              }

                              return ListView.builder(
                                padding: EdgeInsets.fromLTRB(
                                  wide ? 28 : 18,
                                  0,
                                  wide ? 28 : 18,
                                  150,
                                ),
                                itemCount: vacancies.length,
                                itemBuilder: (context, index) {
                                  final data = vacancies[index].data()
                                      as Map<String, dynamic>;

                                  final vacancy = {
                                    ...data,
                                    'id': vacancies[index].id,
                                  };

                                  return _buildVacancyCard(vacancy)
                                      .animate(
                                        delay: (index.clamp(0, 8) * 45).ms,
                                      )
                                      .fadeIn(duration: 300.ms)
                                      .slideY(begin: 0.04, end: 0);
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentHeader(String? uid, bool wide) {
    if (uid == null) return _welcomeBanner('Estudiante');

    return StreamBuilder<DocumentSnapshot>(
      stream: _db.collection('users').doc(uid).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError ||
            !snapshot.hasData ||
            !snapshot.data!.exists) {
          return _welcomeBanner('Estudiante');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = (data['name'] ?? 'Estudiante').toString().trim();
        final firstName =
            name.isEmpty ? 'Estudiante' : name.split(' ').first;

        return Container(
          margin: EdgeInsets.fromLTRB(
            wide ? 28 : 18,
            10,
            wide ? 28 : 18,
            0,
          ),
          padding: EdgeInsets.all(wide ? 21 : 17),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF8C2349),
                Color(0xFF741C3D),
                Color(0xFF4C102B),
              ],
            ),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: _gold.withValues(alpha: 0.6),
            ),
            boxShadow: [
              BoxShadow(
                color: _wine.withValues(alpha: 0.16),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.13),
                  border: Border.all(color: _gold, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    firstName[0].toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '¡Hola, $firstName!',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: wide ? 24 : 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Es un buen día para avanzar.',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Text(
                      'TU FUTURO PROFESIONAL EMPIEZA HOY',
                      style: GoogleFonts.inter(
                        color: _gold,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                    if (data['gpa'] != null) ...[
                      const SizedBox(height: 7),
                      Text(
                        'Promedio académico: ${data['gpa']}',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.school_rounded,
                color: _gold,
                size: 30,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _welcomeBanner(String name) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_wineLight, _wine],
        ),
        borderRadius: BorderRadius.circular(23),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.waving_hand_rounded,
            color: _gold,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '¡Bienvenido, $name!',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearch() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _wine.withValues(alpha: 0.07),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.inter(
          color: _text,
          fontSize: 13,
        ),
        cursorColor: _wine,
        decoration: InputDecoration(
          hintText: 'Busca puestos, empresas...',
          hintStyle: GoogleFonts.inter(
            color: _muted,
            fontSize: 12,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: _wine,
          ),
          suffixIcon: _searchController.text.isEmpty
              ? null
              : IconButton(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                  icon: const Icon(
                    Icons.close_rounded,
                    color: _muted,
                  ),
                ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(17),
            borderSide: const BorderSide(
              color: _wine,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final selected = _selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 9),
      child: FilterChip(
        showCheckmark: false,
        selected: selected,
        onSelected: (_) {
          setState(() => _selectedCategory = category);
        },
        backgroundColor: Colors.white,
        selectedColor: _wine,
        side: BorderSide(
          color: selected ? _wine : _border,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(13),
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 7,
        ),
        label: Text(
          category,
          style: GoogleFonts.inter(
            color: selected ? Colors.white : _wine,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildVacancyCard(Map<String, dynamic> vacancy) {
    final title = (vacancy['puesto'] ?? 'Vacante').toString();
    final company = (vacancy['empresa'] ?? 'Empresa').toString();
    final location =
        (vacancy['ubicacion'] ?? 'Ubicación por confirmar').toString();
    final type =
        (vacancy['tipo'] ?? 'Oportunidad profesional').toString();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VacancyDetailPage(vacancy: vacancy),
              ),
            );
          },
          child: Ink(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: _border),
              boxShadow: [
                BoxShadow(
                  color: _wine.withValues(alpha: 0.07),
                  blurRadius: 17,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 53,
                        height: 53,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [_wineLight, _wine],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          _vacancyIcon(type),
                          color: _gold,
                          size: 27,
                        ),
                      ),
                      const SizedBox(width: 13),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                color: _text,
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              company,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                color: _muted,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_outward_rounded,
                        color: _wine,
                        size: 21,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTag(Icons.work_outline_rounded, type, true),
                      _buildTag(
                        Icons.location_on_outlined,
                        location,
                        false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Divider(height: 1, color: _border),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: Color(0xFFB47A22),
                        size: 18,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'Descubre esta oportunidad',
                          style: GoogleFonts.inter(
                            color: _muted,
                            fontSize: 10,
                          ),
                        ),
                      ),
                      Text(
                        'Ver vacante →',
                        style: GoogleFonts.inter(
                          color: _wine,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  IconData _vacancyIcon(String type) {
    final value = type.toLowerCase();

    if (value.contains('social')) {
      return Icons.volunteer_activism_rounded;
    }
    if (value.contains('residencia')) {
      return Icons.school_rounded;
    }
    if (value.contains('empleo') || value.contains('egresado')) {
      return Icons.business_center_rounded;
    }

    return Icons.work_rounded;
  }

  Widget _buildTag(IconData icon, String label, bool highlighted) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 260),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? const Color(0xFFFFF2D8)
            : const Color(0xFFF7F2F3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlighted ? _gold : _border,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: highlighted ? _wine : _muted,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                color: highlighted ? _wine : _muted,
                fontSize: 10,
                fontWeight:
                    highlighted ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? action,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: math.max(0, constraints.maxHeight - 40),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFFFE8CF),
                          Color(0xFFFFF8EF),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: _gold),
                    ),
                    child: Icon(icon, color: _wine, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: _text,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: _muted,
                      fontSize: 12,
                      height: 1.6,
                    ),
                  ),
                  if (action != null) ...[
                    const SizedBox(height: 10),
                    action,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      itemCount: 3,
      itemBuilder: (_, __) {
        return Shimmer.fromColors(
          baseColor: const Color(0xFFE8DDE1),
          highlightColor: Colors.white,
          child: Container(
            height: 135,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
            ),
          ),
        );
      },
    );
  }
}

class _AmbientPainter extends CustomPainter {
  const _AmbientPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFF9F1),
            Color(0xFFF7EEE5),
            Color(0xFFF1E4DD),
          ],
        ).createShader(rect),
    );

    _glow(
      canvas,
      Offset(size.width * 0.95, size.height * 0.18),
      size.width * 0.45,
      const Color(0x289D3458),
    );

    _glow(
      canvas,
      Offset(size.width * 0.05, size.height * 0.78),
      size.width * 0.48,
      const Color(0x28E6B968),
    );

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = const Color(0x24741C3D);

    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.15),
      size.width * 0.18,
      ringPaint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.95, size.height * 0.15),
      size.width * 0.23,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x20B47A22),
    );

    final dotPaint = Paint()..color = const Color(0x66B47A22);

    for (int i = 0; i < 26; i++) {
      final x = ((i * 83 + 29) % 997) / 997 * size.width;
      final y = ((i * 137 + 47) % 991) / 991 * size.height;

      canvas.drawCircle(
        Offset(x, y),
        i % 4 == 0 ? 1.8 : 1,
        dotPaint,
      );
    }
  }

  void _glow(Canvas canvas, Offset center, double radius, Color color) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0),
          ],
        ).createShader(
          Rect.fromCircle(
            center: center,
            radius: radius,
          ),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _AmbientPainter oldDelegate) => false;
}
