import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.text,
    this.onTap,
    super.key,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null;
    final buttonColor = isEnabled ? AppTheme.actionColor : Colors.red.shade300;
    final textColor = isEnabled ? Colors.white : Colors.black45;

    return InkResponse(
      onTap: onTap,
      radius: 28,
      splashColor: AppTheme.actionColor.withValues(alpha: 0.2),
      highlightColor: Colors.transparent,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: buttonColor,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
