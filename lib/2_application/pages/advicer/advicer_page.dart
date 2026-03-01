import 'package:advicer/2_application/core/services/theme_service.dart';
import 'package:advicer/2_application/core/widgets/custom_button.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_cubit.dart';
import 'package:advicer/2_application/pages/advicer/cubit/advicer_state.dart';
import 'package:advicer/2_application/pages/advicer/widgets/advice_field.dart';
import 'package:advicer/2_application/pages/advicer/widgets/error_message.dart';
import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AdvicerPageWrapperProvider extends StatelessWidget {
  const AdvicerPageWrapperProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AdvicerCubit(),
      child: const AdvicerPage(),
    );
  }
}

class AdvicerPage extends StatelessWidget {
  const AdvicerPage({super.key});

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
                child: BlocBuilder<AdvicerCubit, AdvicerState>(
                  builder: (context, state) {
                    if (state is AdvicerInitial) {
                      return const Text(
                        'Your advice is waiting for you',
                        textAlign: TextAlign.center,
                      );
                    } else if (state is AdvicerStateLoading) {
                      return const CircularProgressIndicator(
                        color: AppTheme.actionColor,
                      );
                    } else if (state is AdvicerStateLoaded) {
                      return AdviceField(advice: state.advice);
                    } else if (state is AdvicerStateError) {
                      return ErrorMessage(message: state.message);
                    }

                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: const CustomButton(text: 'Get Advice'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
