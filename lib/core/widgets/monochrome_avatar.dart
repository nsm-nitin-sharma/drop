import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'smart_image.dart';

class MonochromeAvatar extends StatelessWidget {
  final String? photoUrl;
  final double radius;
  final String fallbackInitial;
  final VoidCallback? onTap;

  const MonochromeAvatar({
    super.key,
    this.photoUrl,
    this.radius = 20,
    this.fallbackInitial = 'D',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final backgroundColor = isDark ? AppColors.darkSurface : AppColors.lightSurface;
    final textColor = isDark ? AppColors.white : AppColors.black;

    final avatarWidget = Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ClipOval(
        child: photoUrl != null && photoUrl!.trim().isNotEmpty
            ? SmartImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                errorWidget: _buildFallback(textColor),
              )
            : _buildFallback(textColor),
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: avatarWidget,
      );
    }
    return avatarWidget;
  }

  Widget _buildFallback(Color textColor) {
    return Center(
      child: Text(
        fallbackInitial.isNotEmpty ? fallbackInitial[0].toUpperCase() : 'D',
        style: TextStyle(
          fontSize: radius * 0.8,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
