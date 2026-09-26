import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/core/theme/app_theme.dart';
import 'package:red_teso/features/auth/presentation/pages/register_page.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late AnimationController _smokeAnimationController;
  late AnimationController _floatController;

  bool _isPasswordVisible = false;
  bool _isLoginPressed = false;

  // Posición interactiva para la iluminación de humo según el toque/movimiento
  Offset _interactiveOffset = Offset.zero;
  Offset _targetOffset = Offset.zero;

  @override
  void initState() {
    super.initState();

    // Controlador para el movimiento fluido del humo de fondo
    _smokeAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat(reverse: true);

    // Controlador para la levitación sutil de la tarjeta de cristal
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _smokeAnimationController.dispose();
    _floatController.dispose();
    super.dispose();
  }

  void _login() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor ingresa tu correo y contraseña', style: GoogleFonts.inter()),
          backgroundColor: Colors.orange.withOpacity(0.9),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final error = await authProvider.signIn(email, password);

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  error,
                  style: GoogleFonts.inter(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFFD32F2F).withOpacity(0.95),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: GestureDetector(
        // Detecta el arrastre/movimiento en la pantalla para mover el humo interactivamente
        onPanUpdate: (details) {
          setState(() {
            _targetOffset += details.delta;
            _targetOffset = Offset(
              _targetOffset.dx.clamp(-size.width * 0.4, size.width * 0.4),
              _targetOffset.dy.clamp(-size.height * 0.4, size.height * 0.4),
            );
            _interactiveOffset = Offset.lerp(_interactiveOffset, _targetOffset, 0.2)!;
          });
        },
        onPanEnd: (_) {
          setState(() {
            _targetOffset = Offset.zero;
          });
        },
        child: Stack(
          children: [
            // 1. FONDO CON HUMO INTERACTIVO VINO Y DIFUMINADO (GUÍA NACIONAL 0xFF691C32)
            AnimatedBuilder(
              animation: _smokeAnimationController,
              builder: (context, child) {
                return CustomPaint(
                  size: size,
                  painter: _InteractiveSmokeBackgroundPainter(
                    progress: _smokeAnimationController.value,
                    interactiveOffset: _interactiveOffset,
                  ),
                );
              },
            ),

            // 2. CONTENIDO PRINCIPAL CON TARJETA DE CRISTAL
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
                  child: AnimatedBuilder(
                    animation: _floatController,
                    builder: (context, child) {
                      final floatY = math.sin(_floatController.value * math.pi) * 6.0;
                      return Transform.translate(
                        offset: Offset(0, floatY),
                        child: child,
                      );
                    },
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(38),
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
                            decoration: BoxDecoration(
                              // Gradiente translúcido frosted glass
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withOpacity(0.18),
                                  Colors.white.withOpacity(0.06),
                                  Colors.black.withOpacity(0.20),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(38),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.30),
                                width: 1.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.35),
                                  blurRadius: 40,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 20),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // 1. LOGO DE REDTESO (130x130) CON MARCO TRASLÚCIDO Y HALO GUINDA
                                Container(
                                  width: 130,
                                  height: 130,
                                  padding: const EdgeInsets.all(18),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.16),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.40),
                                      width: 2.0,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                        blurRadius: 25,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'web/icons/logo_sis_color.png',
                                    fit: BoxFit.contain,
                                  ),
                                ),

                                const SizedBox(height: 22),

                                // TÍTULO Y SUBTÍTULO
                                Text(
                                  'RedTESO',
                                  style: GoogleFonts.outfit(
                                    fontSize: 34,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.4),
                                        blurRadius: 12,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 6),

                                Text(
                                  'Plataforma Académica TESOEM',
                                  style: GoogleFonts.inter(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white.withOpacity(0.85),
                                    letterSpacing: 0.5,
                                  ),
                                ),

                                const SizedBox(height: 36),

                                // 2. CAMPO CORREO - ESTILO LÍNEA INFERIOR (UNDERLINE IGUAL A REFERENCIA)
                                _buildUnderlineTextField(
                                  controller: _emailController,
                                  hintText: 'Correo Institucional',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                ),

                                const SizedBox(height: 24),

                                // 3. CAMPO CONTRASEÑA - ESTILO LÍNEA INFERIOR CON OJO
                                _buildUnderlineTextField(
                                  controller: _passwordController,
                                  hintText: 'Contraseña',
                                  icon: Icons.lock_outline,
                                  obscureText: !_isPasswordVisible,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isPasswordVisible
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: Colors.white.withOpacity(0.85),
                                      size: 20,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isPasswordVisible = !_isPasswordVisible;
                                      });
                                    },
                                  ),
                                ),

                                const SizedBox(height: 40),

                                // 4. BOTÓN INICIAR SESIÓN EN VINO GUINDA NACIONAL Y AZUL SUAVE
                                Consumer<AuthProvider>(
                                  builder: (context, auth, _) {
                                    if (auth.isLoading) {
                                      return const Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                        ),
                                      );
                                    }

                                    return GestureDetector(
                                      onTapDown: (_) => setState(() => _isLoginPressed = true),
                                      onTapUp: (_) {
                                        setState(() => _isLoginPressed = false);
                                        _login();
                                      },
                                      onTapCancel: () => setState(() => _isLoginPressed = false),
                                      child: AnimatedScale(
                                        scale: _isLoginPressed ? 0.96 : 1.0,
                                        duration: const Duration(milliseconds: 100),
                                        child: Container(
                                          width: double.infinity,
                                          height: 54,
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [
                                                AppTheme.primaryColor, // Guinda Oficial 0xFF691C32
                                                Color(0xFF4A1022), // Vino Profundo
                                                Color(0xFF38101E), // Vino Noche
                                              ],
                                              begin: Alignment.centerLeft,
                                              end: Alignment.centerRight,
                                            ),
                                            borderRadius: BorderRadius.circular(27),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(0.35),
                                              width: 1,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: AppTheme.primaryColor.withOpacity(0.45),
                                                blurRadius: 22,
                                                offset: const Offset(0, 10),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              'INICIAR SESIÓN',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                ),

                                const SizedBox(height: 28),

                                // 5. ENLACE TRASLÚCIDO A REGISTRO
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const RegisterPage(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.20),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '¿No tienes cuenta? ',
                                          style: GoogleFonts.inter(
                                            color: Colors.white.withOpacity(0.85),
                                            fontSize: 13.5,
                                          ),
                                        ),
                                        Text(
                                          'Regístrate aquí',
                                          style: GoogleFonts.inter(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.bold,
                                            decoration: TextDecoration.underline,
                                            decorationColor: Colors.white,
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
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper widget para crear inputs estilo línea inferior minimalista (como la imagen de referencia)
  Widget _buildUnderlineTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
    Widget? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(
          color: Colors.white.withOpacity(0.70),
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(right: 12.0),
          child: Icon(
            icon,
            color: Colors.white.withOpacity(0.90),
            size: 22,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
        suffixIcon: suffixIcon,
        filled: false,
        border: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.65),
            width: 1.2,
          ),
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white.withOpacity(0.65),
            width: 1.2,
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.white,
            width: 2.0,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 14.0),
      ),
    );
  }
}

/// Dibuja un fondo fluido tipo humo interactivo en tonos Guinda Oficial (0xFF691C32)
/// que reacciona dinámicamente al toque/desplazamiento del usuario.
class _InteractiveSmokeBackgroundPainter extends CustomPainter {
  final double progress;
  final Offset interactiveOffset;

  _InteractiveSmokeBackgroundPainter({
    required this.progress,
    required this.interactiveOffset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // 1. Fondo base de gradiente vino profundo según Guía Nacional
    final baseGradient = LinearGradient(
      colors: const [
        Color(0xFF1E050D), // Vino Noche oscuro
        AppTheme.primaryColor, // Guinda Oficial 0xFF691C32
        Color(0xFF2E0A15), // Vino Noche
        Color(0xFF120308), // Vino Noche profundo
      ],
      stops: const [0.0, 0.45, 0.8, 1.0],
      begin: Alignment(
        -1.0 + (interactiveOffset.dx / size.width) * 0.8,
        -1.0 + (interactiveOffset.dy / size.height) * 0.8,
      ),
      end: Alignment(
        1.0 + (interactiveOffset.dx / size.width) * 0.8,
        1.0 + (interactiveOffset.dy / size.height) * 0.8,
      ),
    );

    canvas.drawRect(rect, Paint()..shader = baseGradient.createShader(rect));

    // 2. Capas de Humo Orgánico en movimiento fluido (Smoke Volumetric Clouds)
    const smokeCount = 5;

    for (int i = 0; i < smokeCount; i++) {
      final angle = (progress * math.pi * 2) + (i * (math.pi * 2 / smokeCount));
      final offsetX = size.width * 0.5 +
          math.cos(angle) * (60.0 + i * 15.0) +
          interactiveOffset.dx * (0.3 + i * 0.1);
      final offsetY = size.height * 0.4 +
          math.sin(angle * 1.3) * (50.0 + i * 20.0) +
          interactiveOffset.dy * (0.3 + i * 0.1);

      final center = Offset(offsetX, offsetY);
      final radius = size.width * (0.55 + (i * 0.08));

      final smokePaint = Paint()
        ..shader = RadialGradient(
          colors: [
            AppTheme.primaryColor.withOpacity(0.40 - (i * 0.05)),
            const Color(0xFF380B18).withOpacity(0.20),
            Colors.transparent,
          ],
          stops: const [0.0, 0.55, 1.0],
        ).createShader(
          Rect.fromCircle(center: center, radius: radius),
        );

      canvas.drawCircle(center, radius, smokePaint);
    }

    // 3. Resplandor acento dorado institucional sutil en el centro
    final goldCenter = Offset(
      size.width * 0.5 + interactiveOffset.dx * 0.2,
      size.height * 0.35 + interactiveOffset.dy * 0.2,
    );

    final goldPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          AppTheme.accentColor.withOpacity(0.18),
          Colors.transparent,
        ],
      ).createShader(
        Rect.fromCircle(center: goldCenter, radius: size.width * 0.5),
      );

    canvas.drawCircle(goldCenter, size.width * 0.5, goldPaint);
  }

  @override
  bool shouldRepaint(covariant _InteractiveSmokeBackgroundPainter oldDelegate) => true;
}
