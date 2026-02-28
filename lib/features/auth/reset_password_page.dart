// lib/features/auth/reset_password_page.dart
import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  bool _loading = false;
  bool _ready = false;
  bool _showPass = false;
  bool _showConfirm = false;

  StreamSubscription<AuthState>? _authSub;

  SupabaseClient get _sb => Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    _passCtrl.addListener(_rebuild);
    _confirmCtrl.addListener(_rebuild);

    _authSub = _sb.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      if (event == AuthChangeEvent.passwordRecovery ||
          event == AuthChangeEvent.signedIn ||
          event == AuthChangeEvent.tokenRefreshed) {
        if (mounted) {
          setState(() => _ready = _sb.auth.currentSession != null);
        }
      }
    });

    unawaited(_ensureRecoverySession());
  }

  void _rebuild() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _passCtrl.removeListener(_rebuild);
    _confirmCtrl.removeListener(_rebuild);
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  bool _looksStrongEnough(String pass) => pass.length >= 8;

  bool _containsAny(String haystack, List<String> needles) =>
      needles.any((n) => haystack.contains(n));

  /// Ensures a recovery session exists before allowing updateUser(password).
  /// Supports:
  /// - Web PKCE: /reset-password?code=...
  /// - Web implicit: #access_token=...&refresh_token=...&type=recovery
  /// - Existing session
  Future<void> _ensureRecoverySession() async {
    try {
      // If session already exists, we’re good.
      if (_sb.auth.currentSession != null) {
        if (mounted) setState(() => _ready = true);
        return;
      }

      if (!kIsWeb) {
        // Mobile deep links require setup; without it, recovery won’t arrive here.
        if (mounted) setState(() => _ready = _sb.auth.currentSession != null);
        return;
      }

      final uri = Uri.base;
      final full = uri.toString();
      final frag = uri.fragment;
      final query = uri.query;

      debugPrint('RESET PAGE URL => $full');
      debugPrint('RESET query => $query');
      debugPrint('RESET fragment => $frag');

      // Decide if this page load is actually a recovery link
      final isRecoveryLink = _containsAny(full, [
        'type=recovery',
        'code=',
        'access_token=',
        'refresh_token=',
      ]);

      if (!isRecoveryLink) {
        // Not a recovery link load; don’t pretend we can create a session.
        if (mounted) setState(() => _ready = false);
        return;
      }

      // 1) PKCE: ?code=...
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) {
        debugPrint('RESET detected PKCE code');
        await _sb.auth.exchangeCodeForSession(code);
        await _waitForSession();
        if (mounted) setState(() => _ready = _sb.auth.currentSession != null);
        return;
      }

      // 2) Implicit: parse refresh_token from query/fragment/full string
      String? extract(String key) {
        final m = RegExp('$key=([^&]+)').firstMatch(full);
        if (m == null) return null;
        return Uri.decodeComponent(m.group(1)!);
      }

      final refreshToken = extract('refresh_token');
      if (refreshToken != null && refreshToken.isNotEmpty) {
        debugPrint('RESET detected refresh_token');
        await _sb.auth.setSession(refreshToken);
        await _waitForSession();
        if (mounted) setState(() => _ready = _sb.auth.currentSession != null);
        return;
      }

      // If we got here, we had a "recovery-ish" URL but no usable params.
      if (mounted) setState(() => _ready = false);
    } catch (e) {
      debugPrint('RESET ensureRecoverySession error: $e');
      if (mounted) setState(() => _ready = false);
    }
  }

  /// Wait a short time for Supabase to populate currentSession after code exchange.
  Future<void> _waitForSession() async {
    for (var i = 0; i < 30; i++) {
      if (_sb.auth.currentSession != null) return;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> _setNewPassword() async {
    FocusScope.of(context).unfocus();

    final pass = _passCtrl.text; // do NOT trim passwords
    final confirm = _confirmCtrl.text;

    if (!_looksStrongEnough(pass)) {
      _toast('Password must be at least 8 characters.');
      return;
    }
    if (pass != confirm) {
      _toast('Passwords do not match.');
      return;
    }

    setState(() => _loading = true);

    try {
      await _ensureRecoverySession();

      if (_sb.auth.currentSession == null) {
        _toast(
          'Recovery session not found.\n\n'
          'Fix checklist:\n'
          '1) Make sure ForgotPasswordPage uses redirectTo = ${Uri.base.origin}/reset-password\n'
          '2) Supabase Dashboard → Auth → URL Configuration must allow:\n'
          '   ${Uri.base.origin}\n'
          '   ${Uri.base.origin}/*\n'
          '3) Open the email link in the SAME Chrome browser/profile.',
        );
        return;
      }

      await _sb.auth.updateUser(UserAttributes(password: pass));

      _toast('Password updated. Please log in.');
      await _sb.auth.signOut();

      if (mounted) context.go('/login');
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Something went wrong: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    final pass = _passCtrl.text;
    final confirm = _confirmCtrl.text;

    final passOk = _looksStrongEnough(pass);
    final matchOk = pass.isNotEmpty && pass == confirm;

    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_ready) ...[
              const Text(
                'Waiting for recovery session…',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 6),
              const Text(
                'If this stays here, the reset link didn’t land in this app correctly.\n'
                'Tap “Reload session” and check the URL printed in console.',
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _loading ? null : _ensureRecoverySession,
                child: const Text('Reload session'),
              ),
              const SizedBox(height: 16),
            ],
            TextField(
              controller: _passCtrl,
              obscureText: !_showPass,
              decoration: InputDecoration(
                labelText: 'New password',
                helperText: 'At least 8 characters',
                errorText: pass.isEmpty || passOk ? null : 'Too short',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _showPass = !_showPass),
                  icon: Icon(
                    _showPass ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmCtrl,
              obscureText: !_showConfirm,
              decoration: InputDecoration(
                labelText: 'Confirm password',
                errorText: confirm.isEmpty || matchOk ? null : 'Does not match',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  icon: Icon(
                    _showConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                ),
              ),
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _loading ? null : _setNewPassword(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _setNewPassword,
              child: Text(_loading ? 'Saving…' : 'Update password'),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loading ? null : () => context.go('/login'),
              child: const Text('Back to login'),
            ),
          ],
        ),
      ),
    );
  }
}
