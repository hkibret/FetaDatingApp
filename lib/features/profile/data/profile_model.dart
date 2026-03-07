class Profile {
  Profile({
    required this.id,
    this.email,
    this.name,
    this.age,
    this.bio,
    this.location,
    this.avatarUrl,
    this.photos = const [],
    this.gender,
    this.interestedIn,
    this.onboardingCompleted,
    this.bodyType,
    this.heightCm,
    this.smoking,
    this.drinking,
    this.datingIntent,
    this.hasKids,
    this.religion,
    this.education,
  });

  final String id;
  final String? email;
  final String? name;
  final int? age;
  final String? bio;
  final String? location;
  final String? avatarUrl;
  final List<String> photos;

  // Matching fields
  final String? gender;
  final String? interestedIn;

  // Onboarding fields
  final bool? onboardingCompleted;
  final String? bodyType;
  final int? heightCm;
  final String? smoking;
  final String? drinking;
  final String? datingIntent;
  final String? hasKids;
  final String? religion;
  final String? education;

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      email: map['email'] as String?,
      name: map['name'] as String?,
      age: map['age'] as int?,
      bio: map['bio'] as String?,
      location: map['location'] as String?,
      avatarUrl: map['avatar_url'] as String?,
      photos:
          (map['photos'] as List?)?.map((e) => e.toString()).toList() ??
          const [],
      gender: map['gender'] as String?,
      interestedIn: map['interested_in'] as String?,
      onboardingCompleted: map['onboarding_completed'] as bool?,
      bodyType: map['body_type'] as String?,
      heightCm: map['height_cm'] as int?,
      smoking: map['smoking'] as String?,
      drinking: map['drinking'] as String?,
      datingIntent: map['dating_intent'] as String?,
      hasKids: map['has_kids'] as String?,
      religion: map['religion'] as String?,
      education: map['education'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'bio': bio,
      'location': location,
      'avatar_url': avatarUrl,
      'photos': photos,
      'gender': gender,
      'interested_in': interestedIn,
      'onboarding_completed': onboardingCompleted,
      'body_type': bodyType,
      'height_cm': heightCm,
      'smoking': smoking,
      'drinking': drinking,
      'dating_intent': datingIntent,
      'has_kids': hasKids,
      'religion': religion,
      'education': education,
    };
  }

  Profile copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? bio,
    String? location,
    String? avatarUrl,
    List<String>? photos,
    String? gender,
    String? interestedIn,
    bool? onboardingCompleted,
    String? bodyType,
    int? heightCm,
    String? smoking,
    String? drinking,
    String? datingIntent,
    String? hasKids,
    String? religion,
    String? education,
  }) {
    return Profile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      photos: photos ?? this.photos,
      gender: gender ?? this.gender,
      interestedIn: interestedIn ?? this.interestedIn,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      bodyType: bodyType ?? this.bodyType,
      heightCm: heightCm ?? this.heightCm,
      smoking: smoking ?? this.smoking,
      drinking: drinking ?? this.drinking,
      datingIntent: datingIntent ?? this.datingIntent,
      hasKids: hasKids ?? this.hasKids,
      religion: religion ?? this.religion,
      education: education ?? this.education,
    );
  }
}
