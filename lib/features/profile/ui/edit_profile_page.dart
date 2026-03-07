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
  final _location = TextEditingController();

  List<String> _existingPhotos = [];
  final List<Uint8List> _newPhotos = [];
  final List<String> _newExt = [];
  final List<String> _newContentType = [];

  bool _saving = false;

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

    _existingPhotos = [...p.photos];
  }

  Future<void> _pickPhotos() async {
    final picker = ImagePicker();

    final files = await picker.pickMultiImage(imageQuality: 85);

    if (files.isEmpty) return;

    if ((_existingPhotos.length + _newPhotos.length + files.length) > 6) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Maximum 6 photos allowed")));
      return;
    }

    for (final f in files) {
      final bytes = await f.readAsBytes();

      final parts = f.name.split('.');
      final ext = parts.length > 1 ? parts.last : 'jpg';

      String type = 'image/jpeg';
      if (ext == 'png') type = 'image/png';
      if (ext == 'webp') type = 'image/webp';

      _newPhotos.add(bytes);
      _newExt.add(ext);
      _newContentType.add(type);
    }

    setState(() {});
  }

  void _deleteExistingPhoto(int index) {
    setState(() {
      _existingPhotos.removeAt(index);
    });
  }

  void _deleteNewPhoto(int index) {
    setState(() {
      _newPhotos.removeAt(index);
      _newExt.removeAt(index);
      _newContentType.removeAt(index);
    });
  }

  Future<void> _save(Profile current) async {
    setState(() => _saving = true);

    try {
      final repo = ref.read(profileRepoProvider);

      final uploadedUrls = [..._existingPhotos];

      for (int i = 0; i < _newPhotos.length; i++) {
        final url = await repo.uploadGalleryPhotoBytes(
          _newPhotos[i],
          ext: _newExt[i],
          contentType: _newContentType[i],
        );

        uploadedUrls.add(url);
      }

      String? avatarUrl;

      if (uploadedUrls.isNotEmpty) {
        avatarUrl = uploadedUrls.first;
      }

      await repo.upsertProfile(
        name: _name.text,
        age: int.tryParse(_age.text),
        bio: _bio.text,
        location: _location.text,
        avatarUrl: avatarUrl,
        photos: uploadedUrls,
        onboardingCompleted: true,
      );

      ref.invalidate(myProfileProvider);

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Save failed: $e")));
    }

    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profile")),

      body: profileAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),

        error: (e, _) => Center(child: Text("Error: $e")),

        data: (p) {
          if (p == null) {
            return const Center(child: Text("Profile not found"));
          }

          if (_existingPhotos.isEmpty) {
            _prefill(p);
          }

          final totalPhotos = [
            ..._existingPhotos,
            ..._newPhotos.map((e) => "memory"),
          ];

          return ListView(
            padding: const EdgeInsets.all(16),

            children: [
              const Text(
                "Photos",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              SizedBox(
                height: 120,
                child: ReorderableListView.builder(
                  scrollDirection: Axis.horizontal,

                  itemCount: totalPhotos.length,

                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;

                    final item = totalPhotos.removeAt(oldIndex);
                    totalPhotos.insert(newIndex, item);

                    setState(() {
                      _existingPhotos = totalPhotos
                          .whereType<String>()
                          .toList();
                    });
                  },

                  itemBuilder: (context, index) {
                    final isExisting = index < _existingPhotos.length;

                    return Container(
                      key: ValueKey(index),
                      margin: const EdgeInsets.only(right: 10),
                      width: 100,
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),

                            child: isExisting
                                ? Image.network(
                                    _existingPhotos[index],
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 120,
                                  )
                                : Image.memory(
                                    _newPhotos[index - _existingPhotos.length],
                                    fit: BoxFit.cover,
                                    width: 100,
                                    height: 120,
                                  ),
                          ),

                          Positioned(
                            right: 0,
                            top: 0,
                            child: GestureDetector(
                              onTap: () {
                                if (isExisting) {
                                  _deleteExistingPhoto(index);
                                } else {
                                  _deleteNewPhoto(
                                    index - _existingPhotos.length,
                                  );
                                }
                              },

                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),

                          if (index == 0)
                            const Positioned(
                              bottom: 5,
                              left: 5,
                              child: Chip(label: Text("Main")),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              ElevatedButton.icon(
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text("Add Photos"),
                onPressed: _pickPhotos,
              ),

              const SizedBox(height: 30),

              TextField(
                controller: _name,
                decoration: const InputDecoration(labelText: "Name"),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _age,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: "Age"),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _location,
                decoration: const InputDecoration(labelText: "Location"),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: _bio,
                maxLines: 4,
                decoration: const InputDecoration(labelText: "Bio"),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _saving ? null : () => _save(p),

                child: _saving
                    ? const CircularProgressIndicator()
                    : const Text("Save Profile"),
              ),
            ],
          );
        },
      ),
    );
  }
}
