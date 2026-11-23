import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:red_teso/features/auth/presentation/providers/auth_provider.dart';
import 'package:red_teso/features/auth/presentation/widgets/verification_success_dialog.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  static const Color _greenPrimary = Color(0xFF0B5D3B);
  static const Color _greenSecondary = Color(0xFF1E8449);
  static const Color _greenLight = Color(0xFFA8D5A2);
  static const Color _textMuted = Color(0xFF6B7280);

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  late final AnimationController _logoOrbitController;

  String _userType = 'Alumno';
  String _modality = 'Servicio Social';
  String _gender = 'Femenino';
  bool _speaksEnglish = false;
  double _gpa = 8.0;

  @override
  void initState() {
    super.initState();
    _logoOrbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 7),
    )..repeat();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _logoOrbitController.dispose();
    super.dispose();
  }

  void _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor completa todos los campos obligatorios'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    Map<String, dynamic> extraData = {};
    if (_userType == 'Alumno') {
      extraData = {
        'modality': _modality,
        'gender': _gender,
        'speaksEnglish': _speaksEnglish,
        'gpa': _gpa,
        'career': 'Ingeniería en Sistemas Computacionales',
      };
    } else if (_userType == 'Profesor') {
      extraData = {
        'department': 'División de Ingeniería en Sistemas Computacionales',
        'isVerifiedProfessor': true,
      };
    }

    final error = await authProvider.signUp(
      email: email,
      password: password,
      name: name,
      type: _userType.toLowerCase(),
      extraData: extraData,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    } else {
      // Muestra la animación interactiva de éxito y aviso de correo / spam
      await VerificationSuccessDialog.show(context, email: email);

      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: _greenPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          const Positioned.fill(
            child: IgnorePointer(child: CustomPaint(painter: _RegisterBgPainter())),
          ),
          SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            children: [
                              _buildAnimatedLogo(),
                              const SizedBox(height: 8),
                              const Text(
                                'NEXUS',
                                style: TextStyle(
                                  color: _greenPrimary,
                                  fontSize: 25,
                                  height: 1.1,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'ÚNETE A NUESTRA COMUNIDAD',
                                style: TextStyle(
                                  color: _greenSecondary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Card(
                          margin: EdgeInsets.zero,
                          color: Colors.white.withValues(alpha: .96),
                          elevation: 10,
                          shadowColor: _greenPrimary.withValues(alpha: .10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(26),
                            side: BorderSide(
                              color: _greenLight.withValues(alpha: .75),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 42,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: _greenPrimary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                const SizedBox(height: 18),
                                const Text(
                                  'Crea tu cuenta',
                                  style: TextStyle(
                                    color: _greenPrimary,
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  'Completa tus datos para comenzar.',
                                  style: TextStyle(
                                    color: _textMuted,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 22),
                                const Text(
                                  'Tipo de cuenta',
                                  style: TextStyle(
                                    color: _greenPrimary,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SegmentedButton<String>(
                                  showSelectedIcon: false,
                                  style: SegmentedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    selectedForegroundColor: Colors.black,
                                    selectedBackgroundColor: _greenLight,
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 10,
                                    ),
                                  ),
                                  segments: const [
                                    ButtonSegment(
                                      value: 'Alumno',
                                      label: Text('Alumno'),
                                      icon: Icon(Icons.school_outlined),
                                    ),
                                    ButtonSegment(
                                      value: 'Empresa',
                                      label: Text('Empresa'),
                                      icon: Icon(Icons.business_outlined),
                                    ),
                                    ButtonSegment(
                                      value: 'Profesor',
                                      label: Text('Profesor'),
                                      icon: Icon(Icons.co_present_outlined),
                                    ),
                                  ],
                                  selected: {_userType},
                                  onSelectionChanged: (value) => setState(
                                    () => _userType = value.first,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Nombre completo',
                                  icon: Icons.person_outline_rounded,
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Correo institucional',
                                  icon: Icons.alternate_email_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                ),
                                const SizedBox(height: 14),
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Contraseña',
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: true,
                                ),
                                if (_userType == 'Alumno') ...[
                                  const SizedBox(height: 20),
                                  const Divider(height: 1),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Información académica',
                                    style: TextStyle(
                                      color: _greenPrimary,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  DropdownButtonFormField<String>(
                                    initialValue: _modality,
                                    isExpanded: true,
                                    decoration: _inputDecoration(
                                      'Estado / modalidad',
                                      Icons.school_outlined,
                                    ),
                                    items: [
                                      'Servicio Social',
                                      'Residencias',
                                      'Recién Egresado',
                                    ].map((item) {
                                      return DropdownMenuItem(
                                        value: item,
                                        child: Text(item),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() => _modality = value);
                                      }
                                    },
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 4,
                                    children: [
                                      const Text(
                                        'Género',
                                        style: TextStyle(
                                          color: _textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Radio<String>(
                                        value: 'Femenino',
                                        groupValue: _gender,
                                        activeColor: _greenPrimary,
                                        onChanged: (value) => setState(
                                          () => _gender = value!,
                                        ),
                                      ),
                                      const Text('Femenino'),
                                      Radio<String>(
                                        value: 'Masculino',
                                        groupValue: _gender,
                                        activeColor: _greenPrimary,
                                        onChanged: (value) => setState(
                                          () => _gender = value!,
                                        ),
                                      ),
                                      const Text('Masculino'),
                                    ],
                                  ),
                                  SwitchListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: const Text(
                                      '¿Hablas inglés?',
                                      style: TextStyle(fontSize: 14),
                                    ),
                                    value: _speaksEnglish,
                                    activeThumbColor: _greenPrimary,
                                    onChanged: (value) => setState(
                                      () => _speaksEnglish = value,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      const Text(
                                        'Promedio',
                                        style: TextStyle(
                                          color: _textMuted,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _gpa.toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: _greenPrimary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: _greenPrimary,
                                      inactiveTrackColor: _greenLight,
                                      thumbColor: _greenPrimary,
                                      overlayColor:
                                          _greenPrimary.withValues(alpha: .12),
                                      trackHeight: 4,
                                    ),
                                    child: Slider(
                                      value: _gpa,
                                      min: 6,
                                      max: 10,
                                      divisions: 40,
                                      label: _gpa.toStringAsFixed(1),
                                      onChanged: (value) => setState(
                                        () => _gpa = value,
                                      ),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                Consumer<AuthProvider>(
                                  builder: (context, auth, _) {
                                    return SizedBox(
                                      width: double.infinity,
                                      height: 52,
                                      child: auth.isLoading
                                          ? const Center(
                                              child:
                                                  CircularProgressIndicator(),
                                            )
                                          : FilledButton.icon(
                                              onPressed: _register,
                                              icon: const Icon(
                                                Icons.arrow_forward_rounded,
                                                color: Colors.black,
                                              ),
                                              label: const Text(
                                                'FINALIZAR REGISTRO',
                                                style: TextStyle(
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: .5,
                                                ),
                                              ),
                                              style: FilledButton.styleFrom(
                                                backgroundColor: _greenLight,
                                                foregroundColor: Colors.black,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(14),
                                                ),
                                              ),
                                            ),
                                    );
                                  },
                                ),
                                const SizedBox(height: 12),
                                Center(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Volver a iniciar sesión'),
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
        ],
      ),
    );
  }

  Widget _buildAnimatedLogo() {
    const markWidth = 154.0;
    const markHeight = 122.0;

    return AnimatedBuilder(
      animation: _logoOrbitController,
      builder: (context, _) {
        final angle = _logoOrbitController.value * math.pi * 2;
        const tilt = -.28;

        return SizedBox(
          width: markWidth,
          height: markHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) => const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _greenLight,
                    _greenSecondary,
                    _greenPrimary,
                  ],
                ).createShader(bounds),
                child: Text(
                  'N',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 94,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -9,
                  ),
                ),
              ),
              Positioned.fill(
                child: CustomPaint(
                  painter: _RegisterOrbitPainter(
                    progress: _logoOrbitController.value,
                  ),
                ),
              ),
              ...List.generate(3, (index) {
                final nodeAngle = angle + index * math.pi * 2 / 3;
                const rx = 62.0;
                const ry = 25.0;
                final x = rx * math.cos(nodeAngle);
                final y = ry * math.sin(nodeAngle);
                final nodeX = x * math.cos(tilt) - y * math.sin(tilt);
                final nodeY = x * math.sin(tilt) + y * math.cos(tilt);
                final icon = switch (index) {
                  0 => Icons.work_rounded,
                  1 => Icons.school_rounded,
                  _ => Icons.lightbulb_outline_rounded,
                };

                return Positioned(
                  left: markWidth / 2 + nodeX - 15,
                  top: markHeight / 2 + nodeY - 15,
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_greenSecondary, _greenPrimary],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1.7),
                      boxShadow: [
                        BoxShadow(
                          color: _greenPrimary.withValues(alpha: .2),
                          blurRadius: 9,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: index == 2
                        ? Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(icon, color: Colors.white, size: 18),
                              const Positioned(
                                right: 1,
                                bottom: 1,
                                child: Icon(
                                  Icons.settings_rounded,
                                  color: Colors.white,
                                  size: 9,
                                ),
                              ),
                            ],
                          )
                        : Icon(icon, color: Colors.white, size: 17),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _greenSecondary, size: 20),
      filled: true,
      fillColor: const Color(0xFFF6F9F7),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE9DF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDCE9DF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _greenPrimary, width: 1.5),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      decoration: _inputDecoration(label, icon),
    );
  }
}

class _RegisterOrbitPainter extends CustomPainter {
  final double progress;

  const _RegisterOrbitPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final orbit = Rect.fromCenter(
      center: center,
      width: size.width * .9,
      height: size.height * .44,
    );
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-.28);
    final localOrbit = orbit.shift(-center);
    canvas.drawOval(
      localOrbit,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
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
        ..strokeWidth = 3.2
        ..color = const Color(0xFFA8D5A2).withValues(alpha: .92),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _RegisterOrbitPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _RegisterBgPainter extends CustomPainter {
  const _RegisterBgPainter();

  @override
  void paint(Canvas canvas, Size size) {
    const lightGreen = Color(0xFFA8D5A2);
    const green = Color(0xFF1E8449);

    final topRight = Path()
      ..moveTo(size.width * .78, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * .3)
      ..cubicTo(size.width * .9, size.height * .24, size.width * .84,
          size.height * .12, size.width * .78, 0)
      ..close();
    final bottomLeft = Path()
      ..moveTo(0, size.height * .78)
      ..cubicTo(size.width * .12, size.height * .82, size.width * .2,
          size.height * .92, size.width * .32, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas
      ..drawPath(
        topRight,
        Paint()..color = lightGreen.withValues(alpha: .38),
      )
      ..drawPath(
        bottomLeft,
        Paint()..color = lightGreen.withValues(alpha: .45),
      );

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = green.withValues(alpha: .16);
    canvas
      ..drawPath(
        Path()
          ..moveTo(size.width * .82, 0)
          ..cubicTo(size.width * .87, size.height * .09, size.width * .94,
              size.height * .13, size.width, size.height * .12),
        line,
      )
      ..drawPath(
        Path()
          ..moveTo(0, size.height * .86)
          ..cubicTo(size.width * .11, size.height * .88, size.width * .2,
              size.height * .96, size.width * .27, size.height),
        line,
      );
  }

  @override
  bool shouldRepaint(covariant _RegisterBgPainter oldDelegate) => false;
}
