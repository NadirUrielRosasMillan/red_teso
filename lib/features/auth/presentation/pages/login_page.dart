import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/features/auth/presentation/pages/register_page.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/admin/presentation/pages/admin_dashboard_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AnimationController _buttonController;
  late final AnimationController _entranceController;
  late final AnimationController _orbitController;
  late final AnimationController _pulseController;
  late final AnimationController _ambientController;
  late final Animation<double> _logoEntry;
  late final Animation<double> _brandFade;
  late final Animation<Offset> _brandSlide;
  late final Animation<double> _cardFade;
  late final Animation<Offset> _cardSlide;

  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  int _logoTapCount = 0;
  Timer? _logoTapResetTimer;

  static const Color _bgWhite = Colors.white;
  static const Color _greenPrimary = Color(0xFF0B5D3B);
  static const Color _greenSecondary = Color(0xFF1E8449);
  static const Color _greenLight = Color(0xFFA8D5A2);
  static const Color _textDark = Color(0xFF0B5D3B);
  static const Color _textMuted = Color(0xFF6B7280);

  @override
  void initState() {
    super.initState();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1150),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    )..repeat(reverse: true);
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _logoEntry = Tween<double>(begin: .72, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, .72, curve: Curves.easeOutBack),
      ),
    );
    _brandFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(.12, .75, curve: Curves.easeOut),
    );
    _brandSlide = Tween<Offset>(
      begin: const Offset(0, .12),
      end: Offset.zero,
    ).animate(_brandFade);
    _cardFade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(.16, .56, curve: Curves.easeOut),
    );
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, .1),
      end: Offset.zero,
    ).animate(_cardFade);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _logoTapResetTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _buttonController.dispose();
    _entranceController.dispose();
    _orbitController.dispose();
    _pulseController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _handleLogoTap() {
    _logoTapCount++;
    _logoTapResetTimer?.cancel();
    _logoTapResetTimer = Timer(const Duration(seconds: 2), () {
      _logoTapCount = 0;
    });

    if (_logoTapCount >= 3) {
      _logoTapCount = 0;
      _logoTapResetTimer?.cancel();
      _showAdminAccessDialog();
    }
  }

  Future<void> _showAdminAccessDialog() async {
    final authorized = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (_) => const _AdminAccessDialog(),
    );

    if (!mounted || authorized != true) return;

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
    );
  }

  Future<void> _login() async {
    if (_isSubmitting) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa tu correo y contraseña.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final auth = context.read<AuthProvider>();
      final String? errorMessage = await auth.signIn(email, password);

      if (!mounted) return;

      // AuthProvider.signIn devuelve el error como String?; no siempre lanza
      // una excepción. Mostrarlo era necesario para que el usuario supiera
      // por qué no avanzaba.
      if (errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFFC8323C), // Danger color
            duration: const Duration(seconds: 5),
          ),
        );
        return;
      }

      if (auth.userType == UserType.none) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'La sesión se validó, pero no se encontró un perfil válido. '
              'Verifica el tipo de usuario en Firestore.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e, stackTrace) {
      debugPrint('Error inesperado al iniciar sesión: $e\n$stackTrace');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo iniciar sesión: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFFC8323C),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _openRegister() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RegisterPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgWhite,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Colors.white),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: AnimatedBuilder(
                animation: _ambientController,
                builder: (context, _) => CustomPaint(
                  painter: _LoginGreenBackgroundPainter(
                    progress: _ambientController.value,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: isWide ? 1080 : 470,
                    ),
                    child: ListView(
                      padding: EdgeInsets.symmetric(
                        horizontal: isWide ? 24 : 18,
                        vertical: 22,
                      ),
                      children: [
                        _buildBrand(compact: isWide),
                        const SizedBox(height: 24),
                        Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 480),
                            child: FadeTransition(
                              opacity: _cardFade,
                              child: SlideTransition(
                                position: _cardSlide,
                                child: _buildLoginCard(),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _reveal(7, _buildFooter()),
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

  Widget _reveal(int order, Widget child) {
    final start = (.25 + order * .075).clamp(0.0, .9).toDouble();
    final end = (start + .34).clamp(.01, 1.0).toDouble();
    final animation = CurvedAnimation(
      parent: _entranceController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, .1),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  // Diseño para celular
  Widget _buildMobileLayout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBrand(),
        const SizedBox(height: 34),
        _buildLoginCard(),
        const SizedBox(height: 24),
        _buildFooter(),
      ],
    );
  }

  // Diseño de dos columnas para laptop
  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBrand(compact: true),
                const SizedBox(height: 42),
                Text(
                  'Tu siguiente\ncapítulo comienza aquí.',
                  style: GoogleFonts.spaceGrotesk(
                    color: _textDark,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Descubre oportunidades, conecta con empresas '
                  'y construye el futuro profesional que imaginas.',
                  style: GoogleFonts.inter(
                    color: _textMuted,
                    fontSize: 16,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                _buildFeature(
                  Icons.rocket_launch_rounded,
                  'Impulsa tu talento',
                ),
                const SizedBox(height: 16),
                _buildFeature(
                  Icons.hub_rounded,
                  'Conecta con nuevas oportunidades',
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: 420,
          child: _buildLoginCard(),
        ),
      ],
    );
  }

  Widget _buildBrand({bool compact = false}) {
    const logoWidth = 184.0;
    const logoHeight = 150.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeTransition(
          opacity: _brandFade,
          child: ScaleTransition(
            scale: _logoEntry,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) => Transform.scale(
                scale: .985 + _pulseController.value * .015,
                child: Transform.rotate(
                  angle: math.sin(_pulseController.value * math.pi) * .025,
                  child: child,
                ),
              ),
              child: GestureDetector(
                onTap: _handleLogoTap,
                child: AnimatedBuilder(
                  animation: _orbitController,
                  builder: (context, _) {
                    final angle = _orbitController.value * math.pi * 2;
                    const orbitRotation = -.28;
                    return SizedBox(
                      width: logoWidth,
                      height: logoHeight,
                      child: Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          ShaderMask(
                            blendMode: BlendMode.srcIn,
                            shaderCallback: (bounds) => const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFFB8E986),
                                Color(0xFF28A85B),
                                Color(0xFF075C3B),
                              ],
                            ).createShader(bounds),
                            child: Text(
                              'N',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 112,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -10,
                                shadows: [
                                  Shadow(
                                    color: _greenPrimary.withValues(alpha: .2),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned.fill(
                            child: CustomPaint(
                              painter: _NexumOrbitPainter(
                                progress: _orbitController.value,
                              ),
                            ),
                          ),
                          ...List.generate(3, (index) {
                            final nodeAngle =
                                angle + index * math.pi * 2 / 3;
                            const radiusX = 76.0;
                            const radiusY = 31.0;
                            final orbitX = radiusX * math.cos(nodeAngle);
                            final orbitY = radiusY * math.sin(nodeAngle);
                            final nodeX = orbitX * math.cos(orbitRotation) -
                                orbitY * math.sin(orbitRotation);
                            final nodeY = orbitX * math.sin(orbitRotation) +
                                orbitY * math.cos(orbitRotation);
                            final icon = switch (index) {
                              0 => Icons.work_rounded,
                              1 => Icons.school_rounded,
                              _ => Icons.lightbulb_outline_rounded,
                            };

                            return Positioned(
                              left: logoWidth / 2 + nodeX - 18,
                              top: logoHeight / 2 + nodeY - 18,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF2E9D5C),
                                      Color(0xFF075C3B),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _greenPrimary.withValues(
                                        alpha: .22,
                                      ),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: index == 2
                                    ? Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Icon(
                                            icon,
                                            color: Colors.white,
                                            size: 21,
                                          ),
                                          const Positioned(
                                            right: 2,
                                            bottom: 2,
                                            child: Icon(
                                              Icons.settings_rounded,
                                              color: Colors.white,
                                              size: 11,
                                            ),
                                          ),
                                        ],
                                      )
                                    : Icon(
                                        icon,
                                        color: Colors.white,
                                        size: 20,
                                      ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 15),
        FadeTransition(
          opacity: _brandFade,
          child: SlideTransition(
            position: _brandSlide,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'NEXUM',
                  style: GoogleFonts.spaceGrotesk(
                    color: _textDark,
                    fontSize: compact ? 42 : 38,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'TU TALENTO ABRE PUERTAS',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: _greenPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _greenLight.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _greenPrimary.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _reveal(
                0,
                Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                    color: _greenPrimary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _reveal(
                1,
                Text(
                  '¡Bienvenido!',
                  style: GoogleFonts.plusJakartaSans(
                    color: _textDark,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              _reveal(
                2,
                Text(
                  'Ingresa con tu matrícula (Alumno), número de empleado (Profesor) o correo (Empresa).',
                  style: GoogleFonts.inter(
                    color: _textMuted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              _reveal(
                3,
                _buildInput(
                  controller: _emailController,
                  label: 'Usuario o Correo',
                  hint: 'matrícula / empleado / correo',
                  icon: Icons.person_outline_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
              ),
              const SizedBox(height: 20),
              _reveal(
                4,
                _buildInput(
                  controller: _passwordController,
                  label: 'Contraseña',
                  hint: 'Ingresa tu contraseña',
                  icon: Icons.lock_outline_rounded,
                  obscureText: !_isPasswordVisible,
                  suffix: IconButton(
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: _textMuted,
                      size: 21,
                    ),
                  ),
                  onSubmitted: (_) => _login(),
                ),
              ),
              const SizedBox(height: 36),
              _reveal(
                5,
                Consumer<AuthProvider>(
                  builder: (context, auth, child) {
                    return AnimatedBuilder(
                      animation: _buttonController,
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _buttonController.value,
                          child: SizedBox(
                            width: double.infinity,
                            height: 58,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [
                                    _greenSecondary,
                                    _greenPrimary,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: _greenPrimary.withValues(alpha: 0.35),
                                    blurRadius: 15,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: auth.isLoading
                                    ? null
                                    : () async {
                                        await _buttonController.reverse();
                                        await _buttonController.forward();
                                        if (mounted) await _login();
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  disabledBackgroundColor: Colors.white24,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: auth.isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.5,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            'INICIAR SESIÓN',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 21,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              _reveal(
                6,
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        '¿Nuevo en la comunidad? ',
                        style: GoogleFonts.inter(
                          color: _textMuted,
                          fontSize: 12,
                        ),
                      ),
                      TextButton(
                        onPressed: _openRegister,
                        style: TextButton.styleFrom(
                          foregroundColor: _greenPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'Regístrate aquí',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    Widget? suffix,
    TextInputType? keyboardType,
    ValueChanged<String>? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: _textDark,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              onSubmitted: onSubmitted,
              style: GoogleFonts.inter(
                color: _textDark,
                fontSize: 14,
              ),
              cursorColor: _greenPrimary,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  color: _textMuted.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  icon,
                  color: _greenPrimary,
                  size: 20,
                ),
                suffixIcon: suffix,
                filled: true,
                fillColor: const Color(0xFF6B7280).withValues(alpha: 0.06),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _greenPrimary.withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _greenPrimary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _greenPrimary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _greenPrimary.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            icon,
            color: _greenPrimary,
            size: 21,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: _textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      'PLATAFORMA ACADÉMICA TESOEM',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
        color: _textMuted.withValues(alpha: 0.6),
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );
  }
}

class _NexumOrbitPainter extends CustomPainter {
  final double progress;

  const _NexumOrbitPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbit = Rect.fromCenter(
      center: center,
      width: size.width * .9,
      height: size.height * .44,
    );
    final rotation = -.28;
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    final localOrbit = orbit.shift(-center);
    canvas.drawOval(
      localOrbit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xFF1E8449).withValues(alpha: .55),
    );
    canvas.drawArc(
      localOrbit,
      math.pi * (.08 + progress * .28),
      math.pi * .72,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 4
        ..color = const Color(0xFFA8D5A2).withValues(alpha: .9),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _NexumOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _LoginGreenBackgroundPainter extends CustomPainter {
  final double progress;

  const _LoginGreenBackgroundPainter({required this.progress});

  static const _deepGreen = Color(0xFF0B5D3B);
  static const _midGreen = Color(0xFF1E8449);
  static const _softGreen = Color(0xFFA8D5A2);

  @override
  void paint(Canvas canvas, Size size) {
    // Large, soft organic shapes stay at the edges so the login remains clear.
    final topRight = Path()
      ..moveTo(size.width * 0.72, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * 0.34)
      ..cubicTo(
        size.width * 0.88,
        size.height * 0.28,
        size.width * 0.82,
        size.height * 0.14,
        size.width * 0.72,
        0,
      )
      ..close();
    canvas.drawPath(
      topRight,
      Paint()..color = _softGreen.withValues(alpha: 0.42),
    );

    final bottomLeft = Path()
      ..moveTo(0, size.height * 0.68)
      ..cubicTo(
        size.width * 0.13,
        size.height * 0.72,
        size.width * 0.19,
        size.height * 0.86,
        size.width * 0.35,
        size.height,
      )
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      bottomLeft,
      Paint()..color = _softGreen.withValues(alpha: 0.48),
    );

    final accent = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = _midGreen.withValues(alpha: 0.2);
    final upperArc = Path()
      ..moveTo(size.width * 0.76, 0)
      ..cubicTo(
        size.width * 0.84,
        size.height * 0.10,
        size.width * 0.92,
        size.height * 0.14,
        size.width,
        size.height * 0.13,
      );
    final lowerArc = Path()
      ..moveTo(0, size.height * 0.82)
      ..cubicTo(
        size.width * 0.12,
        size.height * 0.85,
        size.width * 0.18,
        size.height * 0.95,
        size.width * 0.26,
        size.height,
      );
    canvas
      ..drawPath(upperArc, accent)
      ..drawPath(lowerArc, accent);

    final drift = math.sin(progress * math.pi * 2);
    final dotPaint = Paint()..color = _deepGreen.withValues(alpha: 0.2);
    canvas
      ..drawCircle(
        Offset(size.width * 0.91, size.height * (0.25 + drift * .025)),
        4,
        dotPaint,
      )
      ..drawCircle(
        Offset(size.width * 0.83, size.height * (0.20 - drift * .018)),
        2.5,
        dotPaint,
      )
      ..drawCircle(
        Offset(size.width * 0.13, size.height * (0.78 - drift * .022)),
        3,
        dotPaint,
      );
  }

  @override
  bool shouldRepaint(covariant _LoginGreenBackgroundPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _AdminAccessDialog extends StatefulWidget {
  const _AdminAccessDialog();

  @override
  State<_AdminAccessDialog> createState() => _AdminAccessDialogState();
}

class _AdminAccessDialogState extends State<_AdminAccessDialog> {
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  static const Color _bgDark = Color(0xFF0B5D3B);
  static const Color _greenLight = Color(0xFFA8D5A2);

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_passwordController.text == '2026') {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _errorMessage = 'Contraseña incorrecta.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      scrollable: true,
      backgroundColor: _bgDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _greenLight.withValues(alpha: 0.35)),
      ),
      title: Row(
        children: [
          const Icon(Icons.admin_panel_settings_rounded, color: _greenLight),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Acceso administrador',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresa la contraseña administrativa.',
            style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _passwordController,
            autofocus: true,
            obscureText: _obscurePassword,
            style: GoogleFonts.inter(color: Colors.white),
            onSubmitted: (_) => _submit(),
            decoration: InputDecoration(
              hintText: 'Contraseña',
              hintStyle: GoogleFonts.inter(color: Colors.white38),
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: _greenLight),
              suffixIcon: IconButton(
                onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: Colors.white60,
                ),
              ),
              filled: true,
              fillColor: const Color(0xFF6B7280).withValues(alpha: 0.24),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _greenLight, width: 1.4),
              ),
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              _errorMessage!,
              style: GoogleFonts.inter(color: Colors.redAccent, fontSize: 12),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            'Cancelar',
            style: GoogleFonts.inter(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _greenLight,
            foregroundColor: _bgDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: _submit,
          child: Text(
            'ENTRAR',
            style: GoogleFonts.inter(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}
