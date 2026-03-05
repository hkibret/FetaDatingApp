import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'billing_providers.dart';

class EntitlementsGate {
  static Future<bool> has(WidgetRef ref, String entitlement) async {
    final set = await ref.read(myEntitlementsProvider.future);
    return set.contains(entitlement);
  }
}
