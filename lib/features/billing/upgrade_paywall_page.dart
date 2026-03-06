import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'billing_service.dart';

enum PlanTier { gold, platinum }

class PricingOption {
  final String priceKey; // gold_1m, platinum_3m, etc.
  final int months;
  final double weeklyPrice;
  final double totalPrice;
  final int savePercent;
  final bool popular;

  const PricingOption({
    required this.priceKey,
    required this.months,
    required this.weeklyPrice,
    required this.totalPrice,
    required this.savePercent,
    required this.popular,
  });
}

class PaywallFeature {
  final IconData icon;
  final String title;
  final String subtitle;

  const PaywallFeature({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
}

class UpgradePaywallPage extends ConsumerStatefulWidget {
  const UpgradePaywallPage({super.key});

  @override
  ConsumerState<UpgradePaywallPage> createState() => _UpgradePaywallPageState();
}

class _UpgradePaywallPageState extends ConsumerState<UpgradePaywallPage> {
  final _pageController = PageController();
  int _featureIndex = 1;

  PlanTier _tier = PlanTier.platinum;
  bool _optIn = true;
  bool _checkoutLoading = false;

  String _selectedPriceKey = 'platinum_3m';

  final _features = const <PaywallFeature>[
    PaywallFeature(
      icon: Icons.chat_bubble_outline,
      title: 'Send unlimited communications',
      subtitle: 'Message without limits and keep the conversation going.',
    ),
    PaywallFeature(
      icon: Icons.trending_up,
      title: 'Rank above other members',
      subtitle:
          'As a premium member, your profile ranks above standard members in search results.',
    ),
    PaywallFeature(
      icon: Icons.lock_open,
      title: 'Unlock your messages',
      subtitle: 'See and reply to messages instantly with premium access.',
    ),
    PaywallFeature(
      icon: Icons.block,
      title: 'Say goodbye to ads',
      subtitle: 'Enjoy a cleaner experience with no ads.',
    ),
  ];

  List<PricingOption> get _options {
    if (_tier == PlanTier.gold) {
      return const [
        PricingOption(
          priceKey: 'gold_12m',
          months: 12,
          weeklyPrice: 3.54,
          totalPrice: 184.08,
          savePercent: 65,
          popular: false,
        ),
        PricingOption(
          priceKey: 'gold_3m',
          months: 3,
          weeklyPrice: 6.67,
          totalPrice: 79.99,
          savePercent: 33,
          popular: true,
        ),
        PricingOption(
          priceKey: 'gold_1m',
          months: 1,
          weeklyPrice: 10.00,
          totalPrice: 39.99,
          savePercent: 0,
          popular: false,
        ),
      ];
    }

    return const [
      PricingOption(
        priceKey: 'platinum_12m',
        months: 12,
        weeklyPrice: 3.54,
        totalPrice: 184.08,
        savePercent: 65,
        popular: false,
      ),
      PricingOption(
        priceKey: 'platinum_3m',
        months: 3,
        weeklyPrice: 6.67,
        totalPrice: 79.99,
        savePercent: 33,
        popular: true,
      ),
      PricingOption(
        priceKey: 'platinum_1m',
        months: 1,
        weeklyPrice: 10.00,
        totalPrice: 39.99,
        savePercent: 0,
        popular: false,
      ),
    ];
  }

  PricingOption get _selectedOption => _options.firstWhere(
    (o) => o.priceKey == _selectedPriceKey,
    orElse: () =>
        _options.firstWhere((o) => o.popular, orElse: () => _options[1]),
  );

  List<String> get _tierFeatures {
    if (_tier == PlanTier.gold) {
      return const ['Unlock your messages', 'Say goodbye to ads'];
    }
    return const [
      'Send unlimited communications',
      'Unlock your messages',
      'Say goodbye to ads',
      'Rank boost',
    ];
  }

  void _onTierChanged(PlanTier tier) {
    setState(() {
      _tier = tier;
      final months = _selectedOption.months;
      final nextKey = '${tier.name}_${months}m';
      _selectedPriceKey = _options.any((o) => o.priceKey == nextKey)
          ? nextKey
          : _options[1].priceKey;
    });
  }

  Future<void> _startCheckout(PricingOption selected) async {
    if (_checkoutLoading) return;

    final supabase = Supabase.instance.client;

    setState(() => _checkoutLoading = true);

    try {
      var session = supabase.auth.currentSession;
      var user = supabase.auth.currentUser;

      // If user/session not present, try a refresh once.
      if (session == null || user == null || session.accessToken.isEmpty) {
        try {
          final refreshed = await supabase.auth.refreshSession();
          session = refreshed.session;
          user = supabase.auth.currentUser;
        } catch (e) {
          debugPrint('CHECKOUT refreshSession failed => $e');
        }
      }

      debugPrint('CHECKOUT user id => ${user?.id}');
      debugPrint('CHECKOUT session exists => ${session != null}');
      debugPrint(
        'CHECKOUT token length => ${session?.accessToken.length ?? 0}',
      );

      if (user == null || session == null || session.accessToken.isEmpty) {
        throw Exception('No active session found. Please log in again.');
      }

      final response = await supabase.functions.invoke(
        'stripe-create-checkout',
        body: {'priceKey': selected.priceKey},
        headers: {'Authorization': 'Bearer ${session.accessToken}'},
      );

      final data = response.data;

      String? checkoutUrl;
      if (data is Map<String, dynamic>) {
        checkoutUrl = data['url'] as String?;
      } else if (data is Map) {
        checkoutUrl = data['url']?.toString();
      }

      if (checkoutUrl == null || checkoutUrl.isEmpty) {
        throw Exception(
          'Checkout URL was not returned by stripe-create-checkout.',
        );
      }

      debugPrint('Stripe checkout URL: $checkoutUrl');

      final service = BillingService();
      await service.openExternalUrl(checkoutUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Opening checkout...')));
    } on AuthException catch (e) {
      debugPrint('Checkout auth error: ${e.message}');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Auth error: ${e.message}')));
    } on FunctionException catch (e) {
      debugPrint('Checkout function error: $e');

      if (!mounted) return;

      final details = e.details?.toString() ?? '';
      final message = details.contains('Invalid JWT')
          ? 'Your session expired. Please log out and log back in, then try again.'
          : (details.isNotEmpty
                ? 'Checkout failed: $details'
                : 'Checkout failed: ${e.reasonPhrase ?? e.toString()}');

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (e) {
      debugPrint('Checkout failed: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Checkout failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _checkoutLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOption;

    const ctaHeight = 72.0;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Stack(
        children: [
          ListView(
            padding: EdgeInsets.only(bottom: ctaHeight + bottomInset + 12),
            children: [
              _TopCarousel(
                controller: _pageController,
                features: _features,
                index: _featureIndex,
                onChanged: (i) => setState(() => _featureIndex = i),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _TierSwitch(tier: _tier, onChanged: _onTierChanged),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 178,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  itemCount: _options.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, i) {
                    final opt = _options[i];
                    final isSelected = opt.priceKey == _selectedPriceKey;

                    return _PricingCard(
                      option: opt,
                      selected: isSelected,
                      onTap: () =>
                          setState(() => _selectedPriceKey = opt.priceKey),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _optIn,
                      onChanged: (v) => setState(() => _optIn = v ?? false),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'By opting in, you agree to our Terms and Privacy Policy.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Features:',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const Spacer(),
                    Text(
                      _tier == PlanTier.gold ? 'Gold' : 'Platinum',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ..._tierFeatures.map((f) => _FeatureRow(text: f)),
            ],
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SafeArea(
              top: false,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 16,
                      offset: Offset(0, -4),
                      color: Color(0x14000000),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 52,
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_optIn && !_checkoutLoading)
                        ? () => _startCheckout(selected)
                        : null,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      _checkoutLoading
                          ? 'Opening checkout...'
                          : 'Get ${selected.months} ${selected.months == 1 ? "month" : "months"} for \$${selected.totalPrice.toStringAsFixed(2)}',
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCarousel extends StatelessWidget {
  final PageController controller;
  final List<PaywallFeature> features;
  final int index;
  final ValueChanged<int> onChanged;

  const _TopCarousel({
    required this.controller,
    required this.features,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEFF5FF),
      padding: const EdgeInsets.only(top: 14, bottom: 10),
      child: Column(
        children: [
          SizedBox(
            height: 170,
            child: PageView.builder(
              controller: controller,
              onPageChanged: onChanged,
              itemCount: features.length,
              itemBuilder: (context, i) {
                final f = features[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(f.icon, size: 44, color: const Color(0xFF2F6BFF)),
                      const SizedBox(height: 12),
                      Text(
                        f.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        f.subtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodyMedium?.copyWith(color: Colors.black54),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(features.length, (i) {
              final active = i == index;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: active ? 10 : 8,
                height: active ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active
                      ? const Color(0xFF2F6BFF)
                      : const Color(0xFFD0DAF5),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _TierSwitch extends StatelessWidget {
  final PlanTier tier;
  final ValueChanged<PlanTier> onChanged;

  const _TierSwitch({required this.tier, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: const Color(0xFFF3F5F8),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: _TierPill(
              label: 'Gold',
              selected: tier == PlanTier.gold,
              onTap: () => onChanged(PlanTier.gold),
            ),
          ),
          Expanded(
            child: _TierPill(
              label: 'Platinum',
              selected: tier == PlanTier.platinum,
              onTap: () => onChanged(PlanTier.platinum),
            ),
          ),
        ],
      ),
    );
  }
}

class _TierPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TierPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: selected ? Colors.white : Colors.transparent,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: selected ? const Color(0xFF2F6BFF) : Colors.black54,
          ),
        ),
      ),
    );
  }
}

class _PricingCard extends StatelessWidget {
  final PricingOption option;
  final bool selected;
  final VoidCallback onTap;

  const _PricingCard({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? const Color(0xFF2F6BFF)
        : const Color(0xFFD5DCE8);
    final bg = selected ? const Color(0xFFEFF5FF) : Colors.white;

    return SizedBox(
      width: 140,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: borderColor, width: selected ? 2 : 1),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: LayoutBuilder(
                builder: (context, c) {
                  final compact = c.maxWidth <= 120;

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${option.months}',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        option.months == 1 ? 'month' : 'months',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: Colors.black54),
                      ),
                      SizedBox(height: compact ? 6 : 10),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '\$${option.weeklyPrice.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                color: selected
                                    ? const Color(0xFF2F6BFF)
                                    : Colors.black45,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                      Text(
                        'week',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: selected
                              ? const Color(0xFF2F6BFF)
                              : Colors.black45,
                        ),
                      ),
                      SizedBox(height: compact ? 8 : 10),
                      Flexible(
                        child: _SavePill(savePercent: option.savePercent),
                      ),
                    ],
                  );
                },
              ),
            ),
            if (option.popular)
              Positioned(
                top: -12,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2F6BFF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Text(
                      'POPULAR',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SavePill extends StatelessWidget {
  final int savePercent;

  const _SavePill({required this.savePercent});

  @override
  Widget build(BuildContext context) {
    final hasSave = savePercent > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: hasSave ? const Color(0xFF2F6BFF) : const Color(0xFFE6EAF2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        hasSave ? 'SAVE $savePercent%' : 'STANDARD',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: hasSave ? Colors.white : Colors.black54,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow({required this.text});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.check_circle, color: Color(0xFF2F6BFF)),
      title: Text(text),
      trailing: const Icon(Icons.check, color: Color(0xFF2F6BFF)),
    );
  }
}
