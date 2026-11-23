import 'package:flutter/material.dart';
import 'package:red_teso/core/theme/app_theme.dart';

/// Fondo limpio NEXUS (siempre blanco, sin saturación ni tonos azules).
class LiquidGlassAmbientBackground extends StatelessWidget {
  final Widget child;

  const LiquidGlassAmbientBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.white,
      child: SizedBox.expand(child: child),
    );
  }
}

/// Tarjeta limpia sobre fondo blanco con bordes grises suaves y acento verde Nexus.
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
    final cardContent = Container(
      padding: widget.padding ?? const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isHovered
              ? AppTheme.nexusGreen.withValues(alpha: 0.45)
              : AppTheme.borderLight,
          width: _isHovered ? 1.5 : 1,
        ),
      ),
      child: widget.child,
    );

    return Container(
      margin: widget.margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _isHovered ? 0.07 : 0.04),
            blurRadius: _isHovered ? 16 : 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.white,
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: widget.onTap,
            onHover: _setHovered,
            child: cardContent,
          ),
        ),
      ),
    );
  }
}
