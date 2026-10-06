import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/bahasa.dart';
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
  late final _username = TextEditingController(text: widget.user.username);
  late Peran? _peran = widget.user.peran;
  late final _sekolah = TextEditingController(text: widget.user.sekolah);
  late final _kelas = TextEditingController(text: widget.user.kelas);
  late final _bio = TextEditingController(text: widget.user.bio);
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [_nama, _sebutan, _username, _sekolah, _kelas, _bio]) {
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
        username: _username.text.trim().toLowerCase(),
        peran: _peran,
        sekolah: _sekolah.text,
        kelas: _kelas.text,
        bio: _bio.text,
      ));
      if (!mounted) return;
      if (!widget.isOnboarding) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(tr('Profil disimpan'))),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is UsernameDipakai ? e.toString() : tr('Gagal menyimpan: {error}', {'error': e}))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? tr('Wajib diisi') : null;

  String? _cekUsername(String? v) {
    final u = (v ?? '').trim().toLowerCase();
    if (u.isEmpty) return tr('Wajib diisi, dipakai teman untuk mencarimu');
    if (u.length < 3) return tr('Minimal 3 huruf');
    if (!polaUsername.hasMatch(u)) return tr('Hanya huruf kecil, angka, titik (.), dan garis bawah (_)');
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(tr(widget.isOnboarding ? 'Lengkapi profil' : 'Edit profil')),
        actions: [
          if (widget.isOnboarding)
            TextButton(
              onPressed: AuthService.instance.signOut,
              child: Text(tr('Keluar')),
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
                label: tr('Nama lengkap'),
                icon: Icons.badge_outlined,
                kapital: TextCapitalization.words,
                validator: _required,
              ),
              _Isian(
                controller: _sebutan,
                label: tr('Nama panggilan'),
                icon: Icons.waving_hand_outlined,
                kapital: TextCapitalization.words,
                maxLength: 30,
                validator: _required,
              ),
              _Isian(
                controller: _username,
                label: tr('Username'),
                icon: Icons.alternate_email_rounded,
                awalan: '@',
                maxLength: 20,
                validator: _cekUsername,
                bantuan: tr('Teman mencarimu dengan username ini. Harus unik.'),
                format: [
                  FilteringTextInputFormatter.allow(RegExp('[a-zA-Z0-9._]')),
                  _HurufKecil(),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(tr('Kegiatan'), style: Theme.of(context).textTheme.titleSmall),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final p in Peran.values)
                      ChoiceChip(
                        label: Text(tr(p.label)),
                        selected: _peran == p,
                        onSelected: (_) => setState(() => _peran = p),
                      ),
                  ],
                ),
              ),
              _Isian(
                controller: _sekolah,
                label: tr(_peran?.labelTempat ?? 'Sekolah / kampus / perusahaan'),
                icon: _peran == Peran.pekerja ? Icons.business_outlined : Icons.school_outlined,
                kapital: TextCapitalization.words,
              ),
              _Isian(
                controller: _kelas,
                label: tr(_peran?.labelPosisi ?? 'Kelas / jurusan / jabatan'),
                icon: _peran == Peran.pekerja ? Icons.work_outline_rounded : Icons.class_outlined,
                kapital: _peran == Peran.pekerja ? TextCapitalization.words : TextCapitalization.none,
              ),
              _Isian(
                controller: _bio,
                label: tr('Bio'),
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
                    : Text(tr(widget.isOnboarding ? 'Lanjut' : 'Simpan')),
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
    this.awalan,
    this.bantuan,
    this.format,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextCapitalization kapital;
  final String? Function(String?)? validator;
  final int? maxLength;
  final int maxLines;
  final bool terakhir;
  final String? awalan;
  final String? bantuan;
  final List<TextInputFormatter>? format;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          prefixText: awalan,
          helperText: bantuan,
          prefixIcon:
              maxLines > 1 ? Padding(padding: const EdgeInsets.only(bottom: 44), child: Icon(icon)) : Icon(icon),
          alignLabelWithHint: maxLines > 1,
        ),
        textCapitalization: kapital,
        textInputAction: terakhir ? TextInputAction.done : TextInputAction.next,
        maxLines: maxLines,
        maxLength: maxLength,
        // Penghitung huruf hanya untuk bio, agar jarak antar kolom tetap rapi.
        buildCounter:
            maxLines > 1 ? null : (context, {required currentLength, required isFocused, required maxLength}) => null,
        validator: validator,
        inputFormatters: format,
        autocorrect: format == null,
      ),
    );
  }
}

/// Mengubah ketikan menjadi huruf kecil (untuk username).
class _HurufKecil extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toLowerCase());
}
