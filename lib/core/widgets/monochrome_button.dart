import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MonochromeButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;
  final double height;
  final double? width;

  const MonochromeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.height = 50,
    this.width,
  });

  @override
  State<MonochromeButton> createState() => _MonochromeButtonState();
}

class _MonochromeButtonState extends State<MonochromeButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? AppColors.white : AppColors.black;
    final textColor = isDark ? AppColors.black : AppColors.white;

    return AnimatedScale(
      scale: _isPressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) {
          if (widget.onPressed != null && !widget.isLoading) {
            setState(() => _isPressed = true);
          }
        },
        onTapUp: (_) {
          if (_isPressed) {
            setState(() => _isPressed = false);
          }
        },
        onTapCancel: () {
          if (_isPressed) {
            setState(() => _isPressed = false);
          }
        },
        child: SizedBox(
          height: widget.height,
          width: widget.width ?? double.infinity,
          child: ElevatedButton(
            onPressed: widget.isLoading ? null : widget.onPressed,
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: widget.isOutlined ? Colors.transparent : primaryColor,
              foregroundColor: widget.isOutlined ? primaryColor : textColor,
              disabledBackgroundColor: isDark ? AppColors.darkBorder : AppColors.lightBorder,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: widget.isOutlined
                    ? BorderSide(color: isDark ? AppColors.darkBorder : AppColors.lightBorder, width: 1.5)
                    : BorderSide.none,
              ),
            ),
            child: widget.isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        widget.isOutlined ? primaryColor : textColor,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, size: 18),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: widget.isOutlined ? primaryColor : textColor,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
