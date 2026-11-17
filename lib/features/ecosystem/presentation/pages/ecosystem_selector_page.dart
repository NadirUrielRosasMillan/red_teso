import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/courses/presentation/pages/course_catalog_page.dart';
import 'package:red_teso/features/student/presentation/pages/student_dashboard_page.dart';
import 'package:red_teso/features/company/presentation/pages/company_dashboard_page.dart';

class EcosystemSelectorPage extends StatefulWidget {
  const EcosystemSelectorPage({super.key});

  @override
  State<EcosystemSelectorPage> createState() => _EcosystemSelectorPageState();
}
class _EcosystemSelectorPageState extends State<EcosystemSelectorPage> {
  late final PageController _controller;
  int _selectedIndex = 0;

  final List<_Experience> _experiences = const [
    _Experience(
      id: 'talento',
      title: 'ÁGORA Talento',
      eyebrow: 'BOLSA DE TRABAJO',
      subtitle: 'Conecta con tu próxima oportunidad.',
      description:
          'Encuentra vacantes, presenta tu perfil y conecta con empresas.',
      icon: Icons.work_rounded,
      image: 'assets/images/experiences/talento.png',
      colors: [Color(0xFF12366A), Color(0xFF2467B5)],
      available: true,
    ),
    _Experience(
      id: 'aprende',
      title: 'ÁGORA Aprende',
      eyebrow: 'CURSOS Y HABILIDADES',
      subtitle: 'Aprende. Crece. Evoluciona.',
      description:
          'Explora cursos prácticos y desarrolla habilidades para tu futuro.',
      icon: Icons.school_rounded,
      image: 'assets/images/experiences/aprende.png',
      colors: [Color(0xFF147A9D), Color(0xFF61BFEA)],
      available: true,
    ),
    _Experience(
      id: 'impulsa',
      title: 'ÁGORA Impulsa',
      eyebrow: 'CÓDIGO COLABORATIVO',
      subtitle: 'Comparte código. Impulsa ideas.',
      description:
          'Dona o adopta código para ayudar a crecer proyectos de la comunidad.',
      icon: Icons.rocket_launch_rounded,
      image: 'assets/images/experiences/impulsa.png',
      colors: [Color(0xFF157C83), Color(0xFF5EBF9C)],
      available: false,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.78);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _openExperience(_Experience experience, UserType userType) {
    if (!experience.available) return;

    final Widget destination;
    if (experience.id == 'talento') {
      destination = userType == UserType.empresa
          ? const CompanyDashboardPage()
          : const StudentDashboardPage();
    } else if (experience.id == 'aprende') {
      destination = const CourseCatalogPage();
    } else {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  List<_Experience> _visibleExperiences(UserType userType) {
    if (userType == UserType.empresa) {
      return _experiences.where((item) => item.id != 'impulsa').toList();
    }
    if (userType == UserType.alumno || userType == UserType.profesor) {
      return _experiences;
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final userType = authProvider.userType;
    final experiences = _visibleExperiences(userType);

    if (experiences.isEmpty) {
      return const Scaffold(
        backgroundColor: Color(0xFF071A36),
        body: Center(
          child: Text(
            'No tienes experiencias disponibles.',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final selectedIndex = _selectedIndex.clamp(0, experiences.length - 1);
    final selected = experiences[selectedIndex];
    final greeting = switch (userType) {
      UserType.profesor => 'docente',
      UserType.empresa => 'empresa',
      _ => 'estudiante',
    };
    final isWide = MediaQuery.sizeOf(context).width >= 940;

    return Scaffold(
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF092B57),
              Color(0xFF174E87),
              Color(0xFFB9D7F3),
              Color(0xFFFFFFFF),
            ],
            stops: [0, .28, .68, 1],
          ),
        ),
        child: Stack(
          children: [
            SafeArea(
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildIntro(greeting),
                  const SizedBox(height: 18),
                  Expanded(
                    child: isWide
                        ? _buildDesktopCards(experiences, selected, userType)
                        : _buildMobileCards(experiences, selected, userType),
                  ),
                  const SizedBox(height: 8),
                  _buildPageIndicators(experiences, selectedIndex),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      isWide ? 32 : 20,
                      14,
                      isWide ? 32 : 20,
                      18,
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton.icon(
                        onPressed: selected.available
                            ? () => _openExperience(selected, userType)
                            : null,
                        icon: Icon(
                          selected.available
                              ? Icons.play_arrow_rounded
                              : Icons.lock_outline_rounded,
                          size: 24,
                        ),
                        label: Text(
                          selected.available
                              ? 'ENTRAR A ${selected.title.toUpperCase()}'
                              : 'ÁGORA IMPULSA · PRÓXIMAMENTE',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            letterSpacing: .8,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF6AD7FF),
                          disabledBackgroundColor:
                              Colors.white.withValues(alpha: .16),
                          foregroundColor: const Color(0xFF071A36),
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: .65),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 18, 4),
      child: Row(
        children: [
          Image.asset(
            'assets/images/branding/agora_icono_app.png',
            width: 58,
            height: 58,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.hub_rounded,
              color: Color(0xFF6AD7FF),
              size: 46,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ÁGORA',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 23,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'ECOSISTEMA UNIVERSITARIO',
                  style: TextStyle(
                    color: Color(0xFFB7D8FF),
                    fontSize: 9,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton.filledTonal(
            tooltip: 'Cerrar sesión',
            onPressed: () => context.read<AuthProvider>().logout(),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: .12),
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildIntro(String greeting) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22),
      child: Column(
        children: [
          Text(
            '¡Bienvenido, $greeting!',
            style: const TextStyle(
              color: Color(0xFFB7D8FF),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'ELIGE TU SIGUIENTE PASO',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Tres experiencias. Un solo ecosistema.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopCards(
    List<_Experience> experiences,
    _Experience selected,
    UserType userType,
  ) {
    final selectedPosition = experiences.indexOf(selected);
    final displayOrder = experiences.length == 3
        ? [
            experiences[(selectedPosition + 1) % 3],
            selected,
            experiences[(selectedPosition + 2) % 3],
          ]
        : experiences;

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var index = 0; index < displayOrder.length; index++) ...[
            if (index > 0) const SizedBox(width: 14),
            Expanded(
              child: _ExperienceCard(
                experience: displayOrder[index],
                selected: displayOrder[index].id == selected.id,
                compact: false,
                onTap: () {
                  if (displayOrder[index].id == selected.id) {
                    _openExperience(displayOrder[index], userType);
                  } else {
                    setState(() {
                      _selectedIndex = experiences.indexOf(displayOrder[index]);
                    });
                  }
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMobileCards(
    List<_Experience> experiences,
    _Experience selected,
    UserType userType,
  ) {
    final currentIndex = experiences.indexOf(selected);
    return PageView.builder(
      controller: _controller,
      itemCount: experiences.length,
      onPageChanged: (index) => setState(() => _selectedIndex = index),
      itemBuilder: (context, index) {
        final experience = experiences[index];
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            var page = 0.0;
            if (_controller.hasClients && _controller.position.haveDimensions) {
              page = (_controller.page ?? currentIndex.toDouble()) - index;
            }
            final scale = (1 - page.abs() * .12).clamp(.84, 1.0).toDouble();
            return Transform.scale(scale: scale, child: child);
          },
          child: _ExperienceCard(
            experience: experience,
            selected: index == currentIndex,
            compact: true,
            onTap: () {
              if (index == currentIndex) {
                _openExperience(experience, userType);
              } else {
                _controller.animateToPage(
                  index,
                  duration: const Duration(milliseconds: 380),
                  curve: Curves.easeOutCubic,
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildPageIndicators(
      List<_Experience> experiences, int selectedIndex) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        experiences.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: index == selectedIndex ? 26 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: index == selectedIndex
                ? const Color(0xFF6AD7FF)
                : Colors.white.withValues(alpha: .38),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

class _Experience {
  final String id;
  final String title;
  final String eyebrow;
  final String subtitle;
  final String description;
  final IconData icon;
  final String image;
  final List<Color> colors;
  final bool available;

  const _Experience({
    required this.id,
    required this.title,
    required this.eyebrow,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.image,
    required this.colors,
    required this.available,
  });
}

class _ExperienceCard extends StatelessWidget {
  final _Experience experience;
  final bool selected;
  final bool compact;
  final VoidCallback onTap;

  const _ExperienceCard({
    required this.experience,
    required this.selected,
    required this.compact,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      margin: EdgeInsets.fromLTRB(
        compact ? 8 : 0,
        selected ? 2 : 28,
        compact ? 8 : 0,
        selected ? 4 : 26,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(selected ? 27 : 23),
        border: Border.all(
          color: selected
              ? const Color(0xFF8DE4FF)
              : Colors.white.withValues(alpha: .46),
          width: selected ? 3 : 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: selected
                ? const Color(0xFF3FC8FF).withValues(alpha: .32)
                : Colors.black.withValues(alpha: .30),
            blurRadius: selected ? 32 : 18,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(selected ? 24 : 21),
        child: Material(
          color: experience.colors.first,
          child: InkWell(
            onTap: onTap,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  experience.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: experience.colors,
                      ),
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: .02),
                        Colors.black.withValues(alpha: .08),
                        const Color(0xFF06162D).withValues(alpha: .58),
                        const Color(0xFF06162D).withValues(alpha: .97),
                      ],
                      stops: const [0, .38, .68, 1],
                    ),
                  ),
                ),
                Positioned(
                  top: 18,
                  left: 18,
                  right: 18,
                  child: Row(
                    children: [
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: .18),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: .40),
                            ),
                          ),
                          child: Text(
                            experience.eyebrow,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: .8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        experience.available
                            ? Icons.arrow_outward_rounded
                            : Icons.lock_outline_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    ],
                  ),
                ),
                Positioned(
                  left: compact ? 19 : 22,
                  right: compact ? 19 : 22,
                  bottom: compact ? 20 : 25,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: selected ? 48 : 40,
                        height: selected ? 48 : 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: .16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          experience.icon,
                          color: Colors.white,
                          size: selected ? 27 : 23,
                        ),
                      ),
                      SizedBox(height: selected ? 13 : 10),
                      Text(
                        experience.title.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: selected ? 22 : 17,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          letterSpacing: .35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        experience.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: selected ? 13 : 11,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (selected) ...[
                        const SizedBox(height: 7),
                        Text(
                          experience.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: .78),
                            fontSize: 11,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: [
                            Icon(
                              experience.available
                                  ? Icons.touch_app_rounded
                                  : Icons.schedule_rounded,
                              color: const Color(0xFF8DE4FF),
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              experience.available
                                  ? 'SELECCIONAR EXPERIENCIA'
                                  : 'PRÓXIMAMENTE',
                              style: const TextStyle(
                                color: Color(0xFF8DE4FF),
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: .7,
                              ),
                            ),
                          ],
                        ),
                      ],
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
}
