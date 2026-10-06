import 'package:flutter/material.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/user_repository.dart';

/// Form isian data diri. Dipakai saat pertama login (onboarding)
/// dan saat mengedit profil dari halaman Profil.
class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({super.key, required this.user, this.isOnboarding = false});

  final AppUser user;
  final bool isOnboarding;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _nama = TextEditingController(text: widget.user.namaLengkap);
  late final _sebutan = TextEditingController(text: widget.user.sebutan);
  late final _sekolah = TextEditingController(text: widget.user.sekolah);
  late final _kelas = TextEditingController(text: widget.user.kelas);
  late final _bio = TextEditingController(text: widget.user.bio);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_nama, _sebutan, _sekolah, _kelas, _bio]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await UserRepository.instance.save(widget.user.copyWith(
        namaLengkap: _nama.text,
        sebutan: _sebutan.text,
        sekolah: _sekolah.text,
        kelas: _kelas.text,
        bio: _bio.text,
      ));
      if (!mounted) return;
      if (!widget.isOnboarding) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil disimpan')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) =>
      (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isOnboarding ? 'Lengkapi profil' : 'Edit profil'),
        actions: [
          if (widget.isOnboarding)
            TextButton(
              onPressed: AuthService.instance.signOut,
              child: const Text('Keluar'),
            ),
        ],
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (widget.isOnboarding) ...[
                Text(
                  'Kenalan dulu, yuk! Data ini akan terlihat oleh temanmu di chat.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
              ],
              TextFormField(
                controller: _nama,
                decoration: const InputDecoration(labelText: 'Nama lengkap *'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: _required,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sebutan,
                decoration: const InputDecoration(
                  labelText: 'Sebutan / nama panggilan *',
                  helperText: 'Dipakai untuk menyapamu, mis. "Gun"',
                ),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                maxLength: 30,
                validator: _required,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sekolah,
                decoration: const InputDecoration(labelText: 'Sekolah / kampus'),
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _kelas,
                decoration: const InputDecoration(labelText: 'Kelas / jurusan'),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bio,
                decoration: const InputDecoration(labelText: 'Bio singkat'),
                maxLines: 3,
                maxLength: 150,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isOnboarding ? 'Lanjut' : 'Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
