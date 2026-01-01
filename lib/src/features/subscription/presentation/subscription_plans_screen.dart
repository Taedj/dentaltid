import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dentaltid/src/shared/widgets/activation_dialog.dart';
import 'package:dentaltid/src/core/remote_config_service.dart';
import 'package:dentaltid/src/features/finance/domain/purchase_order.dart';
import 'package:uuid/uuid.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState
    extends ConsumerState<SubscriptionPlansScreen> {
  String _selectedDuration = 'yearly'; // monthly, yearly, lifetime
  String _selectedCurrency = 'DZD';

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).value;
    final remoteConfig = ref.watch(remoteConfigProvider);
    final currentPlan = userProfile?.plan ?? SubscriptionPlan.trial;

    return Scaffold(
      backgroundColor: const Color(0xFF080A0E),
      body: remoteConfig.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF10B981)),
        ),
        error: (err, stack) => Center(
          child: Text(
            'Error: $err',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        data: (config) => Stack(
          children: [
            // Background Effects
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF10B981).withAlpha(13),
                ),
                child: BackdropFilter(
                  filter: ui.ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  leading: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  title: Text(
                    'Choose Your Plan',
                    style: GoogleFonts.outfit(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  centerTitle: true,
                  pinned: true,
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24.0,
                      vertical: 40,
                    ),
                    child: Column(
                      children: [
                        _buildCurrencySelector(config),
                        const SizedBox(height: 32),
                        _buildDurationToggle(),
                        const SizedBox(height: 48),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Wrap(
                              spacing: 24,
                              runSpacing: 24,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildPlanCard(
                                  context,
                                  config,
                                  'Trial',
                                  'FOR EVALUATION (30 DAYS)',
                                  Icons.timer_outlined,
                                  const Color(0xFF10B981),
                                  [
                                    'Max 100 Patients',
                                    'Max 100 Appointments',
                                    'Local Backup Only',
                                    'All Features Unlocked',
                                  ],
                                  isCurrent:
                                      currentPlan == SubscriptionPlan.trial,
                                  price: 'Free',
                                ),
                                _buildPlanCard(
                                  context,
                                  config,
                                  'Premium',
                                  'FOR STANDARD CLINICS',
                                  Icons.star_rounded,
                                  const Color(0xFF10B981),
                                  [
                                    'Unlimited Patients & Appointments',
                                    'Cloud Sync & Restore',
                                    'Secure Local Backup',
                                    'Whatsapp Reminders',
                                    'Standard Support',
                                  ],
                                  isCurrent:
                                      currentPlan ==
                                      SubscriptionPlan.professional,
                                  price: _getPrice('premium', config),
                                ),
                                _buildPlanCard(
                                  context,
                                  config,
                                  'CROWN',
                                  'FOR POWER USERS',
                                  Icons.diamond_outlined,
                                  const Color(0xFF10B981),
                                  [
                                    'Everything in Premium',
                                    'Advanced Analytics Tab',
                                    'Digital Prescriptions',
                                    'Priority Support',
                                    'Future AI Features',
                                  ],
                                  isCurrent:
                                      currentPlan ==
                                      SubscriptionPlan.enterprise,
                                  price: _getPrice('crown', config),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 60),
                        _buildActivationLink(),
                        const SizedBox(height: 40),
                        Text(
                          'Need a custom Enterprise solution? Contact us directly.',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationLink() {
    return TextButton(
      onPressed: () {
        final uid = ref.read(userProfileProvider).value?.uid ?? '';
        if (uid.isNotEmpty) {
          showDialog(
            context: context,
            builder: (context) => ActivationDialog(uid: uid),
          );
        }
      },
      child: Text(
        'I already have an activation code',
        style: GoogleFonts.outfit(
          color: const Color(0xFF10B981).withAlpha(204),
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  String _getPrice(String tier, RemoteConfig config) {
    if (tier.toLowerCase() == 'trial') return 'Free';

    final pricing = config.pricing;
    if (pricing.isEmpty || !pricing.containsKey(_selectedCurrency)) {
      return 'N/A';
    }

    final currencyConfig = pricing[_selectedCurrency];
    if (currencyConfig is! Map) return 'N/A';

    final symbol = currencyConfig['symbol'] ?? '';
    final position = currencyConfig['position'] ?? 'suffix';
    final plans = currencyConfig['plans'];

    if (plans == null ||
        plans is! Map ||
        plans[tier.toLowerCase()] == null ||
        plans[tier.toLowerCase()] is! Map ||
        plans[tier.toLowerCase()][_selectedDuration] == null) {
      return 'N/A';
    }

    final priceValue = plans[tier.toLowerCase()][_selectedDuration];

    String formattedPrice = position == 'prefix'
        ? '$symbol$priceValue'
        : '$priceValue $symbol';

    if (_selectedDuration == 'monthly') formattedPrice += ' /mo';
    if (_selectedDuration == 'yearly') formattedPrice += ' /yr';

    return formattedPrice;
  }

  Widget _buildCurrencySelector(RemoteConfig config) {
    final currencies = config.pricing.keys.isNotEmpty
        ? config.pricing.keys.toList()
        : ['DZD', 'USD', 'EUR'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(13)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: currencies.map((c) {
          final isSelected = _selectedCurrency == c;
          return GestureDetector(
            onTap: () => setState(() => _selectedCurrency = c),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF10B981)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                c,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDurationToggle() {
    final durations = ['monthly', 'yearly', 'lifetime'];
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withAlpha(26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: durations.map((d) {
          final isSelected = _selectedDuration == d;
          return GestureDetector(
            onTap: () => setState(() => _selectedDuration = d),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                d[0].toUpperCase() + d.substring(1),
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    RemoteConfig config,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<String> features, {
    bool isCurrent = false,
    required String price,
  }) {
    final canUpgrade = !isCurrent;

    return Container(
      width: 320,
      height: 580,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1117),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isCurrent ? color.withAlpha(128) : Colors.white.withAlpha(13),
          width: 2,
        ),
        boxShadow: [
          if (isCurrent)
            BoxShadow(
              color: color.withAlpha(26),
              blurRadius: 40,
              spreadRadius: 0,
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.outfit(
              fontSize: 11,
              color: const Color(0xFF10B981),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            price,
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: features
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.check,
                              color: Color(0xFF10B981),
                              size: 18,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                f,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.white.withAlpha(153),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: !canUpgrade ? null : () => _contactSales(title, price),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(13),
                disabledBackgroundColor: Colors.white.withAlpha(5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: canUpgrade
                        ? Colors.white.withAlpha(26)
                        : Colors.transparent,
                  ),
                ),
                elevation: 0,
              ),
              child: Text(
                !isCurrent ? 'Select Plan' : 'Current Plan',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: isCurrent ? Colors.white38 : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _contactSales(String targetPlan, String price) async {
    final userProfile = ref.read(userProfileProvider).value;
    final uid = userProfile?.uid ?? 'unknown';
    final email = userProfile?.email ?? 'unknown';

    final config = ref.read(remoteConfigProvider).value;
    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Could not retrieve contact information. Please try again later.',
          ),
        ),
      );
      return;
    }

    if (targetPlan == 'Trial') return; // Cannot purchase trial

    // --- Create Pending Order ---
    final order = PurchaseOrder(
      id: const Uuid().v4(),
      userId: uid,
      userEmail: email,
      dentistName: userProfile?.dentistName,
      plan: targetPlan == 'CROWN'
          ? SubscriptionPlan.enterprise
          : SubscriptionPlan.professional,
      durationLabel: _selectedDuration,
      priceLabel: price,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
    );

    try {
      await ref.read(firebaseServiceProvider).createPurchaseOrder(order);
    } catch (e) {
      debugPrint('Error creating order: $e');
    }

    final message = Uri.encodeComponent(
      'Hello DentalTID, I want to upgrade to *$targetPlan* ($_selectedDuration) for $price.\n\nMy User ID: $uid\nOrder Ref: ${order.id.substring(0, 8)}',
    );

    final waNumber = config.supportPhone
        .replaceAll(RegExp(r'\s+'), '')
        .replaceAll('+', '');
    final waUrl = 'https://wa.me/$waNumber?text=$message';

    if (await canLaunchUrl(Uri.parse(waUrl))) {
      await launchUrl(Uri.parse(waUrl));
    } else {
      final emailUrl =
          'mailto:${config.supportEmail}?subject=Upgrade to $targetPlan&body=$message';
      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Could not launch contact method. Please contact ${config.supportPhone}',
              ),
            ),
          );
        }
      }
    }
  }
}
