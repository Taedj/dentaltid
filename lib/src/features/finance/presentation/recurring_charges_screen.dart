import 'package:dentaltid/src/features/finance/application/recurring_charge_service.dart';
import 'package:dentaltid/src/features/finance/domain/recurring_charge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; // Import this
import 'package:dentaltid/l10n/app_localizations.dart';

final recurringChargesProvider = FutureProvider<List<RecurringCharge>>((
  ref,
) async {
  final service = ref.watch(recurringChargeServiceProvider);
  return service.getAllRecurringCharges();
});

class RecurringChargesScreen extends ConsumerWidget {
  const RecurringChargesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurringChargesAsyncValue = ref.watch(recurringChargesProvider);
    final l10n = AppLocalizations.of(context)!;
    final recurringChargeService = ref.watch(recurringChargeServiceProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurringCharges)),
      body: recurringChargesAsyncValue.when(
        data: (charges) {
          if (charges.isEmpty) {
            return Center(child: Text(l10n.noRecurringChargesFound));
          }
          return ListView.builder(
            itemCount: charges.length,
            itemBuilder: (context, index) {
              final charge = charges[index];
              return ListTile(
                title: Text(charge.name),
                subtitle: Text(
                  '${charge.amount} ${l10n.currency} - ${charge.frequency.toString().split('.').last}',
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: charge.isActive,
                      onChanged: (value) async {
                        final updatedCharge = RecurringCharge(
                          id: charge.id,
                          name: charge.name,
                          amount: charge.amount,
                          frequency: charge.frequency,
                          startDate: charge.startDate,
                          endDate: charge.endDate,
                          isActive: value,
                          description: charge.description,
                        );
                        await recurringChargeService.updateRecurringCharge(
                          updatedCharge,
                        );
                        ref.invalidate(recurringChargesProvider);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(l10n.deleteRecurringChargeTitle),
                            content: Text(
                              l10n.deleteRecurringChargeContent,
                            ),
                            actions: [
                              TextButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(false),
                                child: Text(l10n.cancel),
                              ),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.of(context).pop(true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text(l10n.deleteItemButton),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true && charge.id != null) {
                          await recurringChargeService.deleteRecurringCharge(
                            charge.id!,
                          );
                          ref.invalidate(recurringChargesProvider);
                        }
                      },
                    ),
                  ],
                ),
                onTap: () {
                  context.go('/finance/recurring-charges/edit', extra: charge);
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          context.go('/finance/recurring-charges/add');
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
