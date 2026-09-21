import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

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
        child: photoUrl != null && photoUrl!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: photoUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: backgroundColor,
                  child: Center(
                    child: SizedBox(
                      width: radius * 0.8,
                      height: radius * 0.8,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => _buildFallback(textColor),
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
