import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

/// Fondo Dinámico Ambiental 2026 con Esferas Flotantes en Guinda y Verde Esmeralda
class LiquidGlassAmbientBackground extends StatefulWidget {
  final Widget child;

  const LiquidGlassAmbientBackground({
    super.key,
    required this.child,
  });

  @override
  State<LiquidGlassAmbientBackground> createState() => _LiquidGlassAmbientBackgroundState();
}

class _LiquidGlassAmbientBackgroundState extends State<LiquidGlassAmbientBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF090D16), // Noche Profunda 2026
      body: Stack(
        children: [
          // 1. ESFERA AMBIENTAL 1: GUINDA OFICIAL (FLOTANTE)
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final value = _animController.value;
              return Positioned(
                top: -80 + (value * 60),
                left: -60 + (value * 80),
                child: Container(
                  width: size.width * 0.8,
                  height: size.width * 0.8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryColor.withOpacity(0.45),
                        AppTheme.primaryColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 2. ESFERA AMBIENTAL 2: VERDE ESMERALDA (FLOTANTE)
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final value = _animController.value;
              return Positioned(
                bottom: -100 + ((1 - value) * 80),
                right: -80 + ((1 - value) * 60),
                child: Container(
                  width: size.width * 0.85,
                  height: size.width * 0.85,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.primaryGreen.withOpacity(0.40),
                        AppTheme.primaryGreen.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 3. ESFERA AMBIENTAL 3: DESTELLO DORADO ACCENT
          AnimatedBuilder(
            animation: _animController,
            builder: (context, child) {
              final value = _animController.value;
              return Positioned(
                top: size.height * 0.4 + (value * 40),
                right: -50 + (value * 30),
                child: Container(
                  width: size.width * 0.5,
                  height: size.width * 0.5,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppTheme.accentColor.withOpacity(0.20),
                        AppTheme.accentColor.withOpacity(0.0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          // 4. MALA DE CRISTAL ESMERILADO (BLUR BACKDROP)
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
              child: Container(
                color: Colors.black.withOpacity(0.25),
              ),
            ),
          ),

          // 5. CONTENIDO
          Positioned.fill(
            child: widget.child,
          ),
        ],
      ),
    );
  }
}

/// Tarjeta Flotante Estilo Vidrio Esmerilado (Glassmorphism Card 2026)
class GlassmorphicCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? margin;
  final EdgeInsetsGeometry? padding;
  final Color? glowColor;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.onTap,
    this.margin,
    this.padding,
    this.glowColor,
  });

  @override
  State<GlassmorphicCard> createState() => _GlassmorphicCardState();
}

class _GlassmorphicCardState extends State<GlassmorphicCard> {
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor = widget.glowColor ?? AppTheme.primaryColor;

    return Container(
      margin: widget.margin ?? const EdgeInsets.only(bottom: 16),
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: AnimatedScale(
            scale: _isPressed ? 0.96 : (_isHovered ? 1.02 : 1.0),
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: effectiveGlowColor.withOpacity(_isHovered ? 0.35 : 0.18),
                    blurRadius: _isHovered ? 20 : 12,
                    spreadRadius: _isHovered ? 2 : 0,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Container(
                    padding: widget.padding ?? const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_isHovered ? 0.12 : 0.08),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: _isHovered
                            ? Colors.white.withOpacity(0.35)
                            : Colors.white.withOpacity(0.18),
                        width: _isHovered ? 1.5 : 1.0,
                      ),
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
