import 'package:flutter/material.dart';

/// Placeholder. Daftar teman, chat pribadi, dan grup dibuat pada tahap 3.
class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.forum_outlined, size: 64, color: theme.colorScheme.outline),
              const SizedBox(height: 12),
              Text('Chat segera hadir', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              const Text(
                'Nanti kamu bisa chat dengan teman dan membuat grup di sini.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
