class ActiveSubscription {
  final String id;
  final String planId;
  final bool isActive;
  final DateTime? currentPeriodEnd;

  ActiveSubscription({
    required this.id,
    required this.planId,
    required this.isActive,
    this.currentPeriodEnd,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    return ActiveSubscription(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      isActive: json['is_active'] as bool? ?? false,
      currentPeriodEnd: json['current_period_end'] != null
          ? DateTime.parse(json['current_period_end'])
          : null,
    );
  }
}

class Entitlement {
  final String entitlement;

  Entitlement({required this.entitlement});

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    return Entitlement(entitlement: json['entitlement'] as String);
  }
}
