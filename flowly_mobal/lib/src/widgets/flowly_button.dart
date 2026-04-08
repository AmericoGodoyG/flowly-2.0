import 'package:flutter/material.dart';
import 'package:meu_app/src/app/flowly_theme.dart';

class FlowlyButton extends StatelessWidget {
  const FlowlyButton({
    required this.onPressed,
    required this.label,
    this.isLoading = false,
    this.color = const Color(0xFF0D9C6E),
    this.textColor = Colors.white,
    this.size = FlowlyButtonSize.large,
    super.key,
  });

  final VoidCallback onPressed;
  final String label;
  final bool isLoading;
  final Color color;
  final Color textColor;
  final FlowlyButtonSize size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size.height,
      width: size == FlowlyButtonSize.large ? double.infinity : null,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: color.withValues(alpha: 0.5),
          elevation: 0,
          shadowColor: Colors.transparent,
          side: const BorderSide(color: flowlyBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(size.radius),
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: size.height * 0.5,
                width: size.height * 0.5,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: size.fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}

enum FlowlyButtonSize {
  small(height: 36, radius: 8, fontSize: 12),
  medium(height: 44, radius: 10, fontSize: 14),
  large(height: 52, radius: 12, fontSize: 16);

  const FlowlyButtonSize({
    required this.height,
    required this.radius,
    required this.fontSize,
  });

  final double height;
  final double radius;
  final double fontSize;
}
