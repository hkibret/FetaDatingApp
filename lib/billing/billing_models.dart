class ActiveSubscription {
  final String provider;
  final String status;
  final String? planId;
  final DateTime? currentPeriodEnd;
  final bool cancelAtPeriodEnd;

  ActiveSubscription({
    required this.provider,
    required this.status,
    required this.planId,
    required this.currentPeriodEnd,
    required this.cancelAtPeriodEnd,
  });

  factory ActiveSubscription.fromJson(Map<String, dynamic> json) {
    return ActiveSubscription(
      provider: (json['provider'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      planId: json['plan_id'] as String?,
      currentPeriodEnd: json['current_period_end'] == null
          ? null
          : DateTime.parse(json['current_period_end'] as String),
      cancelAtPeriodEnd: (json['cancel_at_period_end'] as bool?) ?? false,
    );
  }

  bool get isActive => status == 'active' || status == 'trialing';
}

class Entitlement {
  final String entitlement;
  final dynamic value; // jsonb
  final String planId;
  final String status;
  final DateTime? currentPeriodEnd;

  Entitlement({
    required this.entitlement,
    required this.value,
    required this.planId,
    required this.status,
    required this.currentPeriodEnd,
  });

  factory Entitlement.fromJson(Map<String, dynamic> json) {
    return Entitlement(
      entitlement: (json['entitlement'] as String?) ?? '',
      value: json['value'],
      planId: (json['plan_id'] as String?) ?? '',
      status: (json['status'] as String?) ?? '',
      currentPeriodEnd: json['current_period_end'] == null
          ? null
          : DateTime.parse(json['current_period_end'] as String),
    );
  }
}
