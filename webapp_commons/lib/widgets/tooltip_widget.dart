import 'package:flutter/material.dart';

class TooltipWidget extends StatelessWidget {
  final String message;
  final double size;
  final Color? iconColor;
  final Color? borderColor;

  const TooltipWidget({
    super.key,
    required this.message,
    this.size = 16,
    this.iconColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      decoration: BoxDecoration(
        color: Colors.grey[800],
        borderRadius: BorderRadius.circular(4),
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      waitDuration: const Duration(milliseconds: 500),
      showDuration: const Duration(seconds: 3),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: borderColor ?? Colors.white,
            width: 1,
          ),
        ),
        child: Icon(
          Icons.help_outline,
          size: size,
          color: iconColor ?? Colors.grey[600],
        ),
      ),
    );
  }
}