import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/finance/domain/purchase_order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class DeveloperOrdersScreen extends ConsumerStatefulWidget {
  const DeveloperOrdersScreen({super.key});

  @override
  ConsumerState<DeveloperOrdersScreen> createState() => _DeveloperOrdersScreenState();
}

class _DeveloperOrdersScreenState extends ConsumerState<DeveloperOrdersScreen> {
  bool _isProcessing = false;

  Future<void> _approveOrder(PurchaseOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Approval'),
        content: Text(
            'Are you sure you want to approve this order?\n\nUser: ${order.userEmail}\nPlan: ${order.plan} (${order.durationLabel})'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Approve & Activate', style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        await ref.read(firebaseServiceProvider).approveOrder(order);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order approved successfully')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectOrder(PurchaseOrder order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Rejection'),
        content: Text('Reject order from ${order.userEmail}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);
      try {
        await ref.read(firebaseServiceProvider).rejectOrder(order.id);
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order rejected')));
        }
      } catch (e) {
         if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          'Pending Orders',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: StreamBuilder<List<PurchaseOrder>>(
        stream: ref.watch(firebaseServiceProvider).getPendingOrders(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final orders = snapshot.data ?? [];

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   const Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                   const SizedBox(height: 16),
                   Text(
                    'No pending orders',
                    style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: order.plan.toString().contains('enterprise') 
                                  ? Colors.purple.withValues(alpha: 0.15) 
                                  : Colors.amber.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              order.plan.toString().split('.').last.toUpperCase(),
                              style: TextStyle(
                                color: order.plan.toString().contains('enterprise') ? Colors.purple[800] : Colors.amber[900],
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            DateFormat.yMMMd().add_jm().format(order.createdAt),
                            style: GoogleFonts.poppins(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 16, 
                            backgroundColor: Colors.blueGrey, 
                            child: Icon(Icons.person, size: 16, color: Colors.white)
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.dentistName?.isNotEmpty == true ? order.dentistName! : 'Unknown User',
                                style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 16),
                              ),
                              Text(
                                order.userEmail,
                                style: const TextStyle(color: Colors.grey, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                       const SizedBox(height: 12),
                       Container(
                         padding: const EdgeInsets.all(8),
                         decoration: BoxDecoration(
                           color: Colors.grey.withValues(alpha: 0.05),
                           borderRadius: BorderRadius.circular(8),
                         ),
                         child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.fingerprint, size: 14, color: Colors.grey),
                            const SizedBox(width: 8),
                            SelectableText(
                              order.userId,
                              style: GoogleFonts.firaCode(color: Colors.grey[700], fontSize: 11),
                            ),
                          ],
                        ),
                       ),
                      const Divider(height: 32),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Duration', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                Text(
                                  order.durationLabel.toUpperCase(),
                                  style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Price', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                Text(
                                  order.priceLabel,
                                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green[700]),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => _rejectOrder(order),
                                style: TextButton.styleFrom(foregroundColor: Colors.red),
                                child: const Text('Reject'),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _approveOrder(order),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A1C1E),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Approve'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
