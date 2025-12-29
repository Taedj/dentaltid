import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/prescriptions/application/prescription_service.dart';
import 'package:dentaltid/src/features/prescriptions/domain/prescription.dart';
import 'package:dentaltid/src/features/prescriptions/presentation/prescription_templates.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class PrescriptionHistoryView extends ConsumerStatefulWidget {
  const PrescriptionHistoryView({super.key});

  @override
  ConsumerState<PrescriptionHistoryView> createState() => _PrescriptionHistoryViewState();
}

class _PrescriptionHistoryViewState extends ConsumerState<PrescriptionHistoryView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).value;
    if (userProfile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Since we don't have a dentist-wide prescription history provider yet, 
    // we can use a FutureBuilder or define a new provider.
    // Let's use a FutureProvider for cleaner code (defined in service usually).
    
    return Column(
      children: [
        _buildHeader(context),
        Expanded(
          child: _buildPrescriptionList(userProfile.uid),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by patient name or order number...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionList(String dentistId) {
    // We'll define a quick future for this view
    final prescriptionsFuture = ref.read(prescriptionServiceProvider).getPrescriptionsByDentist(dentistId);

    return FutureBuilder<List<Prescription>>(
      future: prescriptionsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final prescriptions = snapshot.data ?? [];
        final filtered = prescriptions.where((p) {
          final query = _searchQuery.toLowerCase();
          return p.patientName.toLowerCase().contains(query) ||
                 p.patientFamilyName.toLowerCase().contains(query) ||
                 p.orderNumber.toString().contains(query);
        }).toList();

        if (filtered.isEmpty) {
          return const Center(child: Text('No prescriptions found.'));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Ord. #')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Patient')),
                    DataColumn(label: Text('Age')),
                    DataColumn(label: Text('Medicines')),
                    DataColumn(label: Text('Actions')),
                  ],
                  rows: filtered.map((p) => _buildDataRow(context, p)).toList(),
                ),
              ),
            );
          }
        );
      },
    );
  }

  DataRow _buildDataRow(BuildContext context, Prescription p) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(p.date);
    return DataRow(
      cells: [
        DataCell(Text('#${p.orderNumber}')),
        DataCell(Text(dateStr)),
        DataCell(Text('${p.patientName} ${p.patientFamilyName}')),
        DataCell(Text('${p.patientAge}')),
        DataCell(Text('${p.medicines.length} items')),
        DataCell(
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.visibility_outlined, color: Colors.blue),
                tooltip: 'Preview',
                onPressed: () => _showPreview(context, p),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.orange),
                tooltip: 'Edit',
                onPressed: () {
                  // Edit logic would typically open the editor
                  // For now, let's notify the user
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit feature coming soon (navigating to editor)...')),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Delete',
                onPressed: () => _confirmDelete(context, p),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showPreview(BuildContext context, Prescription p) {
    final userProfile = ref.read(userProfileProvider).value;
    if (userProfile == null) return;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800, maxHeight: 900),
          child: Column(
            children: [
              AppBar(
                title: Text('Prescription #${p.orderNumber} Preview'),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.print),
                    onPressed: () {},
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1 / 1.414,
                      child: Card(
                        elevation: 4,
                        child: PrescriptionTemplate(
                          prescription: p,
                          userProfile: userProfile,
                          templateId: p.templateId,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, Prescription p) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Prescription'),
        content: Text('Are you sure you want to delete prescription #${p.orderNumber} for ${p.patientName}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ref.read(prescriptionServiceProvider).deletePrescription(p.id!);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Prescription deleted successfully')),
        );
        setState(() {}); // Refresh list
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting prescription: $e')),
        );
      }
    }
  }
}
