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
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 20),
      height: 68,
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
                    // Cristal ultra-transparente y elegante estilo Liquid Glass
                    color: const Color(0xFF121826).withOpacity(0.38),
                    borderRadius: BorderRadius.circular(36),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 20,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
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
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: isSelected
                                  ? BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.88),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withOpacity(0.45),
                                          blurRadius: 12,
                                          offset: const Offset(0, 3),
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
                                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.75),
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
                                        color: isSelected ? Colors.white : Colors.white.withOpacity(0.75),
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
