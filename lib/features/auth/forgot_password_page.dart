import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  /// ✅ WEB: send recovery link to a callback route on the same origin.
  /// Example (local): http://localhost:49730/auth-callback
  /// Example (prod):  https://feta-dating-app.vercel.app/auth-callback
  ///
  /// ✅ MOBILE: custom scheme only works if you configured deep links.
  static String get _redirectTo {
    if (kIsWeb) {
      final origin = Uri.base.origin; // e.g. https://feta-dating-app.vercel.app
      return '$origin/auth-callback';
    }
    return 'feta://auth-callback';
  }

  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  bool _looksLikeEmail(String v) {
    // lightweight validation
    return v.contains('@') && v.contains('.') && v.length >= 6;
  }

  Future<void> _sendReset() async {
    FocusScope.of(context).unfocus();

    final email = _emailCtrl.text.trim().toLowerCase();

    if (email.isEmpty) {
      _toast('Enter your email.');
      return;
    }
    if (!_looksLikeEmail(email)) {
      _toast('Please enter a valid email address.');
      return;
    }

    setState(() => _loading = true);

    try {
      final redirect = _redirectTo;

      debugPrint('FORGOT PASSWORD redirectTo => $redirect');

      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirect,
      );

      _toast(
        kIsWeb
            ? 'Reset email sent. Open the link in this SAME browser (same Chrome profile) where the app is running.'
            : 'Reset email sent. Open it on this device to continue.',
      );

      if (mounted) Navigator.pop(context);
    } on AuthException catch (e) {
      final msg = e.message;
      final lower = msg.toLowerCase();

      // Supabase throws different variants of this depending on the SDK/version.
      final looksLikeRedirectIssue =
          lower.contains('redirect') ||
          lower.contains('url') ||
          lower.contains('allowed') ||
          lower.contains('not allowed') ||
          lower.contains('whitelist');

      if (looksLikeRedirectIssue) {
        final origin =
            Uri.base.origin; // shows the CURRENT host you are running on
        _toast(
          'Reset link failed due to redirect URL settings.\n\n'
          'Fix in Supabase Dashboard:\n'
          'Authentication → URL Configuration\n\n'
          'Set:\n'
          '• Site URL: $origin\n\n'
          'Add to "Additional Redirect URLs":\n'
          '• $origin/auth-callback\n'
          '• $origin/*\n\n'
          'Then click Save and request a NEW reset email.',
        );
      } else {
        _toast(msg);
      }
    } catch (e) {
      _toast('Something went wrong. Try again. ($e)');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 6)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipText = kIsWeb
        ? 'Tip: open the reset email link in this same browser (Chrome) where the app is running.'
        : 'Tip: open the reset email on the same phone/emulator where Feta is installed.';

    return Scaffold(
      appBar: AppBar(title: const Text('Forgot Password')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Enter your email and we’ll send you a reset link.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(tipText, style: const TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'name@example.com',
              ),
              onSubmitted: (_) => _loading ? null : _sendReset(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _sendReset,
                child: Text(_loading ? 'Sending…' : 'Send reset link'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
