import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';

/// Un diálogo modal ultra-moderno, interactivo y con estética limpia/moderna
/// que notifica al usuario la creación exitosa de su cuenta y la verificación por correo.
class VerificationSuccessDialog extends StatefulWidget {
  final String email;

  const VerificationSuccessDialog({
    super.key,
    required this.email,
  });

  /// Muestra el diálogo con animación de entrada y garantiza una animación de salida suave antes de cerrar.
  static Future<void> show(BuildContext context, {required String email}) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'VerificationSuccessDialog',
      barrierColor: Colors.black.withOpacity(0.65),
      transitionDuration: const Duration(milliseconds: 500),
      pageBuilder: (context, anim1, anim2) {
        return VerificationSuccessDialog(email: email);
      },
    );
  }

  @override
  State<VerificationSuccessDialog> createState() => _VerificationSuccessDialogState();
}

class _VerificationSuccessDialogState extends State<VerificationSuccessDialog>
    with TickerProviderStateMixin {
  late AnimationController _entryExitController;
  late AnimationController _floatController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _checkScaleAnimation;
  late Animation<double> _floatAnimation;

  bool _isExiting = false;
  bool _isButtonPressed = false;

  @override
  void initState() {
    super.initState();

    _entryExitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    // Animación suave de flotación continua (Efecto 3D / Levitación)
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    // Animación de pulso continuo para las ondas de fondo
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat();

    // Animación de destello/brillo que cruza el botón
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat();

    _scaleAnimation = CurvedAnimation(
      parent: _entryExitController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entryExitController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryExitController,
      curve: Curves.easeOutCubic,
    ));

    _checkScaleAnimation = CurvedAnimation(
      parent: _entryExitController,
      curve: const Interval(0.25, 0.9, curve: Curves.elasticOut),
    );

    _floatAnimation = Tween<double>(begin: -6.0, end: 6.0).animate(
      CurvedAnimation(
        parent: _floatController,
        curve: Curves.easeInOutSine,
      ),
    );

    _entryExitController.forward();
  }

  @override
  void dispose() {
    _entryExitController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _dismissDialog() async {
    if (_isExiting) return;
    setState(() {
      _isExiting = true;
    });

    await _entryExitController.animateTo(0.0,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInBack);

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _dismissDialog();
        return false;
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _entryExitController,
          _floatController,
          _pulseController,
          _shimmerController,
        ]),
        builder: (context, child) {
          final scale = _scaleAnimation.value;
          final opacity = _fadeAnimation.value.clamp(0.0, 1.0);
          final slide = _slideAnimation.value;
          final floatOffset = _floatAnimation.value;

          return BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 12.0 * opacity,
              sigmaY: 12.0 * opacity,
            ),
            child: Opacity(
              opacity: opacity,
              child: Center(
                child: SingleChildScrollView(
                  child: SlideTransition(
                    position: AlwaysStoppedAnimation(slide),
                    child: Transform.scale(
                      scale: scale,
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.88,
                        constraints: const BoxConstraints(maxWidth: 400),
                        margin: const EdgeInsets.all(20),
                        padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF691C32).withOpacity(0.18),
                              blurRadius: 40,
                              spreadRadius: 4,
                              offset: const Offset(0, 16),
                            ),
                          ],
                          border: Border.all(
                            color: const Color(0xFFF1F5F9),
                            width: 2,
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 1. ILUSTRACIÓN DE ÉXITO 3D CON LEVITACIÓN
                            _buildModernHeroIcon(floatOffset),

                            const SizedBox(height: 24),

                            // 2. TÍTULO CON TIPOGRAFÍA MODERNA
                            Text(
                              '¡Registro Exitoso!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF0F172A),
                                letterSpacing: -0.5,
                              ),
                            ),

                            const SizedBox(height: 6),

                            Text(
                              'Tu cuenta ha sido creada correctamente.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w400,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 3. PILL DEL CORREO ELECTRÓNICO
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.mark_email_read_rounded,
                                      size: 16,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Flexible(
                                    child: Text(
                                      widget.email,
                                      style: GoogleFonts.inter(
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1E293B),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 20),

                            Text(
                              'Te enviamos un enlace de activación a tu correo. Por favor verifícalo para ingresar a RedTESO.',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                color: const Color(0xFF475569),
                                height: 1.45,
                              ),
                            ),

                            const SizedBox(height: 20),

                            // 4. TARJETA INFORMATIVA SPAM - DISEÑO ULTRA-LIMPIO
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFFBEB), // Soft Warm Yellow
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFDE68A),
                                  width: 1.2,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.alternate_email_rounded,
                                      color: Color(0xFFD97706),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '¿No encuentras el correo?',
                                          style: GoogleFonts.inter(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFB45309),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          'Revisa tu bandeja principal y tu carpeta de Spam / Correo no deseado.',
                                          style: GoogleFonts.inter(
                                            fontSize: 12.5,
                                            color: const Color(0xFF78350F),
                                            height: 1.35,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 28),

                            // 5. BOTÓN PRINCIPAL CON EFECTO BRILLO / SHIMMER
                            GestureDetector(
                              onTapDown: (_) => setState(() => _isButtonPressed = true),
                              onTapUp: (_) {
                                setState(() => _isButtonPressed = false);
                                _dismissDialog();
                              },
                              onTapCancel: () => setState(() => _isButtonPressed = false),
                              child: AnimatedScale(
                                scale: _isButtonPressed ? 0.96 : 1.0,
                                duration: const Duration(milliseconds: 120),
                                child: Container(
                                  width: double.infinity,
                                  height: 54,
                                  clipBehavior: Clip.antiAlias,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppTheme.primaryColor,
                                        Color(0xFF8B1E3F),
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppTheme.primaryColor.withOpacity(0.32),
                                        blurRadius: 16,
                                        spreadRadius: 0,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    children: [
                                      // Brillo Shimmer en diagonal que pasa continuamente
                                      Positioned.fill(
                                        child: CustomPaint(
                                          painter: _ShimmerPainter(
                                            progress: _shimmerController.value,
                                          ),
                                        ),
                                      ),
                                      Center(
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              '¡ENTENDIDO, IR AL LOGIN!',
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              color: Colors.white,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
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
          );
        },
      ),
    );
  }

  /// Construye el icono 3D flotante con capas de gradiente y animación de levitación
  Widget _buildModernHeroIcon(double floatOffset) {
    final checkScale = _checkScaleAnimation.value;
    final pulseValue = _pulseController.value;

    return Transform.translate(
      offset: Offset(0, floatOffset),
      child: SizedBox(
        height: 120,
        width: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Anillo pulsadante de fondo
            CustomPaint(
              size: const Size(120, 120),
              painter: _GlowPulsePainter(
                pulseValue: pulseValue,
                color: const Color(0xFF10B981),
              ),
            ),

            // Esfera verde esmeralda brillante con gradiente radial y sombra 3D
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF34D399), // Emerald claro
                    Color(0xFF059669), // Emerald profundo
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF10B981).withOpacity(0.45),
                    blurRadius: 24,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Transform.scale(
                scale: checkScale,
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),

            // Avión de papel / Envoltorio flotante 3D animado en la esquina superior derecha
            Positioned(
              top: 6,
              right: 8,
              child: Transform.scale(
                scale: checkScale,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Color(0xFF38BDF8), // Cyan neón
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dibuja el brillo/shimmer diagonal en el botón
class _ShimmerPainter extends CustomPainter {
  final double progress;

  _ShimmerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;

    final shimmerWidth = 60.0;
    final startX = (width + shimmerWidth * 2) * progress - shimmerWidth;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.25),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromLTWH(startX, 0, shimmerWidth, height),
      );

    final path = Path()
      ..moveTo(startX, 0)
      ..lineTo(startX + 30, 0)
      ..lineTo(startX + 30 - 20, height)
      ..lineTo(startX - 20, height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ShimmerPainter oldDelegate) => true;
}

/// Dibuja los pulso glow concéntricos detrás del icono de éxito
class _GlowPulsePainter extends CustomPainter {
  final double pulseValue;
  final Color color;

  _GlowPulsePainter({required this.pulseValue, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    for (int i = 0; i < 2; i++) {
      final progress = (pulseValue + (i * 0.5)) % 1.0;
      final radius = 40.0 + (progress * 20.0);
      final opacity = (1.0 - progress).clamp(0.0, 0.5);

      final paint = Paint()
        ..color = color.withOpacity(opacity * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5;

      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowPulsePainter oldDelegate) => true;
}
