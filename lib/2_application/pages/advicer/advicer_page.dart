import 'package:advicer/2_application/core/services/theme_service.dart';
import 'package:advicer/2_application/core/widgets/custom_button.dart';
import 'package:advicer/2_application/pages/advicer/widgets/advice_field.dart';
import 'package:advicer/2_application/pages/advicer/widgets/error_message.dart';
import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AdvicerPage extends StatelessWidget {
  const AdvicerPage({super.key});

  static const _previewState = _AdvicerUiState.initial;

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Advicer'),
        actions: [
          Switch(
            value: themeService.isDarkMode,
            onChanged: (_) => context.read<ThemeService>().toggleTheme(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: _buildStateArea(context),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: CustomButton(
                text: 'Get Advice',
                onTap: () => debugPrint('Get Advice button tapped'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStateArea(BuildContext context) {
    switch (_previewState) {
      case _AdvicerUiState.initial:
        return const Text(
          'Your advice is waiting for you',
          textAlign: TextAlign.center,
        );
      case _AdvicerUiState.loading:
        return const CircularProgressIndicator(color: AppTheme.actionColor);
      case _AdvicerUiState.success:
        return const AdviceField(
          advice: 'The only way to do great work is to love what you do.',
        );
      case _AdvicerUiState.error:
        return const ErrorMessage(
          message: 'Oops, something went wrong. Please try again.',
        );
    }
  }
}

enum _AdvicerUiState {
  initial,
  loading,
  success,
  error,
}
