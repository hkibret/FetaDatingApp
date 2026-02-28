// lib/features/onboarding/onboarding_model.dart

class OnboardingAnswers {
  final String? bodyType; // Petite / Slim / Athletic / etc.
  final String? datingIntent; // Serious / Casual / Friends / etc.
  final String? smoking; // No / Sometimes / Yes
  final String? drinking; // No / Sometimes / Yes
  final String? hasKids; // No / Yes / Prefer not to say

  const OnboardingAnswers({
    this.bodyType,
    this.datingIntent,
    this.smoking,
    this.drinking,
    this.hasKids,
  });

  OnboardingAnswers copyWith({
    String? bodyType,
    String? datingIntent,
    String? smoking,
    String? drinking,
    String? hasKids,
  }) {
    return OnboardingAnswers(
      bodyType: bodyType ?? this.bodyType,
      datingIntent: datingIntent ?? this.datingIntent,
      smoking: smoking ?? this.smoking,
      drinking: drinking ?? this.drinking,
      hasKids: hasKids ?? this.hasKids,
    );
  }

  /// ✅ Used by onboarding_controller.submit()
  /// - Does NOT include null values (prevents overwriting existing data)
  /// - ALWAYS marks onboarding as completed
  Map<String, dynamic> toProfileUpdateJson() {
    final Map<String, dynamic> json = {};

    if (bodyType != null) json['body_type'] = bodyType;
    if (datingIntent != null) json['dating_intent'] = datingIntent;
    if (smoking != null) json['smoking'] = smoking;
    if (drinking != null) json['drinking'] = drinking;
    if (hasKids != null) json['has_kids'] = hasKids;

    // 🚨 CRITICAL FLAG — router + auth rely on this
    json['onboarding_completed'] = true;

    return json;
  }
}
