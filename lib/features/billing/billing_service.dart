// lib/features/billing/billing_service.dart
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class BillingService {
  const BillingService();

  Future<void> openExternalUrl(String url) async {
    final uri = Uri.tryParse(url);

    if (uri == null) {
      throw Exception('Invalid checkout URL: $url');
    }

    // Stripe checkout must always be https
    if (uri.scheme != 'https') {
      throw Exception('Checkout URL must use HTTPS');
    }

    try {
      // =========================
      // Web
      // =========================
      if (kIsWeb) {
        final launched = await launchUrl(
          uri,
          mode: LaunchMode.platformDefault,
          webOnlyWindowName: '_self',
        );

        if (!launched) {
          throw Exception('Could not open checkout URL in browser');
        }
        return;
      }

      // =========================
      // Mobile (iOS / Android)
      // =========================
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        throw Exception('Could not launch checkout URL');
      }
    } catch (e) {
      throw Exception('Failed to open checkout: $e');
    }
  }
}
