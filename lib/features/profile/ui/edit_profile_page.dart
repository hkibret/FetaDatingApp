import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/profile_providers.dart';
import '../data/profile_model.dart';

class EditProfilePage extends ConsumerStatefulWidget {
  const EditProfilePage({super.key});

  @override
  ConsumerState<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends ConsumerState<EditProfilePage> {
  final _name = TextEditingController();
  final _age = TextEditingController();
  final _bio = TextEditingController();

  Uint8List? _pickedBytes;
  String? _pickedExt;
  String? _pickedContentType;

  bool _saving = false;
  bool _didPrefill = false;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _prefill(Profile p) {
    _name.text = p.name ?? '';
    _age.text = p.age?.toString() ?? '';
    _bio.text = p.bio ?? '';
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;

    final bytes = await x.readAsBytes();

    final ext = (x.name.split('.').length > 1)
        ? x.name.split('.').last.toLowerCase()
        : 'jpg';

    String contentType = 'image/jpeg';
    if (ext == 'png') contentType = 'image/png';
    if (ext == 'webp') contentType = 'image/webp';

    setState(() {
      _pickedBytes = bytes;
      _pickedExt = ext;
      _pickedContentType = contentType;
    });
  }

  Future<void> _save(Profile current) async {
    setState(() => _saving = true);
    try {
      final repo = ref.read(profileRepoProvider);

      String? avatarUrl = current.avatarUrl;

      // ✅ Upload new avatar if user picked one
      if (_pickedBytes != null) {
        avatarUrl = await repo.uploadAvatarBytes(
          _pickedBytes!,
          ext: _pickedExt ?? 'jpg',
          contentType: _pickedContentType ?? 'image/jpeg',
        );
      }

      final parsedAge = int.tryParse(_age.text.trim());

      // ✅ Persist avatarUrl along with name/age/bio
      await repo.upsertProfile(
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        age: parsedAge,
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        avatarUrl: avatarUrl,
      );

      // refresh profile
      ref.invalidate(myProfileProvider);

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (p) {
          if (p == null) return const Center(child: Text('No profile found'));

          // ✅ Prefill ONCE (no addPostFrameCallback spam)
          if (!_didPrefill) {
            _didPrefill = true;
            _prefill(p);
          }

          ImageProvider<Object>? avatarProvider;
          if (_pickedBytes != null) {
            avatarProvider = MemoryImage(_pickedBytes!);
          } else if (p.avatarUrl != null && p.avatarUrl!.isNotEmpty) {
            avatarProvider = NetworkImage(p.avatarUrl!);
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44,
                      backgroundImage: avatarProvider,
                      child: (avatarProvider == null)
                          ? const Icon(Icons.person, size: 44)
                          : null,
                    ),
                    TextButton.icon(
                      onPressed: _saving ? null : _pickImage,
                      icon: const Icon(Icons.photo),
                      label: const Text('Choose photo'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bio,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Bio'),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saving ? null : () => _save(p),
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
