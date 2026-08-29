import 'package:flutter/material.dart';

import '../../core/theme/mimo_colors.dart';

/// Placeholder — solicitações, busca por @usuário e pastas compartilhadas
/// entram aqui numa próxima passada (depende de friendships + folder_members
/// já existirem no schema, o que já está feito).
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ComingSoon(
      title: 'Amigos',
      message: 'Solicitações, busca por @usuário e pastas compartilhadas chegam na próxima etapa.',
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: MimoColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
