import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

/// Fondo ambiental para RED-Teso.
/// Las capas decorativas no interceptan clics ni eventos del puntero.
class LiquidGlassAmbientBackground extends StatefulWidget {
  final Widget child;

  const LiquidGlassAmbientBackground({
    super.key,
    required this.child,
  });

  @override
  State<LiquidGlassAmbientBackground> createState() =>
      _LiquidGlassAmbientBackgroundState();
}

class _LiquidGlassAmbientBackgroundState
    extends State<LiquidGlassAmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    );

    // En Web dejamos el fondo estático para simplificar el renderizado.
    if (!kIsWeb) {
      _animController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final blobAlpha = isDark ? 1.0 : 0.55;

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: ColoredBox(
              color: isDark ? AppTheme.bgDark : AppTheme.surfaceLight,
            ),
          ),
        ),

        // Esfera turquesa.
        AnimatedBuilder(
          animation: _animController,
          child: IgnorePointer(
            child: SizedBox(
              width: size.width * 0.8,
              height: size.width * 0.8,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.40 * blobAlpha),
                      AppTheme.primaryColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          builder: (context, child) {
            final value = kIsWeb ? 0.0 : _animController.value;
            return Positioned(
              top: -80 + value * 50,
              left: -60 + value * 60,
              child: child!,
            );
          },
        ),

        // Esfera cian.
        AnimatedBuilder(
          animation: _animController,
          child: IgnorePointer(
            child: SizedBox(
              width: size.width * 0.85,
              height: size.width * 0.85,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentCyan.withValues(alpha: 0.35 * blobAlpha),
                      AppTheme.accentCyan.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          builder: (context, child) {
            final value = kIsWeb ? 0.0 : _animController.value;
            return Positioned(
              bottom: -100 + (1 - value) * 60,
              right: -80 + (1 - value) * 50,
              child: child!,
            );
          },
        ),

        // Destello menta.
        AnimatedBuilder(
          animation: _animController,
          child: IgnorePointer(
            child: SizedBox(
              width: size.width * 0.5,
              height: size.width * 0.5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppTheme.accentColor.withValues(alpha: 0.18 * blobAlpha),
                      AppTheme.accentColor.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          builder: (context, child) {
            final value = kIsWeb ? 0.0 : _animController.value;
            return Positioned(
              top: size.height * 0.4 + value * 30,
              right: -50 + value * 20,
              child: child!,
            );
          },
        ),

        // Difuminado decorativo. IgnorePointer evita que capture interacciones.
        Positioned.fill(
          child: IgnorePointer(
            child: kIsWeb
                ? ColoredBox(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.35),
                  )
                : BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
                    child: ColoredBox(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.20)
                          : Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
          ),
        ),

        // La interfaz queda por encima de todas las capas decorativas.
        Positioned.fill(child: widget.child),
      ],
    );
  }
}

/// Tarjeta de estilo vidrio esmerilado.
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
  bool _isHovered = false;

  void _setHovered(bool hovering) {
    if (!mounted || _isHovered == hovering) return;
    setState(() => _isHovered = hovering);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveGlowColor =
        widget.glowColor ?? AppTheme.primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardContent = Container(
      padding: widget.padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: _isHovered ? 0.12 : 0.08)
            : Colors.white.withValues(alpha: _isHovered ? 0.95 : 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: _isHovered ? 0.40 : 0.20)
              : (_isHovered ? AppTheme.primaryTurquoise.withValues(alpha: 0.5) : AppTheme.borderLight),
          width: _isHovered ? 1.5 : 1,
        ),
      ),
      child: widget.child,
    );

    Widget interactiveCard = Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: widget.onTap,
        onHover: _setHovered,
        child: cardContent,
      ),
    );

    // En plataformas no web conservamos el difuminado de la tarjeta.
    if (!kIsWeb) {
      interactiveCard = BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: interactiveCard,
      );
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.only(bottom: 16),
      child: AnimatedScale(
        scale: _isHovered ? 1.02 : 1,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: effectiveGlowColor.withValues(
                  alpha: (_isHovered ? 0.35 : 0.18) * (isDark ? 1 : 0.5),
                ),
                blurRadius: _isHovered ? 20 : 12,
                spreadRadius: _isHovered ? 2 : 0,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: interactiveCard,
          ),
        ),
      ),
    );
  }
}
