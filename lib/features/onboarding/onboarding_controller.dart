import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_controller.dart'; // ✅ adjust path if needed
import 'onboarding_model.dart';

final onboardingControllerProvider =
    NotifierProvider<OnboardingController, AsyncValue<OnboardingAnswers>>(
      OnboardingController.new,
    );

class OnboardingController extends Notifier<AsyncValue<OnboardingAnswers>> {
  late final SupabaseClient _sb;

  @override
  AsyncValue<OnboardingAnswers> build() {
    _sb = Supabase.instance.client;
    return AsyncValue.data(const OnboardingAnswers());
  }

  OnboardingAnswers get _answers => state.value ?? const OnboardingAnswers();

  void setBodyType(String v) =>
      state = AsyncValue.data(_answers.copyWith(bodyType: v));
  void setDatingIntent(String v) =>
      state = AsyncValue.data(_answers.copyWith(datingIntent: v));
  void setSmoking(String v) =>
      state = AsyncValue.data(_answers.copyWith(smoking: v));
  void setDrinking(String v) =>
      state = AsyncValue.data(_answers.copyWith(drinking: v));
  void setHasKids(String v) =>
      state = AsyncValue.data(_answers.copyWith(hasKids: v));

  void reset() => state = AsyncValue.data(const OnboardingAnswers());

  Future<void> submit() async {
    final user = _sb.auth.currentUser;
    if (user == null) throw Exception('Not logged in');

    final answers = _answers;

    // ✅ Keep answers in memory; UI can still read `answers` before calling submit.
    // We set loading without copyWithPrevious to avoid AsyncValue<dynamic> issues.
    state = const AsyncValue.loading();

    try {
      await _sb
          .from('profiles')
          .update(
            answers.toProfileUpdateJson(),
          ) // ensure includes onboarding_completed: true
          .eq('id', user.id);

      state = AsyncValue.data(answers);

      // ✅ unlock router gate immediately
      ref.read(authControllerProvider.notifier).markOnboardingCompleted();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
