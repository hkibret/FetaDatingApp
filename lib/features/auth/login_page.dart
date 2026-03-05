import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  @override
  void initState() {
    super.initState();

    // If user is already logged in, bounce them out of the login screen.
    // (Helps avoid "session? false" confusion when the app restored a session.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = Supabase.instance.client.auth.currentSession;
      if (session != null && mounted) {
        context.go('/discover');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String v) {
    final s = v.trim();
    if (s.isEmpty) return 'Email is required';
    if (!s.contains('@') || !s.contains('.')) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String v) {
    if (v.trim().isEmpty) return 'Password is required';
    if (v.trim().length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  Future<void> _login() async {
    final email = _emailController.text;
    final password = _passwordController.text;

    final emailErr = _validateEmail(email);
    final passErr = _validatePassword(password);

    if (emailErr != null || passErr != null) {
      final msg = emailErr ?? passErr!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    setState(() => _loading = true);

    try {
      await ref
          .read(authControllerProvider.notifier)
          .login(email: email.trim(), password: password.trim());

      // ✅ After successful login, the session should exist.
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception(
          'Login succeeded but session is missing. Try again (or check Supabase auth settings).',
        );
      }

      // Navigate after login. (Router redirect may also handle this, but this is explicit.)
      if (!mounted) return;
      context.go('/discover');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 8),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'you@example.com',
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              obscureText: _obscure,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => canSubmit ? _login() : null,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  onPressed: _loading
                      ? null
                      : () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
            ),

            // ✅ FORGOT PASSWORD
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _loading
                    ? null
                    : () => context.push('/forgot-password'),
                child: const Text('Forgot Password?'),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: canSubmit ? _login : null,
                child: Text(_loading ? 'Signing in…' : 'Login'),
              ),
            ),

            const SizedBox(height: 12),

            TextButton(
              onPressed: _loading ? null : () => context.go('/register'),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}
