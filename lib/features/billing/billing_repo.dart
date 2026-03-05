import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'billing_models.dart';

class BillingRepo {
  BillingRepo(this._sb, {required this.anonKey});

  final SupabaseClient _sb;

  /// Your project's anon key (from --dart-define=SUPABASE_ANON_KEY=...)
  final String anonKey;

  Future<String> createCheckoutUrl({required String priceKey}) async {
    final session = _sb.auth.currentSession;
    final accessToken = session?.accessToken;
    final user = _sb.auth.currentUser;

    if (kDebugMode) {
      debugPrint("Billing checkout userId: ${user?.id}");
      debugPrint("Billing checkout token length: ${accessToken?.length ?? 0}");
      debugPrint("Billing checkout priceKey: $priceKey");
    }

    if (accessToken == null || accessToken.isEmpty) {
      throw Exception('User not authenticated (missing access token)');
    }

    final res = await _sb.functions.invoke(
      'stripe-create-checkout',
      body: {'price_key': priceKey},
      headers: {
        // ✅ Make both explicit for web reliability
        'apikey': anonKey,
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },
    );

    final data = res.data;

    if (kDebugMode) {
      debugPrint("Stripe checkout response: $data");
    }

    if (data is Map) {
      final url = data['url'];
      if (url is String && url.trim().isNotEmpty) return url.trim();

      final err = data['error'];
      final details = data['details'];
      if (err != null) {
        throw Exception('Checkout failed: $err ${details ?? ""}'.trim());
      }
    }

    throw Exception("Checkout URL missing from function response: $data");
  }

  Future<ActiveSubscription?> fetchMyActiveSubscription() async {
    final row = await _sb.from('my_active_subscription').select().maybeSingle();
    if (row == null) return null;
    return ActiveSubscription.fromJson(row as Map<String, dynamic>);
  }

  Future<List<Entitlement>> fetchMyEntitlements() async {
    final rows = await _sb.from('my_entitlements').select();
    if (rows is List) {
      return rows
          .map((e) => Entitlement.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}
