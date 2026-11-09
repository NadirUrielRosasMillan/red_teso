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

  bool _isPasswordVisible = false;
  bool _isSubmitting = false;
  int _logoTapCount = 0;
  Timer? _logoTapResetTimer;

  static const Color _navy = Color(0xFF123D78);
  static const Color _aqua = Color(0xFF67D8FF);

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
  }

  @override
  void dispose() {
    _logoTapResetTimer?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _buttonController.dispose();
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
            backgroundColor: const Color(0xFF7A1F35),
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
          backgroundColor: const Color(0xFF7A1F35),
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
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
                            child: _buildLoginCard(),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildFooter(),
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

  Widget _buildBrand({bool compact = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handleLogoTap,
          child: Container(
            width: compact ? 210 : 190,
            height: compact ? 132 : 120,
            child: Image.asset(
              'assets/images/branding/agora_logo_principal.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  Widget _buildLoginCard() {
    return Container(
      padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFD8E8F8)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF315B8A).withValues(alpha: 0.12),
                blurRadius: 38,
                offset: const Offset(0, 18),
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
                  color: _aqua,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Bienvenido!',
                style: GoogleFonts.outfit(
                  color: _navy,
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Inicia sesión y entra a tu ecosistema ÁGORA.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF647A96),
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
                    color: const Color(0xFF71839A),
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
                                  Color(0xFF3D9EEB),
                                  Color(0xFF1F67B2),
                                  Color(0xFF438DCE),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(17),
                              boxShadow: [
                                BoxShadow(
                                  color: _aqua.withValues(alpha: 0.23),
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
                                disabledBackgroundColor: Colors.white24,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
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
                                        color: Colors.white,
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
                        color: const Color(0xFF647A96),
                        fontSize: 12,
                      ),
                    ),
                    TextButton(
                      onPressed: _openRegister,
                      style: TextButton.styleFrom(
                        foregroundColor: _navy,
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
              color: _navy,
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
            color: const Color(0xFF1D3553),
            fontSize: 14,
          ),
          cursorColor: _aqua,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF91A1B5),
              fontSize: 12,
            ),
            prefixIcon: Icon(
              icon,
              color: _aqua,
              size: 21,
            ),
            suffixIcon: suffix,
            filled: true,
            fillColor: const Color(0xFFF5F9FE),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 19,
              horizontal: 15,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide(
                color: const Color(0xFFD7E3F0),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(
                color: _aqua,
                width: 1.4,
              ),
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
      color: const Color(0xFF7387A1),
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 2,
      ),
    );
  }
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

  static const Color _navy = Color(0xFF07172F);
  static const Color _aqua = Color(0xFF67D8FF);

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
      backgroundColor: const Color(0xFF102A4A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _aqua.withValues(alpha: 0.35)),
      ),
      title: Row(
        children: [
          const Icon(Icons.admin_panel_settings_rounded, color: _aqua),
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
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: _aqua),
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
              fillColor: Colors.black.withValues(alpha: 0.20),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _aqua, width: 1.4),
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
            backgroundColor: _aqua,
            foregroundColor: _navy,
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

class _PremiumBackgroundPainter extends CustomPainter {
  final double progress;

  _PremiumBackgroundPainter({required this.progress});

  static const Color _wine = Color(0xFF1357A6);
  static const Color _navy = Color(0xFF07172F);
  static const Color _aqua = Color(0xFF67D8FF);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF061326),
          Color(0xFF123F78),
          Color(0xFF0A2342),
          Color(0xFF040B17),
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
      _aqua.withValues(alpha: 0.10),
    );

    // Trazos diagonales luminosos
    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          _aqua.withValues(alpha: 0.34),
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
    final particlePaint = Paint()..color = _aqua.withValues(alpha: 0.44);

    for (int i = 0; i < 45; i++) {
      final x = ((i * 73.7) % 997) / 997 * size.width;
      final baseY = ((i * 137.3) % 991) / 991 * size.height;
      final y = (baseY + progress * size.height * (0.08 + (i % 3) * 0.04)) %
          size.height;
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
            _navy.withValues(alpha: 0.40),
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
