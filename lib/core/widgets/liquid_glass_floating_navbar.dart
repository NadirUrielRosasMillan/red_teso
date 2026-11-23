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

/// Barra de navegación flotante estilo NEXUS (Blanco, Gris, Verde Nexus y letras negras)
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
    final int targetIndex =
        (localPosition.dx / itemWidth).floor().clamp(0, items.length - 1);

    if (targetIndex != currentIndex) {
      HapticFeedback.selectionClick();
      onTap(targetIndex);
    }
  }

  @override
  Widget build(BuildContext context) {
    const inactiveColor = AppTheme.nexusTextMuted;

    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 20),
      height: 76,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Listener(
                onPointerDown: (event) =>
                    _handlePointerEvent(event.localPosition, constraints.maxWidth),
                onPointerMove: (event) =>
                    _handlePointerEvent(event.localPosition, constraints.maxWidth),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.96),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: AppTheme.borderLight,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              decoration: isSelected
                                  ? BoxDecoration(
                                      color: AppTheme.nexusGreenLight,
                                      borderRadius: BorderRadius.circular(24),
                                    )
                                  : const BoxDecoration(),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isSelected ? item.activeIcon : item.icon,
                                    color: isSelected
                                        ? Colors.black
                                        : inactiveColor,
                                    size: isSelected ? 22 : 20,
                                  ),
                                  const SizedBox(height: 3),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      item.label,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: isSelected ? 10.5 : 10,
                                        fontWeight: isSelected
                                            ? FontWeight.w800
                                            : FontWeight.w600,
                                        color: isSelected
                                            ? Colors.black
                                            : inactiveColor,
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
