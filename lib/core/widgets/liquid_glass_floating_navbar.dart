import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:red_teso/core/theme/app_theme.dart';

class LiquidGlassNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  LiquidGlassNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Barra de navegación flotante estilo Liquid Glass (iOS / WhatsApp Style)
/// Soporta deslizamiento continuo (drag/slide) con el dedo entre secciones,
/// retroalimentación háptica y transparencia ultra-cristalina.
class LiquidGlassFloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<LiquidGlassNavItem> items;

  const LiquidGlassFloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  void _handlePointerEvent(Offset localPosition, double totalWidth) {
    if (totalWidth <= 0 || items.isEmpty) return;
    final double itemWidth = totalWidth / items.length;
    final int targetIndex = (localPosition.dx / itemWidth).floor().clamp(0, items.length - 1);
    
    if (targetIndex != currentIndex) {
      HapticFeedback.selectionClick();
      onTap(targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shellColor = isDark
        ? const Color(0xFF101C2D).withValues(alpha: 0.88)
        : const Color(0xFFF8FBFF).withValues(alpha: 0.9);
    final inactiveColor = isDark
        ? Colors.white.withValues(alpha: 0.72)
        : const Color(0xFF64748B);

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      height: 76,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Listener(
                onPointerDown: (event) => _handlePointerEvent(event.localPosition, constraints.maxWidth),
                onPointerMove: (event) => _handlePointerEvent(event.localPosition, constraints.maxWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: shellColor,
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.24)
                          : const Color(0xFF64748B).withValues(alpha: 0.28),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.1),
                        blurRadius: 18,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Row(
                    children: List.generate(items.length, (index) {
                      final isSelected = index == currentIndex;
                      final item = items[index];

                      return Expanded(
                        child: GestureDetector(
                          onTap: () {
                            if (!isSelected) {
                              HapticFeedback.selectionClick();
                              onTap(index);
                            }
                          },
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
                              decoration: isSelected
                                  ? BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    )
                                  : const BoxDecoration(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    color: isSelected ? Colors.white : inactiveColor,
                                    size: isSelected ? 22 : 20,
                                  ),
                                  const SizedBox(height: 3),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      item.label,
                                      style: GoogleFonts.outfit(
                                        fontSize: isSelected ? 10.5 : 10,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                        color: isSelected ? Colors.white : inactiveColor,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
