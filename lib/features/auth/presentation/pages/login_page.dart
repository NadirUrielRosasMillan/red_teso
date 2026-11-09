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

<<<<<<< HEAD
  static const Color _navy = Color(0xFF123D78);
  static const Color _aqua = Color(0xFF67D8FF);
=======
  static const Color _bgWhite = Colors.white; // Fondo blanco puro
  static const Color _primaryTurquoise = Color(0xFF0793B8); // Turquesa / Cian Oscuro
  static const Color _cyan = Color(0xFF10BFD0); // Cian claro
  static const Color _textDark = Color(0xFF0D1330); // Gris-950 (Oscuro)
  static const Color _textMuted = Color(0xFF566080); // Gris-600
>>>>>>> origin/main

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
<<<<<<< HEAD
      backgroundColor: Colors.white,
=======
      backgroundColor: _bgWhite,
>>>>>>> origin/main
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

<<<<<<< HEAD
=======
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

>>>>>>> origin/main
  Widget _buildBrand({bool compact = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _handleLogoTap,
          child: Container(
<<<<<<< HEAD
            width: compact ? 210 : 190,
            height: compact ? 132 : 120,
            child: Image.asset(
              'assets/images/branding/agora_logo_principal.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 18),
=======
            width: compact ? 94 : 108,
            height: compact ? 94 : 108,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: _primaryTurquoise.withValues(alpha: 0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: _primaryTurquoise.withValues(alpha: 0.15),
                  blurRadius: 30,
                  spreadRadius: 2,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: SizedBox(
                width: compact ? 52 : 62,
                height: compact ? 52 : 62,
                child: const _AnimatedVectorLogo(),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'RedTESO',
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
            color: _primaryTurquoise,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
          ),
        ),
>>>>>>> origin/main
      ],
    );
  }

  Widget _buildLoginCard() {
<<<<<<< HEAD
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
=======
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.6), // Cristal claro
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: _primaryTurquoise.withValues(alpha: 0.08),
                blurRadius: 40,
                offset: const Offset(0, 20),
>>>>>>> origin/main
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
<<<<<<< HEAD
                  color: _aqua,
=======
                  color: _primaryTurquoise,
>>>>>>> origin/main
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                '¡Bienvenido!',
<<<<<<< HEAD
                style: GoogleFonts.outfit(
                  color: _navy,
                  fontSize: 31,
=======
                style: GoogleFonts.plusJakartaSans(
                  color: _textDark,
                  fontSize: 32,
>>>>>>> origin/main
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
<<<<<<< HEAD
                'Inicia sesión y entra a tu ecosistema ÁGORA.',
                style: GoogleFonts.inter(
                  color: const Color(0xFF647A96),
=======
                'Ingresa con tu matrícula (Alumno), número de empleado (Profesor) o correo (Empresa).',
                style: GoogleFonts.inter(
                  color: _textMuted,
>>>>>>> origin/main
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              _buildInput(
                controller: _emailController,
                label: 'Usuario o Correo',
                hint: 'matrícula / empleado / correo',
                icon: Icons.person_outline_rounded,
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
<<<<<<< HEAD
                    color: const Color(0xFF71839A),
=======
                    color: _textMuted,
>>>>>>> origin/main
                    size: 21,
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 36),
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
<<<<<<< HEAD
                                  Color(0xFF3D9EEB),
                                  Color(0xFF1F67B2),
                                  Color(0xFF438DCE),
=======
                                  Color(0xFF00B8F0), // _cyan
                                  Color(0xFF0793B8), // _primaryTurquoise
>>>>>>> origin/main
                                ],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
<<<<<<< HEAD
                                  color: _aqua.withValues(alpha: 0.23),
                                  blurRadius: 22,
                                  offset: const Offset(0, 8),
=======
                                  color: _primaryTurquoise.withValues(alpha: 0.35),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
>>>>>>> origin/main
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
              const SizedBox(height: 28),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      '¿Nuevo en la comunidad? ',
                      style: GoogleFonts.inter(
<<<<<<< HEAD
                        color: const Color(0xFF647A96),
=======
                        color: _textMuted,
>>>>>>> origin/main
                        fontSize: 12,
                      ),
                    ),
                    TextButton(
                      onPressed: _openRegister,
                      style: TextButton.styleFrom(
<<<<<<< HEAD
                        foregroundColor: _navy,
=======
                        foregroundColor: _primaryTurquoise,
>>>>>>> origin/main
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
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
<<<<<<< HEAD
            style: GoogleFonts.inter(
              color: _navy,
=======
            style: GoogleFonts.plusJakartaSans(
              color: _textDark,
>>>>>>> origin/main
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
<<<<<<< HEAD
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
=======
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
              cursorColor: _primaryTurquoise,
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.inter(
                  color: _textMuted.withValues(alpha: 0.6),
                  fontSize: 13,
                ),
                prefixIcon: Icon(
                  icon,
                  color: _primaryTurquoise,
                  size: 20,
                ),
                suffixIcon: suffix,
                filled: true,
                fillColor: Colors.black.withValues(alpha: 0.03),
                contentPadding: const EdgeInsets.symmetric(
                  vertical: 18,
                  horizontal: 16,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: _primaryTurquoise.withValues(alpha: 0.15),
                    width: 1.2,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: _primaryTurquoise,
                    width: 1.5,
                  ),
                ),
>>>>>>> origin/main
              ),
            ),
          ),
        ),
      ],
    );
  }

<<<<<<< HEAD
=======
  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _primaryTurquoise.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: _primaryTurquoise.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            icon,
            color: _primaryTurquoise,
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

>>>>>>> origin/main
  Widget _buildFooter() {
    return Text(
      'PLATAFORMA ACADÉMICA TESOEM',
      textAlign: TextAlign.center,
      style: GoogleFonts.inter(
<<<<<<< HEAD
      color: const Color(0xFF7387A1),
=======
        color: _textMuted.withValues(alpha: 0.6),
>>>>>>> origin/main
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

<<<<<<< HEAD
  static const Color _navy = Color(0xFF07172F);
  static const Color _aqua = Color(0xFF67D8FF);
=======
  static const Color _bgDark = Color(0xFF0A1922);
  static const Color _cyan = Color(0xFF10BFD0);
>>>>>>> origin/main

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
<<<<<<< HEAD
      backgroundColor: const Color(0xFF102A4A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _aqua.withValues(alpha: 0.35)),
      ),
      title: Row(
        children: [
          const Icon(Icons.admin_panel_settings_rounded, color: _aqua),
=======
      backgroundColor: _bgDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: _cyan.withValues(alpha: 0.35)),
      ),
      title: Row(
        children: [
          const Icon(Icons.admin_panel_settings_rounded, color: _cyan),
>>>>>>> origin/main
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
<<<<<<< HEAD
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: _aqua),
=======
              prefixIcon: const Icon(Icons.lock_outline_rounded, color: _cyan),
>>>>>>> origin/main
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
<<<<<<< HEAD
                borderSide: const BorderSide(color: _aqua, width: 1.4),
=======
                borderSide: const BorderSide(color: _cyan, width: 1.4),
>>>>>>> origin/main
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
<<<<<<< HEAD
            backgroundColor: _aqua,
            foregroundColor: _navy,
=======
            backgroundColor: _cyan,
            foregroundColor: _bgDark,
>>>>>>> origin/main
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

// --- WIDGET PARA DIBUJAR Y ANIMAR EL LOGO VECTORIAL (Birrete + Maletín) ---
class _AnimatedVectorLogo extends StatefulWidget {
  const _AnimatedVectorLogo();

  @override
  State<_AnimatedVectorLogo> createState() => _AnimatedVectorLogoState();
}

class _AnimatedVectorLogoState extends State<_AnimatedVectorLogo> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _LogoVectorPainter(progress: _controller.value),
        );
      },
    );
  }
}

class _LogoVectorPainter extends CustomPainter {
  final double progress;

  _LogoVectorPainter({required this.progress});

  static const Color _primaryTurquoise = Color(0xFF0793B8);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _primaryTurquoise.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final shadowPaint = Paint()
      ..color = _primaryTurquoise.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);

    final path = Path();
    final w = size.width;
    final h = size.height;

    // BIRRETE (Gorro de graduación)
    path.moveTo(w * 0.1, h * 0.35); // Vértice Izquierdo
    path.lineTo(w * 0.5, h * 0.15); // Vértice Superior
    path.lineTo(w * 0.9, h * 0.35); // Vértice Derecho
    path.lineTo(w * 0.5, h * 0.55); // Vértice Inferior
    path.close();

    // Borla del birrete
    path.moveTo(w * 0.85, h * 0.38);
    path.lineTo(w * 0.85, h * 0.65); // Caída del hilo
    // Nudo y pelitos de la borla
    path.moveTo(w * 0.81, h * 0.65);
    path.lineTo(w * 0.89, h * 0.65);
    path.moveTo(w * 0.82, h * 0.65);
    path.lineTo(w * 0.80, h * 0.72);
    path.moveTo(w * 0.85, h * 0.65);
    path.lineTo(w * 0.85, h * 0.75);
    path.moveTo(w * 0.88, h * 0.65);
    path.lineTo(w * 0.90, h * 0.72);

    // Base del gorro (Cubo abajo del rombo)
    path.moveTo(w * 0.3, h * 0.45);
    path.lineTo(w * 0.3, h * 0.6);
    path.quadraticBezierTo(w * 0.5, h * 0.68, w * 0.7, h * 0.6);
    path.lineTo(w * 0.7, h * 0.45);

    // MALETÍN (Debajo del birrete)
    // Asa del maletín
    path.moveTo(w * 0.4, h * 0.55);
    path.lineTo(w * 0.4, h * 0.48);
    path.quadraticBezierTo(w * 0.5, h * 0.45, w * 0.6, h * 0.48);
    path.lineTo(w * 0.6, h * 0.55);

    // Solapa del maletín
    path.moveTo(w * 0.15, h * 0.55);
    path.lineTo(w * 0.85, h * 0.55);
    path.quadraticBezierTo(w * 0.85, h * 0.7, w * 0.6, h * 0.75);
    path.quadraticBezierTo(w * 0.5, h * 0.77, w * 0.4, h * 0.75);
    path.quadraticBezierTo(w * 0.15, h * 0.7, w * 0.15, h * 0.55);

    // Cuerpo del maletín
    path.moveTo(w * 0.18, h * 0.65);
    path.lineTo(w * 0.18, h * 0.88);
    path.quadraticBezierTo(w * 0.18, h * 0.95, w * 0.3, h * 0.95);
    path.lineTo(w * 0.7, h * 0.95);
    path.quadraticBezierTo(w * 0.82, h * 0.95, w * 0.82, h * 0.88);
    path.lineTo(w * 0.82, h * 0.65);

    // Botón / Broche central del maletín
    path.moveTo(w * 0.5, h * 0.7);
    path.lineTo(w * 0.5, h * 0.8);

    // MÉTRICA DE ANIMACIÓN (TRAZO)
    // Se extrae solo el porcentaje del trazado de acuerdo al progress
    final PathMetrics pathMetrics = path.computeMetrics();
    final Path animatedPath = Path();

    for (final metric in pathMetrics) {
      final extractLength = metric.length * Curves.easeInOutCubic.transform(progress);
      animatedPath.addPath(metric.extractPath(0.0, extractLength), Offset.zero);
    }

    // Dibujar sombra para efecto "neón / semitransparente"
    canvas.drawPath(animatedPath, shadowPaint);
    // Dibujar trazo principal blanco
    canvas.drawPath(animatedPath, paint);
  }

  @override
  bool shouldRepaint(covariant _LogoVectorPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _PremiumBackgroundPainter extends CustomPainter {
  final double progress;

  _PremiumBackgroundPainter({required this.progress});

<<<<<<< HEAD
  static const Color _wine = Color(0xFF1357A6);
  static const Color _navy = Color(0xFF07172F);
  static const Color _aqua = Color(0xFF67D8FF);
=======
  static const Color _noche800 = Color(0xFFF8FBFF);
  static const Color _noche950 = Color(0xFFFFFFFF);
  static const Color _primaryTurquoise = Color(0xFF0793B8);
  static const Color _cyan = Color(0xFF10BFD0);
>>>>>>> origin/main

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    final background = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
<<<<<<< HEAD
          Color(0xFF061326),
          Color(0xFF123F78),
          Color(0xFF0A2342),
          Color(0xFF040B17),
=======
          Color(0xFFFFFFFF),
          Color(0xFFF4FAFC),
          Color(0xFFE6F6FA),
          Color(0xFFDCEBF0),
>>>>>>> origin/main
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
      _primaryTurquoise.withValues(alpha: 0.1),
    );

    _drawGlow(
      canvas,
      Offset(
        size.width * (0.92 - 0.08 * math.cos(progress * math.pi * 2)),
        size.height * 0.76,
      ),
      size.width * 0.48,
<<<<<<< HEAD
      _aqua.withValues(alpha: 0.10),
=======
      _cyan.withValues(alpha: 0.08),
>>>>>>> origin/main
    );

    // Trazos diagonales luminosos
    final ribbonPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
<<<<<<< HEAD
          _aqua.withValues(alpha: 0.34),
          _wine.withValues(alpha: 0.72),
=======
          _cyan.withValues(alpha: 0.15),
          _primaryTurquoise.withValues(alpha: 0.25),
>>>>>>> origin/main
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

<<<<<<< HEAD
    // Partículas doradas
    final particlePaint = Paint()..color = _aqua.withValues(alpha: 0.44);
=======
    // Partículas luminosas estilo cian
    final particlePaint = Paint()..color = _cyan.withValues(alpha: 0.3);
>>>>>>> origin/main

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
<<<<<<< HEAD
            _navy.withValues(alpha: 0.40),
=======
            Colors.white.withValues(alpha: 0.1),
>>>>>>> origin/main
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
