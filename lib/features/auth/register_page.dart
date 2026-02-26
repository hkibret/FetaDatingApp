import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'auth_controller.dart';

class RegisterPage extends ConsumerStatefulWidget {
  const RegisterPage({super.key});

  @override
  ConsumerState<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends ConsumerState<RegisterPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;

    final email = _email.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;

    // Basic validation
    if (email.isEmpty || password.isEmpty || confirm.isEmpty) {
      setState(() => _error = 'Email and passwords are required.');
      return;
    }
    if (password.length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }
    if (password != confirm) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      // ✅ IMPORTANT: register() should call Supabase auth signUp only.
      // It should NOT insert into profiles manually (your trigger does that).
      final result = await ref
          .read(authControllerProvider.notifier)
          .register(email: email, password: password, confirmPassword: confirm);

      if (!mounted) return;

      // ✅ Handle Supabase behavior:
      // If email confirmation is enabled, signUp succeeds but session is null.
      final session = result.session;
      final user = result.user;

      if (user != null && session == null) {
        // Account created, needs email confirmation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created! Please check your email to confirm, then log in.',
            ),
          ),
        );
        context.go('/login');
        return;
      }

      // Logged in immediately
      context.go('/discover');
    } catch (e) {
      // Clean message
      final msg = e.toString().replaceFirst('Exception: ', '');

      // If your backend still throws "Database error saving new user"
      // but you see the profile row created, this is likely a misleading
      // post-signup error. We'll show a nicer message.
      final friendly =
          msg.contains('Database error saving new user') ||
              msg.contains('unexpected_failure')
          ? 'Account may have been created. Try logging in. If email confirmation is enabled, confirm your email first.'
          : msg;

      if (mounted) setState(() => _error = friendly);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Email'),
                    enabled: !_loading,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'Password'),
                    enabled: !_loading,
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirm,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                    ),
                    enabled: !_loading,
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 16),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _loading ? null : _submit,
                      child: Text(_loading ? 'Creating...' : 'Create account'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading ? null : () => context.go('/login'),
                    child: const Text('Back to login'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
