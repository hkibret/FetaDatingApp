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
  final _location = TextEditingController();

  Uint8List? _pickedBytes;
  String? _pickedExt;
  String? _pickedContentType;

  bool _saving = false;

  String? _prefilledForUserId;

  String? _gender;
  String? _interestedIn;
  String? _bodyType;
  String? _smoking;
  String? _drinking;
  String? _datingIntent;
  String? _hasKids;
  String? _religion;
  String? _education;
  int? _heightCm;

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _bio.dispose();
    _location.dispose();
    super.dispose();
  }

  void _prefill(Profile p) {
    _name.text = p.name ?? '';
    _age.text = p.age?.toString() ?? '';
    _bio.text = p.bio ?? '';
    _location.text = p.location ?? '';

    _gender = p.gender;
    _interestedIn = p.interestedIn;
    _bodyType = p.bodyType;
    _heightCm = p.heightCm;
    _smoking = p.smoking;
    _drinking = p.drinking;
    _datingIntent = p.datingIntent;
    _hasKids = p.hasKids;
    _religion = p.religion;
    _education = p.education;
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

      if (_pickedBytes != null) {
        avatarUrl = await repo.uploadAvatarBytes(
          _pickedBytes!,
          ext: _pickedExt ?? 'jpg',
          contentType: _pickedContentType ?? 'image/jpeg',
        );
      }

      final parsedAge = int.tryParse(_age.text.trim());
      final parsedHeight = _heightCm;

      await repo.upsertProfile(
        name: _name.text.trim().isEmpty ? null : _name.text.trim(),
        age: parsedAge,
        bio: _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        location: _location.text.trim().isEmpty ? null : _location.text.trim(),
        avatarUrl: avatarUrl,
        gender: _gender,
        interestedIn: _interestedIn,
        onboardingCompleted: true,
        bodyType: _bodyType,
        heightCm: parsedHeight,
        smoking: _smoking,
        drinking: _drinking,
        datingIntent: _datingIntent,
        hasKids: _hasKids,
        religion: _religion,
        education: _education,
      );

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

          final currentId = p.id;
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
                controller: _location,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(labelText: 'Gender'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Male')),
                  DropdownMenuItem(value: 'female', child: Text('Female')),
                ],
                onChanged: _saving ? null : (v) => setState(() => _gender = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _interestedIn,
                decoration: const InputDecoration(labelText: 'Interested In'),
                items: const [
                  DropdownMenuItem(value: 'male', child: Text('Men')),
                  DropdownMenuItem(value: 'female', child: Text('Women')),
                  DropdownMenuItem(value: 'everyone', child: Text('Everyone')),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _interestedIn = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _bodyType,
                decoration: const InputDecoration(labelText: 'Body Type'),
                items: const [
                  DropdownMenuItem(value: 'slim', child: Text('Slim')),
                  DropdownMenuItem(value: 'average', child: Text('Average')),
                  DropdownMenuItem(value: 'athletic', child: Text('Athletic')),
                  DropdownMenuItem(value: 'curvy', child: Text('Curvy')),
                  DropdownMenuItem(value: 'plus', child: Text('Plus')),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _bodyType = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                value: _heightCm,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                items: List.generate(
                  71,
                  (i) => DropdownMenuItem(
                    value: 140 + i,
                    child: Text('${140 + i} cm'),
                  ),
                ),
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _heightCm = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _smoking,
                decoration: const InputDecoration(labelText: 'Smoking'),
                items: const [
                  DropdownMenuItem(value: 'no', child: Text('No')),
                  DropdownMenuItem(
                    value: 'sometimes',
                    child: Text('Sometimes'),
                  ),
                  DropdownMenuItem(value: 'yes', child: Text('Yes')),
                ],
                onChanged: _saving ? null : (v) => setState(() => _smoking = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _drinking,
                decoration: const InputDecoration(labelText: 'Drinking'),
                items: const [
                  DropdownMenuItem(value: 'no', child: Text('No')),
                  DropdownMenuItem(
                    value: 'sometimes',
                    child: Text('Sometimes'),
                  ),
                  DropdownMenuItem(value: 'yes', child: Text('Yes')),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _drinking = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _datingIntent,
                decoration: const InputDecoration(labelText: 'Dating Intent'),
                items: const [
                  DropdownMenuItem(
                    value: 'serious',
                    child: Text('Serious relationship'),
                  ),
                  DropdownMenuItem(
                    value: 'casual',
                    child: Text('Casual dating'),
                  ),
                  DropdownMenuItem(value: 'marriage', child: Text('Marriage')),
                  DropdownMenuItem(
                    value: 'friendship',
                    child: Text('Friendship first'),
                  ),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _datingIntent = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _hasKids,
                decoration: const InputDecoration(labelText: 'Has Kids'),
                items: const [
                  DropdownMenuItem(value: 'no', child: Text('No')),
                  DropdownMenuItem(value: 'yes', child: Text('Yes')),
                  DropdownMenuItem(
                    value: 'want_kids',
                    child: Text('Want kids someday'),
                  ),
                  DropdownMenuItem(value: 'open', child: Text('Open to kids')),
                ],
                onChanged: _saving ? null : (v) => setState(() => _hasKids = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _religion,
                decoration: const InputDecoration(labelText: 'Religion'),
                items: const [
                  DropdownMenuItem(
                    value: 'christian',
                    child: Text('Christian'),
                  ),
                  DropdownMenuItem(value: 'muslim', child: Text('Muslim')),
                  DropdownMenuItem(value: 'jewish', child: Text('Jewish')),
                  DropdownMenuItem(value: 'hindu', child: Text('Hindu')),
                  DropdownMenuItem(value: 'none', child: Text('None')),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _religion = v),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _education,
                decoration: const InputDecoration(labelText: 'Education'),
                items: const [
                  DropdownMenuItem(
                    value: 'high_school',
                    child: Text('High school'),
                  ),
                  DropdownMenuItem(value: 'college', child: Text('College')),
                  DropdownMenuItem(
                    value: 'bachelors',
                    child: Text('Bachelors'),
                  ),
                  DropdownMenuItem(value: 'masters', child: Text('Masters')),
                  DropdownMenuItem(
                    value: 'doctorate',
                    child: Text('Doctorate'),
                  ),
                  DropdownMenuItem(value: 'other', child: Text('Other')),
                ],
                onChanged: _saving
                    ? null
                    : (v) => setState(() => _education = v),
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
