import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';

class AdviceField extends StatelessWidget {
  const AdviceField({
    required this.advice,
    super.key,
  });

  static const emptyAdvice = 'No advice available yet.';

  final String advice;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(18),
      color: Theme.of(context).colorScheme.primary,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: AppTheme.iconColor.withValues(alpha: 0.25),
          ),
        ),
        child: Text(
          advice.isNotEmpty ? '"$advice"' : emptyAdvice,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontSize: 22,
                height: 1.35,
              ),
        ),
      ),
    );
  }
}
