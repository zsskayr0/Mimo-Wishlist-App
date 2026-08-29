import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/theme/mimo_colors.dart';
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

  runApp(MimoApp(supabaseConfigured: configured));
}

class MimoApp extends StatelessWidget {
  const MimoApp({super.key, required this.supabaseConfigured});

  final bool supabaseConfigured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mimo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MimoColors.gradientA,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: MimoColors.bg,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: MimoColors.gradientA,
          brightness: Brightness.dark,
        ),
      ),
      home: supabaseConfigured ? const AuthGate() : const _MissingEnvScreen(),
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
