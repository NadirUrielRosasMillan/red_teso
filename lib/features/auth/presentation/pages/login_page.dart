
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/auth_provider.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  late final AnimationController _backgroundController;
  late final AnimationController _buttonController;

  bool _isPasswordVisible = false;
  bool _isLoginPressed = false;

  static const Color _wine = Color(0xFF650D2B);
  static const Color _darkWine = Color(0xFF210713);
  static const Color _gold = Color(0xFFE7BD72);
  static const Color _cream = Color(0xFFFFF8EF);

  @override
  void initState() {
    super.initState();

    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _backgroundController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
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

    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).signIn(email, password);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo iniciar sesión: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
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
      backgroundColor: _darkWine,
      body: Stack(
        children: [
          // Fondo animado
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _backgroundController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _PremiumBackgroundPainter(
                    progress: _backgroundController.value,
                  ),
                );
              },
            ),
          ),

          // Contenido principal
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 850;

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 22,
                      vertical: 28,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 1020 : 470,
                      ),
                      child: isWide
                          ? _buildDesktopLayout()
                          : _buildMobileLayout(),
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
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Descubre oportunidades, conecta con empresas '
                  'y construye el futuro profesional que imaginas.',
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 16,
                    height: 1.8,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 94 : 108,
          height: compact ? 94 : 108,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.07),
            border: Border.all(
              color: _gold.withValues(alpha: 0.85),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _gold.withValues(alpha: 0.16),
                blurRadius: 35,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: ClipOval(
              child: Image.asset(
                'web/icons/logo_sis_color.png',
                width: compact ? 68 : 78,
                height: compact ? 68 : 78,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return Icon(
                    Icons.hub_rounded,
                    color: _gold,
                    size: compact ? 48 : 56,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'RedTESO',
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: compact ? 42 : 38,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'TU TALENTO ABRE PUERTAS',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: _gold,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.075),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.16),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: _gold,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Bienvenido!',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión y encuentra tu próxima oportunidad.',
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.68),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 30),

              _buildInput(
                controller: _emailController,
                label: 'Correo electrónico',
                hint: 'nombre@tesoem.mx',
                icon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 20),

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
                    color: Colors.white60,
                    size: 21,
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),

              const SizedBox(height: 30),

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
                                  Color(0xFFF2D69B),
                                  Color(0xFFD8A74F),
                                  Color(0xFFECC780),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(17),
                              boxShadow: [
                                BoxShadow(
                                  color: _gold.withValues(alpha: 0.23),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
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
                                disabledBackgroundColor:
                                    Colors.white24,
                                shadowColor: Colors.transparent,
                                foregroundColor: _darkWine,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(17),
                                ),
                              ),
                              child: auth.isLoading
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: _darkWine,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'INICIAR SESIÓN',
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 13,
                                            letterSpacing: 1.3,
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

              const SizedBox(height: 25),

              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '¿Todavía no tienes cuenta? ',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    TextButton(
                      onPressed: _openRegister,
                      style: TextButton.styleFrom(
                        foregroundColor: _gold,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        'Regístrate',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
          padding: const EdgeInsets.only(left: 3, bottom: 10),
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: _cream,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onSubmitted: onSubmitted,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 14,
          ),
          cursorColor: _gold,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: Colors.white38,
              fontSize: 12,
            ),
            prefixIcon: Icon(
              icon,
              color: _gold,
              size: 21,
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.17),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 19,
              horizontal: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: _gold,
                width: 1.4,
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
            color: _gold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _gold.withValues(alpha: 0.24),
            ),
          ),
          child: Icon(
            icon,
            color: _gold,
            size: 21,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: Colors.white.withValues(alpha: 0.85),
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
        color: Colors.white38,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );
  }
}

class _PremiumBackgroundPainter extends CustomPainter {
  final double progress;

  _PremiumBackgroundPainter({required this.progress});

  static const Color _wine = Color(0xFF650D2B);
  static const Color _darkWine = Color(0xFF210713);
  static const Color _gold = Color(0xFFE7BD72);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF10050D),
          Color(0xFF3A091C),
          Color(0xFF170610),
          Color(0xFF080408),
        ],
        stops: [0, 0.38, 0.72, 1],
      ).createShader(rect);

    canvas.drawRect(rect, background);

    // Grandes halos de luz
    _drawGlow(
      canvas,
      Offset(
        size.width * (0.12 + 0.06 * math.sin(progress * math.pi * 2)),
        size.height * 0.18,
      ),
      size.width * 0.42,
      _wine.withValues(alpha: 0.42),
    );

    _drawGlow(
      canvas,
      Offset(
        size.width * (0.92 - 0.08 * math.cos(progress * math.pi * 2)),
        size.height * 0.76,
      ),
      size.width * 0.48,
      _gold.withValues(alpha: 0.10),
    );

    // Trazos diagonales luminosos
    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          _gold.withValues(alpha: 0.34),
          _wine.withValues(alpha: 0.72),
          Colors.transparent,
        ],
      ).createShader(rect);

    final path1 = Path()
      ..moveTo(-size.width * 0.2, size.height * 0.35)
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.08,
        size.width * 0.50,
        size.height * 0.58,
        size.width * 1.2,
        size.height * 0.20,
      );

    final path2 = Path()
      ..moveTo(-size.width * 0.2, size.height * 0.76)
      ..cubicTo(
        size.width * 0.40,
        size.height * 0.46,
        size.width * 0.62,
        size.height * 1.05,
        size.width * 1.2,
        size.height * 0.65,
      );

    canvas.drawPath(path1, ribbonPaint);
    canvas.drawPath(path2, ribbonPaint);

    // Partículas doradas
    final particlePaint = Paint()
      ..color = _gold.withValues(alpha: 0.44);

    for (int i = 0; i < 45; i++) {
      final x = ((i * 73.7) % 997) / 997 * size.width;
      final baseY = ((i * 137.3) % 991) / 991 * size.height;
      final y = (baseY + progress * size.height * (0.08 + (i % 3) * 0.04))
          % size.height;
      final radius = 0.6 + (i % 4) * 0.35;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        particlePaint,
      );
    }

    // Viñeta para que el contenido destaque
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          colors: [
            Colors.transparent,
            _darkWine.withValues(alpha: 0.40),
          ],
          stops: const [0.35, 1],
        ).createShader(rect),
    );
  }

  void _drawGlow(
    Canvas canvas,
    Offset center,
    double radius,
    Color color,
  ) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        ),
    );
  }

  @override
  bool shouldRepaint(covariant _PremiumBackgroundPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
