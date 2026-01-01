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
    final currentPlan = userProfile?.plan ?? SubscriptionPlan.trial;
    final isCrown = currentPlan == SubscriptionPlan.enterprise || currentPlan == SubscriptionPlan.trial; 
    // Note: Trial has Crown features, but is not "subscription" Crown.
    // Visually we want to distinguish "Active Plan".

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4F8), // Soft background
      appBar: AppBar(
        title: Text(
          'Upgrade Your Practice',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              _buildCurrencySelector(),
              const SizedBox(height: 24),
              _buildDurationToggle(),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                  // Responsive Layout
                  if (constraints.maxWidth > 900) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildPlanCard(
                          context,
                          'Trial',
                          'For Evaluation',
                          Icons.timer_outlined,
                          Colors.grey,
                          ['30 Days Access', 'Max 100 Patients', 'Max 100 Appointments', 'Local Backup Only', 'All Features Unlocked'],
                          isCurrent: currentPlan == SubscriptionPlan.trial,
                          price: 'Free',
                        ),
                        const SizedBox(width: 24),
                        _buildPlanCard(
                          context,
                          'Premium',
                          'For Standard Clinics',
                          Icons.star_rounded,
                          Colors.amber.shade700,
                          ['Unlimited Duration', 'Unlimited Patients', 'Unlimited Appointments', 'Cloud Sync & Restore', 'Secure Local Backup', 'Standard Support'],
                          isCurrent: currentPlan == SubscriptionPlan.professional,
                          isRecommended: true,
                          price: _getPrice('premium'),
                        ),
                        const SizedBox(width: 24),
                        _buildPlanCard(
                          context,
                          'CROWN',
                          'For Power Users',
                          Icons.diamond_outlined,
                          Colors.purple,
                          ['Everything in Premium', 'Advanced Analytics Tab', 'Digital Prescriptions', 'Priority Support', 'Future AI Features'],
                          isCurrent: currentPlan == SubscriptionPlan.enterprise,
                          price: _getPrice('crown'),
                        ),
                      ],
                    );
                  } else {
                    return Column(
                      children: [
                        _buildPlanCard(
                          context,
                          'Premium',
                          'For Standard Clinics',
                          Icons.star_rounded,
                          Colors.amber.shade700,
                          ['Unlimited Duration', 'Unlimited Patients', 'Unlimited Appointments', 'Cloud Sync & Restore', 'Secure Local Backup', 'Standard Support'],
                          isCurrent: currentPlan == SubscriptionPlan.professional,
                          isRecommended: true,
                          price: _getPrice('premium'),
                        ),
                        const SizedBox(height: 24),
                         _buildPlanCard(
                          context,
                          'CROWN',
                          'For Power Users',
                          Icons.diamond_outlined,
                          Colors.purple,
                          ['Everything in Premium', 'Advanced Analytics Tab', 'Digital Prescriptions', 'Priority Support', 'Future AI Features'],
                          isCurrent: currentPlan == SubscriptionPlan.enterprise,
                          price: _getPrice('crown'),
                        ),
                         const SizedBox(height: 24),
                        _buildPlanCard(
                          context,
                          'Trial',
                          'For Evaluation',
                          Icons.timer_outlined,
                          Colors.grey,
                          ['30 Days Access', 'Max 100 Patients', 'Max 100 Appointments', 'Local Backup Only', 'All Features Unlocked'],
                          isCurrent: currentPlan == SubscriptionPlan.trial,
                          price: 'Free',
                        ),
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
                    showDialog(
                      context: context,
                      builder:
                          (context) => ActivationDialog(uid: uid),
                    );
                  }
                },
                child: Text(
                  'I already have an activation code',
                  style: GoogleFonts.poppins(
                    decoration: TextDecoration.underline,
                    color: Colors.blue,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Need a custom Enterprise solution? Contact us directly.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getPrice(String tier) {
    final config = ref.read(remoteConfigProvider);
    final pricing = config.pricing[_selectedCurrency];
    if (pricing == null) return 'N/A';

    final symbol = pricing['symbol'] ?? '';
    final position = pricing['position'] ?? 'suffix';
    final plans = pricing['plans'];
    
    if (plans == null || plans[tier] == null) return 'N/A';
    
    final priceValue = plans[tier][_selectedDuration] ?? 'N/A';
    
    // Format: 2,000 DZD /mo or $15 /mo
    String formattedPrice = position == 'prefix' ? '$symbol$priceValue' : '$priceValue $symbol';
    
    if (_selectedDuration == 'monthly') formattedPrice += ' /mo';
    if (_selectedDuration == 'yearly') formattedPrice += ' /yr';
    
    return formattedPrice;
  }

  Widget _buildCurrencySelector() {
    final config = ref.read(remoteConfigProvider);
    // Get available currencies from config keys, defaulting to ['DZD'] if empty
    final currencies = config.pricing.keys.isNotEmpty ? config.pricing.keys.toList() : ['DZD'];
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: currencies.contains(_selectedCurrency) ? _selectedCurrency : currencies.first,
          items: currencies.map((c) => DropdownMenuItem(
            value: c,
            child: Text(c, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          )).toList(),
          onChanged: (val) {
            if (val != null) setState(() => _selectedCurrency = val);
          },
          icon: const Icon(Icons.currency_exchange, size: 18),
        ),
      ),
    );
  }

  Widget _buildDurationToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _toggleButton('Monthly', 'monthly'),
          _toggleButton('Yearly (Save 17%)', 'yearly'),
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
          color: isSelected ? const Color(0xFF1E88E5) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            color: isSelected ? Colors.white : Colors.black54,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildPlanCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    List<String> features, {
    bool isCurrent = false,
    bool isRecommended = false,
    required String price,
  }) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: isRecommended
                ? Border.all(color: color, width: 2)
                : Border.all(color: Colors.transparent),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.1),
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
                      color: color.withValues(alpha: 0.1),
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
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey,
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
                  color: Colors.black87,
                ),
              ),
              const Divider(height: 32),
              ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: color, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            f,
                            style: GoogleFonts.poppins(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  )),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: isCurrent
                    ? OutlinedButton(
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
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ElevatedButton(
                        onPressed: () => _contactSales(title, price),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Subscribe Now',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
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
