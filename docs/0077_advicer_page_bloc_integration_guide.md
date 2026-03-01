# Integrating Advicer UI with BLoC (From Preview State to Real State Flow)

Reference: you can read [0076_bloc_state_management_guide.md](./0076_bloc_state_management_guide.md) first for core BLoC basics.  
This file focuses on how those BLoC basics were connected to the actual page.

## Conceptual Overview (Why these changes were made)

Before this update, the page used a local preview enum (`_AdvicerUiState`) to fake UI states like loading and success.

That is useful for design practice, but it is not real app behavior.

Now, the page uses `AdvicerBloc` directly:
- The button sends an event.
- The bloc handles logic.
- The UI rebuilds from emitted states.

Analogy:  
Before, the screen was like an actor reading a script with fake props.  
Now, the screen is connected to the real backstage team (BLoC), so the actor reacts to real signals.

## What Changed (High level)

1. `main.dart`
- `home` changed from `AdvicerPage` to `AdvicerPageWrapperProvider`.
- Reason: the page now needs a `BlocProvider` above it in the widget tree.

2. `advicer_page.dart`
- Added `AdvicerPageWrapperProvider` widget.
- Added `BlocProvider(create: ...)` to create `AdvicerBloc`.
- Replaced `_buildStateArea()` enum logic with `BlocBuilder<AdvicerBloc, AdvicerState>`.
- Removed preview enum and fake switch code.

3. `custom_button.dart`
- Removed callback parameter (`onTap`) from the button API.
- Button now dispatches `AdvicerRequestedEvent` directly through bloc.

## Syntax Breakdown (Beginner friendly)

- `StatelessWidget`
  - A widget with no mutable local state.
  - Here, state is handled by BLoC instead of inside widgets.

- `BlocProvider`
  - Creates and provides a bloc to child widgets.
  - Think: "make this bloc available in this part of the UI tree."

- `create: (context) => AdvicerBloc()`
  - Factory function to create the bloc instance.

- `BlocBuilder<AdvicerBloc, AdvicerState>`
  - Listens to bloc state updates and rebuilds UI when state changes.

- `if (state is SomeState)`
  - Type-check syntax to render different widgets for each state class.

- `BlocProvider.of<AdvicerBloc>(context).add(...)`
  - Gets the existing bloc instance from context and sends an event to it.

- `const`
  - Marks widgets as compile-time constants when possible.
  - Helps performance and code clarity.

## Code Walkthrough (Updated implementation with detailed comments)

```dart
// lib/main.dart
import 'package:advicer/2_application/core/services/theme_service.dart';
import 'package:advicer/2_application/pages/advicer/advicer_page.dart';
import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      // ThemeService is still managed with Provider.
      // This is separate from BLoC state for advice data.
      create: (context) => ThemeService(),
      child: const AdvicerApp(),
    ),
  );
}

class AdvicerApp extends StatelessWidget {
  const AdvicerApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeService = context.watch<ThemeService>();

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeService.currentThemeMode,
      // IMPORTANT CHANGE:
      // We no longer mount AdvicerPage directly.
      // We mount a wrapper that provides AdvicerBloc first.
      home: const AdvicerPageWrapperProvider(),
    );
  }
}
```

```dart
// lib/2_application/pages/advicer/advicer_page.dart
import 'package:advicer/2_application/core/services/theme_service.dart';
import 'package:advicer/2_application/core/widgets/custom_button.dart';
import 'package:advicer/2_application/pages/advicer/bloc/advicer_bloc.dart';
import 'package:advicer/2_application/pages/advicer/widgets/advice_field.dart';
import 'package:advicer/2_application/pages/advicer/widgets/error_message.dart';
import 'package:advicer/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// NEW: This wrapper's only job is dependency wiring.
// It creates AdvicerBloc and makes it available to AdvicerPage.
class AdvicerPageWrapperProvider extends StatelessWidget {
  const AdvicerPageWrapperProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // The bloc starts with AdvicerInitial state (from advicer_bloc.dart).
      create: (context) => AdvicerBloc(),
      // Child widgets below can read/listen to this bloc.
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Advicer'),
        actions: [
          IconButton(
            onPressed: themeService.toggleTheme,
            icon: Icon(
              themeService.currentThemeMode == ThemeMode.light
                  ? Icons.dark_mode
                  : Icons.light_mode,
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Expanded(
              child: Center(
                // IMPORTANT CHANGE:
                // Instead of a local preview enum, we now listen to real bloc states.
                child: BlocBuilder<AdvicerBloc, AdvicerState>(
                  builder: (context, state) {
                    // Initial state: user has not requested advice yet.
                    if (state is AdvicerInitial) {
                      return const Text(
                        'Your advice is waiting for you',
                        textAlign: TextAlign.center,
                      );
                    }
                    // Loading state: show spinner while bloc is "working".
                    else if (state is AdvicerStateLoading) {
                      return const CircularProgressIndicator(
                        color: AppTheme.actionColor,
                      );
                    }
                    // Loaded state: bloc returned advice text successfully.
                    else if (state is AdvicerStateLoaded) {
                      return AdviceField(advice: state.advice);
                    }
                    // Error state: bloc failed and returned message.
                    else if (state is AdvicerStateError) {
                      return ErrorMessage(message: state.message);
                    }

                    // Safety fallback (rare).
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ),
            SizedBox(
              width: double.infinity,
              height: 56,
              // Button no longer receives onTap from parent.
              // It dispatches the bloc event internally.
              child: const CustomButton(text: 'Get Advice'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
```

```dart
// lib/2_application/core/widgets/custom_button.dart
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
      // IMPORTANT CHANGE:
      // On tap, we get the existing AdvicerBloc from context
      // and add an event that means "user requested advice".
      onTap: () {
        BlocProvider.of<AdvicerBloc>(context).add(AdvicerRequestedEvent());
      },
      radius: 28,
      splashColor: AppTheme.actionColor.withValues(alpha: 0.2),
      highlightColor: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: AppTheme.actionColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Center(
          child: Text(
            text,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
```

## Data Flow (How state moves through the app)

1. User taps **Get Advice**.
2. `CustomButton` sends `AdvicerRequestedEvent` to `AdvicerBloc`.
3. `AdvicerBloc` emits `AdvicerStateLoading`.
4. `BlocBuilder` rebuilds and shows loading spinner.
5. `AdvicerBloc` emits either:
   - `AdvicerStateLoaded(advice: ...)` -> show advice text.
   - `AdvicerStateError(message: ...)` -> show error widget.
6. UI updates automatically because `BlocBuilder` is listening.

## Why this is the Flutter way (Best Practices)

- Single source of truth for feature state: bloc owns advice state.
- Separation of concerns: UI renders; bloc decides transitions.
- Easier testing: you can test event -> state flow without UI.
- Scalable architecture: adding retry/refresh becomes cleaner.
- Reusable widgets: page and state logic are less tightly coupled.

## Quick Tips

- If you see `BlocProvider.of<T>(context)` error, check that the widget is below the provider in the tree.
- If UI is not updating, verify states are being emitted in bloc and widget uses `BlocBuilder`.
- Use one clear state class per UI mode (`Initial`, `Loading`, `Loaded`, `Error`) to keep logic easy to reason about.
