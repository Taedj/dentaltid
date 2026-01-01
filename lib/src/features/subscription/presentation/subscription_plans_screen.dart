import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/core/user_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dentaltid/src/shared/widgets/activation_dialog.dart';
import 'package:dentaltid/src/core/firebase_service.dart';
import 'package:dentaltid/src/core/remote_config_service.dart';
import 'package:dentaltid/src/features/finance/domain/purchase_order.dart';
import 'package:uuid/uuid.dart';

class SubscriptionPlansScreen extends ConsumerStatefulWidget {
  const SubscriptionPlansScreen({super.key});

  @override
  ConsumerState<SubscriptionPlansScreen> createState() =>
      _SubscriptionPlansScreenState();
}

class _SubscriptionPlansScreenState extends ConsumerState<SubscriptionPlansScreen> {
  String _selectedDuration = 'yearly'; // monthly, yearly, lifetime
  String _selectedCurrency = 'DZD';

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).value;
    final remoteConfig = ref.watch(remoteConfigProvider);
    final currentPlan = userProfile?.plan ?? SubscriptionPlan.trial;

    return Scaffold(
      body: remoteConfig.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (config) => Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
            ),
          ),
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(
                  'Upgrade Your Practice',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                backgroundColor: Colors.transparent,
                elevation: 0,
                centerTitle: true,
                pinned: true,
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildCurrencySelector(config),
                      const SizedBox(height: 24),
                      _buildDurationToggle(),
                      const SizedBox(height: 32),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 900) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildPlanCard(context, config, 'Premium', 'For Standard Clinics', Icons.star_rounded, Colors.amber.shade700, ['Unlimited Duration', 'Unlimited Patients', 'Cloud Sync & Restore', 'Secure Local Backup'], isCurrent: currentPlan == SubscriptionPlan.professional, isRecommended: true, price: _getPrice('premium', config)),
                                const SizedBox(width: 24),
                                _buildPlanCard(context, config, 'CROWN', 'For Power Users', Icons.diamond_outlined, Colors.purple, ['Everything in Premium', 'Advanced Analytics', 'Digital Prescriptions', 'Priority Support'], isCurrent: currentPlan == SubscriptionPlan.enterprise, price: _getPrice('crown', config)),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildPlanCard(context, config, 'Premium', 'For Standard Clinics', Icons.star_rounded, Colors.amber.shade700, ['Unlimited Duration', 'Unlimited Patients', 'Cloud Sync & Restore', 'Secure Local Backup'], isCurrent: currentPlan == SubscriptionPlan.professional, isRecommended: true, price: _getPrice('premium', config)),
                                const SizedBox(height: 24),
                                _buildPlanCard(context, config, 'CROWN', 'For Power Users', Icons.diamond_outlined, Colors.purple, ['Everything in Premium', 'Advanced Analytics', 'Digital Prescriptions', 'Priority Support'], isCurrent: currentPlan == SubscriptionPlan.enterprise, price: _getPrice('crown', config)),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {
                          final uid = ref.read(userProfileProvider).value?.uid ?? '';
                          if (uid.isNotEmpty) {
                            showDialog(context: context, builder: (context) => ActivationDialog(uid: uid));
                          }
                        },
                        child: Text('I already have an activation code', style: GoogleFonts.poppins(decoration: TextDecoration.underline, color: Colors.blue.shade300)),
                      ),
                      const SizedBox(height: 40),
                      const Text('Need a custom Enterprise solution? Contact us directly.', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPrice(String tier, RemoteConfig config) {
    final pricing = config.pricing;
    if (pricing.isEmpty || !pricing.containsKey(_selectedCurrency)) return 'N/A';

    final currencyConfig = pricing[_selectedCurrency];
    if (currencyConfig is! Map) return 'N/A';

    final symbol = currencyConfig['symbol'] ?? '';
    final position = currencyConfig['position'] ?? 'suffix';
    final plans = currencyConfig['plans'];
    
    if (plans == null || plans is! Map || plans[tier] == null || plans[tier] is! Map || plans[tier][_selectedDuration] == null) return 'N/A';
    
    final priceValue = plans[tier][_selectedDuration];
    
    String formattedPrice = position == 'prefix' ? '$symbol$priceValue' : '$priceValue $symbol';
    
    if (_selectedDuration == 'monthly') formattedPrice += ' /mo';
    if (_selectedDuration == 'yearly') formattedPrice += ' /yr';
    
    return formattedPrice;
  }

  Widget _buildCurrencySelector(RemoteConfig config) {
    final currencies = config.pricing.keys.isNotEmpty ? config.pricing.keys.toList() : ['DZD'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currencies.contains(_selectedCurrency) ? _selectedCurrency : currencies.first,
          dropdownColor: const Color(0xFF1E293B),
          items: currencies.map((c) => DropdownMenuItem(
            value: c,
            child: Text(c, style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white)),
          )).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCurrency = val);
          },
          icon: const Icon(Icons.currency_exchange, size: 18, color: Colors.white70),
        ),
      ),
    );
  }

  Widget _buildDurationToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton('Monthly', 'monthly'),
          _toggleButton('Yearly', 'yearly'),
          _toggleButton('Lifetime', 'lifetime'),
        ],
      ),
    );
  }

  Widget _toggleButton(String label, String value) {
    final isSelected = _selectedDuration == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedDuration = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.white70,
            fontWeight: FontWeight.w600,
          ),
        ),
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
    bool isRecommended = false,
    required String price,
  }) {
    // A premium user should be able to upgrade to crown.
    final canUpgrade = !isCurrent;

    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B).withOpacity(0.5),
            borderRadius: BorderRadius.circular(24),
            border: isRecommended
                ? Border.all(color: color, width: 2)
                : Border.all(color: Colors.white.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                price,
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Divider(height: 32, color: Colors.white12),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f,
                            style: GoogleFonts.poppins(fontSize: 14, color: Colors.white.withOpacity(0.9)),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: canUpgrade
                    ? ElevatedButton(
                        onPressed: title == 'Trial' ? null : () => _contactSales(title, price),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: title == 'Trial' ? Colors.grey : color,
                          disabledBackgroundColor: Colors.grey.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          title == 'Trial' ? 'Free Forever' : 'Subscribe Now',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    : OutlinedButton(
                        onPressed: null,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Current Plan',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            color: Colors.white54,
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
        if (isRecommended)
          Positioned(
            top: -12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'RECOMMENDED',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  void _contactSales(String plan, String price) async {
    final userProfile = ref.read(userProfileProvider).value;
    final uid = userProfile?.uid ?? 'unknown';
    final email = userProfile?.email ?? 'unknown';
    
    final config = ref.read(remoteConfigProvider); // Dynamic Config

    // --- Create Pending Order ---
    final order = PurchaseOrder(
      id: const Uuid().v4(),
      userId: uid,
      userEmail: email,
      dentistName: userProfile?.dentistName,
      plan: plan == 'CROWN' ? SubscriptionPlan.enterprise : SubscriptionPlan.professional,
      durationLabel: _selectedDuration,
      priceLabel: price,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
    );

    try {
      // Create order in Firestore (fire and forget mostly, but we await to ensure ID exists if we want to ref it)
      await ref.read(firebaseServiceProvider).createPurchaseOrder(order);
    } catch (e) {
      debugPrint('Error creating order: $e');
    }
    // ----------------------------

    // Hybrid Payment Flow: Message to WhatsApp/Email
    // Added Order Ref to message
    final message = Uri.encodeComponent(
        'Hello DentalTID, I want to upgrade to *$plan* ($_selectedDuration) for $price.\n\nMy User ID: $uid\nOrder Ref: ${order.id.substring(0,8)}');
    
    // Prioritize WhatsApp if available, else Email
    // Clean phone number for URL (remove + or spaces if needed, but WA usually handles it)
    final waNumber = config.supportPhone.replaceAll(RegExp(r'\s+'), '').replaceAll('+', '');
    final waUrl = 'https://wa.me/$waNumber?text=$message'; 
    
    if (await canLaunchUrl(Uri.parse(waUrl))) {
      await launchUrl(Uri.parse(waUrl));
    } else {
      // Fallback to Email
      final emailUrl = 'mailto:${config.supportEmail}?subject=Upgrade to $plan&body=$message';
      if (await canLaunchUrl(Uri.parse(emailUrl))) {
        await launchUrl(Uri.parse(emailUrl));
      } else {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not launch contact method. Please contact ${config.supportPhone}')),
          );
        }
      }
    }
  }
}
