import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class FloatingNavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const FloatingNavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class FloatingNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<FloatingNavBarItem> items;

  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final navBackground = isDark
        ? AppColors.darkSurface.withValues(alpha: 0.85)
        : AppColors.white.withValues(alpha: 0.85);
    final borderColor = isDark
        ? AppColors.white.withValues(alpha: 0.15)
        : AppColors.black.withValues(alpha: 0.1);

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        height: 64,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: navBackground,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: borderColor, width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;

                  return GestureDetector(
                    onTap: () => onTap(index),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.fastOutSlowIn,
                      padding: EdgeInsets.symmetric(
                        horizontal: isSelected ? 16 : 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primaryColor.withValues(alpha: isDark ? 0.18 : 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: AnimatedScale(
                        scale: isSelected ? 1.15 : 1.0,
                        duration: const Duration(milliseconds: 200),
                        child: Icon(
                          isSelected ? item.activeIcon : item.icon,
                          color: isSelected
                              ? primaryColor
                              : (isDark
                                  ? AppColors.darkTextMuted
                                  : AppColors.lightTextMuted),
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
