class Profile {
  Profile({required this.id, this.name, this.age, this.bio, this.avatarUrl});

  final String id;
  final String? name;
  final int? age;
  final String? bio;
  final String? avatarUrl;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      name: map['name'] as String?,
      age: map['age'] as int?,
      bio: map['bio'] as String?,
      avatarUrl: map['avatar_url'] as String?,
    );
  }
}
