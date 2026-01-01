import 'dart:math';
import 'package:dentaltid/src/core/user_profile_provider.dart';
import 'package:dentaltid/src/features/developer/data/developer_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class DeveloperCodesScreen extends ConsumerStatefulWidget {
  const DeveloperCodesScreen({super.key});

  @override
  ConsumerState<DeveloperCodesScreen> createState() =>
      _DeveloperCodesScreenState();
}

class _DeveloperCodesScreenState extends ConsumerState<DeveloperCodesScreen> {
  final _formKey = GlobalKey<FormState>();
  final DeveloperService _developerService = DeveloperService();
  int _selectedDurationMonths = 1;
  String? _generatedCode;
  bool _isLoading = false;
  String _selectedPlanType = 'premium_subscription'; // default

  String _generateRandomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return String.fromCharCodes(
      Iterable.generate(27, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
  }

  Future<void> _generateAndSaveCode() async {
    setState(() {
      _isLoading = true;
      _generatedCode = null;
    });

    try {
      final code = _generateRandomCode();
      await ref
          .read(firebaseServiceProvider)
          .createActivationCode(
            code: code,
            durationMonths: _selectedDurationMonths,
            type: _selectedPlanType,
          );

      setState(() {
        _generatedCode = code;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating code: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteCode(String id) async {
    try {
      await _developerService.deleteActivationCode(id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error deleting: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activation Codes')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LEFT: Generator
          Expanded(
            flex: 4,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Generate Code',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Form(
                    key: _formKey,
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            DropdownButtonFormField<int>(
                              initialValue: _selectedDurationMonths,
                              decoration: const InputDecoration(
                                labelText: 'Duration',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 1,
                                  child: Text('1 Month'),
                                ),
                                DropdownMenuItem(
                                  value: 3,
                                  child: Text('3 Months'),
                                ),
                                DropdownMenuItem(
                                  value: 6,
                                  child: Text('6 Months'),
                                ),
                                DropdownMenuItem(
                                  value: 12,
                                  child: Text('1 Year'),
                                ),
                                DropdownMenuItem(
                                  value: 1200,
                                  child: Text('Lifetime (100 Years)'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedDurationMonths = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedPlanType,
                              decoration: const InputDecoration(
                                labelText: 'Target Tier',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: 'premium_subscription',
                                  child: Text('PREMIUM (Professional)'),
                                ),
                                DropdownMenuItem(
                                  value: 'crown_subscription',
                                  child: Text('CROWN (Enterprise)'),
                                ),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _selectedPlanType = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading
                                    ? null
                                    : _generateAndSaveCode,
                                child: _isLoading
                                    ? const CircularProgressIndicator()
                                    : const Text('Generate Code'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_generatedCode != null) ...[
                    const Text(
                      'New Code:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green),
                      ),
                      child: SelectableText(
                        _generatedCode!,
                        style: const TextStyle(
                          fontSize: 16,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Courier',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _generatedCode!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Code copied to clipboard'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const VerticalDivider(width: 1),
          // RIGHT: List
          Expanded(
            flex: 6,
            child: StreamBuilder<List<ActivationCodeModel>>(
              stream: _developerService.getActivationCodes(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final codes = snapshot.data!;

                return ListView.separated(
                  itemCount: codes.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final code = codes[index];
                    final isRedeemed = code.isRedeemed;

                    return ListTile(
                      title: SelectableText(
                        code.code,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Duration: ${code.durationMonths} months • Created: ${DateFormat.yMMMd().format(code.createdAt)}',
                          ),
                          if (isRedeemed) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Used used: ${code.redeemedAt != null ? DateFormat.yMMMd().add_Hm().format(code.redeemedAt!) : 'Unknown'}',
                              style: TextStyle(
                                color: Colors.green[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (code.redeemedByEmail != null)
                              Text('Email: ${code.redeemedByEmail}'),
                            if (code.redeemedByPhone != null)
                              Text('Phone: ${code.redeemedByPhone}'),
                          ],
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isRedeemed)
                            const Chip(
                              label: Text('USED'),
                              backgroundColor: Colors.amberAccent,
                            )
                          else
                            const Chip(
                              label: Text('ACTIVE'),
                              backgroundColor: Colors.greenAccent,
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.grey),
                            onPressed: () => _confirmDelete(code),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(ActivationCodeModel code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Code'),
        content: Text('Are you sure you want to delete code ${code.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _deleteCode(code.id);
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
