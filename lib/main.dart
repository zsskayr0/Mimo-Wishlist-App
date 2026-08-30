import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/layout/view_mode_controller.dart';
import 'core/theme/mimo_colors.dart';
import 'core/theme/mimo_text.dart';
import 'core/theme/theme_controller.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local/dev config lives in .env (gitignored). See .env.example.
  // In CI/release builds these are passed instead via --dart-define.
  await dotenv.load(fileName: '.env', isOptional: true);

  final supabaseUrl = dotenv.env['SUPABASE_URL'] ??
      const String.fromEnvironment('SUPABASE_URL');
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'] ??
      const String.fromEnvironment('SUPABASE_ANON_KEY');

  final configured = supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
  if (configured) {
    await Supabase.initialize(
      url: supabaseUrl,
      publishableKey: supabaseAnonKey,
    );
  }

  await ThemeController.initialize();
  await ViewModeController.initialize();

  runApp(MimoApp(supabaseConfigured: configured));
}

class MimoApp extends StatelessWidget {
  const MimoApp({super.key, required this.supabaseConfigured});

  final bool supabaseConfigured;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.instance.mode,
      builder: (context, themeMode, _) {
        return MaterialApp(
          title: 'Mimo',
          debugShowCheckedModeBanner: false,
          themeMode: themeMode,
          theme: _buildTheme(MimoColors.light, Brightness.light),
          darkTheme: _buildTheme(MimoColors.dark, Brightness.dark),
          scrollBehavior: _MouseDragScrollBehavior(),
          home: supabaseConfigured ? const AuthGate() : const _MissingEnvScreen(),
        );
      },
    );
  }

  ThemeData _buildTheme(MimoColors colors, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: MimoColors.gradientA,
        brightness: brightness,
      ),
      scaffoldBackgroundColor: colors.bg,
      textTheme: poppinsTextTheme(base.textTheme).apply(
        bodyColor: colors.ink,
        displayColor: colors.ink,
      ),
    );
  }
}

/// Shown when the app was built without .env / --dart-define values —
/// there's nowhere useful to route to without a Supabase connection.
class _MissingEnvScreen extends StatelessWidget {
  const _MissingEnvScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: MimoColors.gradient,
                ),
                child: const Icon(Icons.favorite, color: Colors.white),
              ),
              const SizedBox(height: 16),
              const Text('Mimo', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Copie .env.example para .env com suas chaves do Supabase.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Flutter's default `ScrollBehavior` only lets touch/stylus drag a
/// scrollable — a mouse click-and-drag does nothing on desktop unless a
/// platform-specific widget (like a `Scrollbar`) opts it in. Horizontal
/// rows like the Feed's tag chips have no such widget, so on Windows they
/// were only scrollable via a wheel that mostly doesn't map to a
/// horizontal axis. This adds mouse (and trackpad) to the drag devices
/// app-wide instead of special-casing every scrollable.
class _MouseDragScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };
}
