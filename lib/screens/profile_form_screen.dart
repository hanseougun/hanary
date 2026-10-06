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
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              _Isian(
                controller: _nama,
                label: 'Nama lengkap',
                icon: Icons.badge_outlined,
                kapital: TextCapitalization.words,
                validator: _required,
              ),
              _Isian(
                controller: _sebutan,
                label: 'Nama panggilan',
                icon: Icons.waving_hand_outlined,
                kapital: TextCapitalization.words,
                maxLength: 30,
                validator: _required,
              ),
              _Isian(
                controller: _sekolah,
                label: 'Sekolah / kampus',
                icon: Icons.school_outlined,
                kapital: TextCapitalization.words,
              ),
              _Isian(
                controller: _kelas,
                label: 'Kelas / jurusan',
                icon: Icons.class_outlined,
              ),
              _Isian(
                controller: _bio,
                label: 'Bio',
                icon: Icons.edit_note_rounded,
                maxLines: 3,
                maxLength: 150,
                terakhir: true,
              ),
              const SizedBox(height: 8),
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

/// Satu kolom isian dengan ikon dan jarak yang seragam.
class _Isian extends StatelessWidget {
  const _Isian({
    required this.controller,
    required this.label,
    required this.icon,
    this.kapital = TextCapitalization.none,
    this.validator,
    this.maxLength,
    this.maxLines = 1,
    this.terakhir = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextCapitalization kapital;
  final String? Function(String?)? validator;
  final int? maxLength;
  final int maxLines;
  final bool terakhir;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: maxLines > 1
              ? Padding(padding: const EdgeInsets.only(bottom: 44), child: Icon(icon))
              : Icon(icon),
          alignLabelWithHint: maxLines > 1,
        ),
        textCapitalization: kapital,
        textInputAction: terakhir ? TextInputAction.done : TextInputAction.next,
        maxLines: maxLines,
        maxLength: maxLength,
        // Penghitung huruf hanya untuk bio, agar jarak antar kolom tetap rapi.
        buildCounter: maxLines > 1
            ? null
            : (context, {required currentLength, required isFocused, required maxLength}) => null,
        validator: validator,
      ),
    );
  }
}
