import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  bool _obscure1 = true;
  bool _obscure2 = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    // If already logged in, don't let user sit on Register.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && mounted) {
        context.go('/discover');
      }
    });
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _validateEmail(String v) {
    final s = v.trim();
    if (s.isEmpty) return 'Email is required.';
    if (!s.contains('@') || !s.contains('.')) return 'Enter a valid email.';
    return null;
  }

  String? _validatePassword(String v) {
    final s = v.trim();
    if (s.isEmpty) return 'Password is required.';
    if (s.length < 6) return 'Password must be at least 6 characters.';
    return null;
  }

  Future<void> _submit() async {
    if (_loading) return;

    final email = _email.text.trim();
    final password = _password.text;
    final confirm = _confirm.text;

    final emailErr = _validateEmail(email);
    final passErr = _validatePassword(password);
    if (emailErr != null) {
      setState(() => _error = emailErr);
      return;
    }
    if (passErr != null) {
      setState(() => _error = passErr);
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
      // ✅ register() should only call Supabase signUp
      // (profiles row should be created by trigger)
      final result = await ref
          .read(authControllerProvider.notifier)
          .register(email: email, password: password, confirmPassword: confirm);

      if (!mounted) return;

      // Supabase behavior:
      // - If email confirmation is ON -> user created, session is null
      // - If OFF -> user + session returned
      final session = result.session;
      final user = result.user;

      if (user != null && session == null) {
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
      if (!mounted) return;

      final raw = e.toString().replaceFirst('Exception: ', '');

      final friendly =
          (raw.contains('Database error saving new user') ||
              raw.contains('unexpected_failure'))
          ? 'Account may have been created. Try logging in. If email confirmation is enabled, confirm your email first.'
          : raw;

      setState(() => _error = friendly);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: AutofillGroup(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    TextField(
                      controller: _email,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'you@example.com',
                      ),
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _password,
                      enabled: !_loading,
                      obscureText: _obscure1,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        suffixIcon: IconButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() => _obscure1 = !_obscure1),
                          icon: Icon(
                            _obscure1 ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                    ),
                    const SizedBox(height: 12),

                    TextField(
                      controller: _confirm,
                      enabled: !_loading,
                      obscureText: _obscure2,
                      autofillHints: const [AutofillHints.newPassword],
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'Confirm password',
                        suffixIcon: IconButton(
                          onPressed: _loading
                              ? null
                              : () => setState(() => _obscure2 = !_obscure2),
                          icon: Icon(
                            _obscure2 ? Icons.visibility : Icons.visibility_off,
                          ),
                        ),
                      ),
                      onSubmitted: (_) => _loading ? null : _submit(),
                    ),

                    const SizedBox(height: 16),

                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                    ],

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: Text(_loading ? 'Creating…' : 'Create account'),
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
      ),
    );
  }
}
