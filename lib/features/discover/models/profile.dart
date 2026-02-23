// lib/features/discover/models/profile.dart
class Profile {
  final String id;
  final String name;
  final int age;
  final String location; // city/state or just city
  final double? distanceMiles; // ← nullable (Supabase-friendly)
  final bool onlineNow;
  final DateTime lastActiveAt;
  final String photoUrl; // placeholder for now

  const Profile({
    required this.id,
    required this.name,
    required this.age,
    required this.location,
    this.distanceMiles,
    required this.onlineNow,
    required this.lastActiveAt,
    required this.photoUrl,
  });
}
