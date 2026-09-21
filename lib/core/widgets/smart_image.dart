import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SmartImage extends StatelessWidget {
  final String imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Widget? placeholder;
  final Widget? errorWidget;

  const SmartImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.placeholder,
    this.errorWidget,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkCard : AppColors.lightCard;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    if (imageUrl.trim().isEmpty) {
      return errorWidget ?? _buildErrorContainer(cardColor, textSecondary);
    }

    final trimmed = imageUrl.trim();

    // 1. Base64 Data URI check: data:image/...;base64,...
    if (trimmed.startsWith('data:image/') && trimmed.contains(';base64,')) {
      try {
        final base64Data = trimmed.split(';base64,').last;
        final Uint8List bytes = base64Decode(base64Data);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? _buildErrorContainer(cardColor, textSecondary),
        );
      } catch (_) {
        return errorWidget ?? _buildErrorContainer(cardColor, textSecondary);
      }
    }

    // 2. Raw Base64 string without header
    if (!trimmed.startsWith('http://') &&
        !trimmed.startsWith('https://') &&
        !trimmed.startsWith('/') &&
        !trimmed.contains(':\\') &&
        trimmed.length > 100) {
      try {
        final Uint8List bytes = base64Decode(trimmed);
        return Image.memory(
          bytes,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? _buildErrorContainer(cardColor, textSecondary),
        );
      } catch (_) {}
    }

    // 3. Local File path check
    if (trimmed.startsWith('/') || trimmed.contains(':\\')) {
      final file = File(trimmed);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) =>
              errorWidget ?? _buildErrorContainer(cardColor, textSecondary),
        );
      }
    }

    // 4. Network HTTP/HTTPS URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: trimmed,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) =>
            placeholder ?? Container(color: cardColor),
        errorWidget: (context, url, error) =>
            errorWidget ?? _buildErrorContainer(cardColor, textSecondary),
      );
    }

    return errorWidget ?? _buildErrorContainer(cardColor, textSecondary);
  }

  Widget _buildErrorContainer(Color cardColor, Color textSecondary) {
    return Container(
      width: width,
      height: height,
      color: cardColor,
      child: Center(
        child: Icon(
          Icons.image_not_supported_outlined,
          color: textSecondary,
          size: 24,
        ),
      ),
    );
  }
}
