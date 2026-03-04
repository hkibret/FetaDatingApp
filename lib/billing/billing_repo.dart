import 'package:supabase_flutter/supabase_flutter.dart';
import 'billing_models.dart';

class BillingRepo {
  BillingRepo(this._sb);

  final SupabaseClient _sb;

  /// Calls Edge Function stripe-create-checkout and returns the checkout URL.
  Future<String> createCheckoutUrl({
    required String priceKey, // "gold_1m", "platinum_3m", etc.
  }) async {
    final session = _sb.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null) throw Exception('Not authenticated');

    final res = await _sb.functions.invoke(
      'stripe-create-checkout',
      body: {'price_key': priceKey},
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final data = res.data;
    if (data is Map && data['url'] is String) {
      return data['url'] as String;
    }
    throw Exception('Checkout URL missing from function response');
  }

  /// OPTIONAL: if you add a stripe-create-portal edge function
  Future<String> createPortalUrl() async {
    final session = _sb.auth.currentSession;
    final accessToken = session?.accessToken;
    if (accessToken == null) throw Exception('Not authenticated');

    final res = await _sb.functions.invoke(
      'stripe-create-portal',
      body: const {},
      headers: {'Authorization': 'Bearer $accessToken'},
    );

    final data = res.data;
    if (data is Map && data['url'] is String) {
      return data['url'] as String;
    }
    throw Exception('Portal URL missing from function response');
  }

  /// Reads `my_active_subscription` view.
  Future<ActiveSubscription?> fetchMyActiveSubscription() async {
    final rows = await _sb.from('my_active_subscription').select();
    if (rows is List && rows.isNotEmpty) {
      return ActiveSubscription.fromJson(rows.first as Map<String, dynamic>);
    }
    return null;
  }

  /// Reads `my_entitlements` view.
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
