// lib/features/auth/login_page.dart
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
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

    // Helpful debug: confirm what URL the compiled build is using.
    // On Vercel, if you still see "yourproject.supabase.co", your build env is wrong / cached.
    if (kDebugMode) {
      const envUrl = String.fromEnvironment('SUPABASE_URL');
      debugPrint('LOGIN: SUPABASE_URL env => $envUrl');
      debugPrint('LOGIN: origin => ${kIsWeb ? Uri.base.origin : "(not web)"}');
    }

    // If user is already logged in, bounce them out of the login screen.
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
    // Do NOT trim password; allow leading/trailing spaces if user set them.
    if (v.isEmpty) return 'Password is required';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text; // don't trim password

    final emailErr = _validateEmail(email);
    final passErr = _validatePassword(password);

    if (emailErr != null || passErr != null) {
      _toast(emailErr ?? passErr!);
      return;
    }

    setState(() => _loading = true);

    try {
      // Debug sanity check for the deployed build:
      // if the env is missing, Supabase calls will hit placeholders.
      if (kDebugMode) {
        const envUrl = String.fromEnvironment('SUPABASE_URL');
        if (envUrl.isEmpty || envUrl.contains('yourproject')) {
          debugPrint('LOGIN WARNING: SUPABASE_URL env looks wrong => $envUrl');
        }
      }

      await ref
          .read(authControllerProvider.notifier)
          .login(email: email, password: password);

      // ✅ After successful login, the session should exist.
      final session = Supabase.instance.client.auth.currentSession;
      if (session == null) {
        throw Exception(
          'Login succeeded but session is missing. '
          'This usually means the app is not using the correct Supabase config.',
        );
      }

      if (!mounted) return;
      context.go('/discover');
    } on AuthException catch (e) {
      if (!mounted) return;

      final msg = e.message;

      // Friendly message for common web failure (CORS / wrong env / cached old build)
      if (msg.toLowerCase().contains('failed to fetch')) {
        final origin = kIsWeb ? Uri.base.origin : '';
        _toast(
          'Network error (Failed to fetch).\n\n'
          'Common causes:\n'
          '1) Vercel build missing SUPABASE_URL / SUPABASE_ANON_KEY (Flutter web needs --dart-define at build time)\n'
          '2) Supabase CORS missing: $origin\n'
          '3) Old cached service worker (Flutter PWA) — clear site data/unregister SW.\n',
        );
        return;
      }

      _toast(msg);
    } catch (e) {
      if (!mounted) return;
      _toast(e.toString());
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
