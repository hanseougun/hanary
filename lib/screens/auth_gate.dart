import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';
import 'home_shell.dart';
import 'profile_form_screen.dart';
import 'welcome_screen.dart';

/// Menentukan halaman pertama:
/// belum login → Selamat datang, profil belum lengkap → isi profil,
/// sudah lengkap → Beranda.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const _Loading();
        }
        final user = authSnap.data;
        if (user == null) return const WelcomeScreen();
        return _ProfileGate(user: user);
      },
    );
  }
}

class _ProfileGate extends StatefulWidget {
  const _ProfileGate({required this.user});
  final User user;

  @override
  State<_ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<_ProfileGate> {
  late final Future<void> _init = UserRepository.instance.ensureExists(widget.user);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _init,
      builder: (context, initSnap) {
        if (initSnap.hasError) {
          return _ErrorView(message: 'Gagal memuat profil: ${initSnap.error}');
        }
        if (initSnap.connectionState != ConnectionState.done) {
          return const _Loading();
        }
        return StreamBuilder<AppUser?>(
          stream: UserRepository.instance.watch(widget.user.uid),
          builder: (context, snap) {
            final profile = snap.data;
            if (profile == null) return const _Loading();
            if (!profile.isComplete) {
              return ProfileFormScreen(user: profile, isOnboarding: true);
            }
            return HomeShell(user: profile);
          },
        );
      },
    );
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: AuthService.instance.signOut,
                child: const Text('Keluar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
