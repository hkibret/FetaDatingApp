import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
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

  // ✅ safer: track which profile we prefilling for
  String? _prefilledForUserId;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _prefill(Profile p) {
    _name.text = (p.name ?? '');
    _age.text = (p.age?.toString() ?? '');
    _bio.text = (p.bio ?? '');
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null) return;

    final bytes = await x.readAsBytes();

    final parts = x.name.split('.');
    final ext = (parts.length > 1) ? parts.last.toLowerCase() : 'jpg';

    String contentType = 'image/jpeg';
    if (ext == 'png') contentType = 'image/png';
    if (ext == 'webp') contentType = 'image/webp';

    if (!mounted) return;
    setState(() {
      _pickedBytes = bytes;
      _pickedExt = ext;
      _pickedContentType = contentType;
    });
  }

  Future<void> _save(Profile current) async {
    FocusScope.of(context).unfocus();

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

      await repo.upsertProfile(
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        age: parsedAge,
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        avatarUrl: avatarUrl,
      );

      // ✅ refresh profile
      ref.invalidate(myProfileProvider);

      if (!mounted) return;
      Navigator.pop(context);
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
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          TextButton(
            onPressed: _saving
                ? null
                : () async {
                    final p = profileAsync.maybeWhen(
                      data: (p) => p,
                      orElse: () => null,
                    );
                    if (p == null) return;
                    await _save(p);
                  },
            child: Text(_saving ? 'Saving…' : 'Save'),
          ),
        ],
      ),
      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Could not load your profile.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text('$e', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(myProfileProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (p) {
          if (p == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No profile found.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => ref.invalidate(myProfileProvider),
                    child: const Text('Reload'),
                  ),
                ],
              ),
            );
          }

          // ✅ Prefill ONCE per user id (prevents stale prefill + prevents rebuild spam)
          final currentId = p.id; // make sure Profile has id
          if (_prefilledForUserId != currentId) {
            _prefilledForUserId = currentId;
            _prefill(p);
          }

          Widget avatar;
          if (_pickedBytes != null) {
            avatar = CircleAvatar(
              radius: 44,
              backgroundImage: MemoryImage(_pickedBytes!),
            );
          } else if (p.avatarUrl != null && p.avatarUrl!.isNotEmpty) {
            // Optional: cache-bust on web if avatar changes often
            final url = kIsWeb
                ? '${p.avatarUrl!}?t=${DateTime.now().millisecondsSinceEpoch}'
                : p.avatarUrl!;
            avatar = CircleAvatar(
              radius: 44,
              backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
              child: ClipOval(
                child: Image.network(
                  url,
                  width: 88,
                  height: 88,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.person, size: 44),
                ),
              ),
            );
          } else {
            avatar = const CircleAvatar(
              radius: 44,
              child: Icon(Icons.person, size: 44),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Center(
                child: Column(
                  children: [
                    avatar,
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
