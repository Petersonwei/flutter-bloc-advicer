import 'package:advicer/2_application/pages/advicer/bloc/advicer_bloc.dart';
import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CustomButton extends StatelessWidget {
  const CustomButton({
    required this.text,
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: () {
        BlocProvider.of<AdvicerBloc>(context).add(AdvicerRequestedEvent());
      },
      radius: 28,
      splashColor: AppTheme.actionColor.withValues(alpha: 0.2),
      highlightColor: Colors.transparent,
      child: Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(16),
        color: AppTheme.actionColor,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
      ),
    );
  }
}
