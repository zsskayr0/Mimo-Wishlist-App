import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../shell/home_shell.dart';
import 'login_screen.dart';

/// Root traffic cop: shows the Feed (inside HomeShell) once someone's
/// signed in, the login/signup screen otherwise. Rebuilds on every auth
/// state change (sign in, sign out, token refresh).
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final client = Supabase.instance.client;

    return StreamBuilder<AuthState>(
      stream: client.auth.onAuthStateChange,
      initialData: AuthState(AuthChangeEvent.initialSession, client.auth.currentSession),
      builder: (context, snapshot) {
        final session = snapshot.data?.session ?? client.auth.currentSession;
        return session == null ? const LoginScreen() : const HomeShell();
      },
    );
  }
}
