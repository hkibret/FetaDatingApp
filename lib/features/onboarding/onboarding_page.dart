import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'onboarding_controller.dart';
// OPTIONAL (recommended): if your router gates onboarding via AuthState
import '../auth/auth_controller.dart'; // ✅ adjust path if needed

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  int step = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final ctrl = ref.read(onboardingControllerProvider.notifier);

    // ✅ Don't rely on state.value being non-null during loading/errors
    final answers = state.value;

    final isLoading = state.isLoading;
    final isLast = step == 4;

    Widget body;
    String title;

    if (step == 0) {
      title = 'How would you describe your body type?';
      body = _RadioList(
        value: answers?.bodyType,
        options: const [
          'Petite',
          'Slim',
          'Athletic',
          'Average',
          'Few Extra Pounds',
          'Full Figured',
          'Large and Lovely',
        ],
        onChanged: ctrl.setBodyType,
      );
    } else if (step == 1) {
      title = 'What are you looking for?';
      body = _RadioList(
        value: answers?.datingIntent,
        options: const [
          'Serious relationship',
          'Casual dating',
          'Friends',
          'Not sure yet',
        ],
        onChanged: ctrl.setDatingIntent,
      );
    } else if (step == 2) {
      title = 'Do you smoke?';
      body = _RadioList(
        value: answers?.smoking,
        options: const ['No', 'Sometimes', 'Yes'],
        onChanged: ctrl.setSmoking,
      );
    } else if (step == 3) {
      title = 'Do you drink?';
      body = _RadioList(
        value: answers?.drinking,
        options: const ['No', 'Sometimes', 'Yes'],
        onChanged: ctrl.setDrinking,
      );
    } else {
      title = 'Do you have kids?';
      body = _RadioList(
        value: answers?.hasKids,
        options: const ['No', 'Yes', 'Prefer not to say'],
        onChanged: ctrl.setHasKids,
      );
    }

    bool canNext() {
      if (answers == null) return false;
      switch (step) {
        case 0:
          return answers.bodyType != null;
        case 1:
          return answers.datingIntent != null;
        case 2:
          return answers.smoking != null;
        case 3:
          return answers.drinking != null;
        case 4:
          return answers.hasKids != null;
        default:
          return false;
      }
    }

    Future<void> finish() async {
      FocusScope.of(context).unfocus();

      try {
        await ref.read(onboardingControllerProvider.notifier).submit();

        // ✅ If you are gating onboarding via AuthState, this prevents being forced back
        ref.read(authControllerProvider.notifier).markOnboardingCompleted();

        if (!mounted) return;
        context.go('/discover');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    }

    Future<void> skip() async {
      // If you want skip to truly skip onboarding permanently:
      // - either mark completed locally
      // - or update profiles.onboarding_completed in DB
      //
      // Quick dev behavior: mark as completed locally so router doesn't trap you.
      ref.read(authControllerProvider.notifier).markOnboardingCompleted();

      if (!mounted) return;
      context.go('/discover');
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${step + 1}/5'),
        actions: [
          TextButton(
            onPressed: isLoading ? null : skip,
            child: const Text('Skip'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Expanded(child: body),

            if (state.hasError) ...[
              const SizedBox(height: 8),
              Text(
                state.error.toString(),
                style: const TextStyle(color: Colors.red),
              ),
            ],

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isLoading || step == 0
                        ? null
                        : () => setState(() => step -= 1),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: isLoading || !canNext()
                        ? null
                        : () async {
                            if (!isLast) {
                              setState(() => step += 1);
                              return;
                            }
                            await finish();
                          },
                    child: Text(
                      isLast ? (isLoading ? 'Saving…' : 'Finish') : 'Next',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RadioList extends StatelessWidget {
  final String? value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _RadioList({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: options.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final opt = options[i];
        return RadioListTile<String>(
          value: opt,
          groupValue: value,
          onChanged: (v) {
            if (v == null) return;
            onChanged(v);
          },
          title: Text(opt),
        );
      },
    );
  }
}
