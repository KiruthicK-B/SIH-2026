import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/centre.dart';
import '../../models/slot.dart';
import '../../repositories/repository_providers.dart';
import '../../state/booking_controller.dart';
import '../../state/data_revision.dart';
import '../../widgets/app_buttons.dart';
import '../../widgets/app_text_field.dart';

class ManageCapacityDialog extends ConsumerStatefulWidget {
  final ProcurementCentre centre;
  const ManageCapacityDialog({super.key, required this.centre});

  static Future<void> show(BuildContext context, ProcurementCentre centre) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ManageCapacityDialog(centre: centre),
    );
  }

  @override
  ConsumerState<ManageCapacityDialog> createState() =>
      _ManageCapacityDialogState();
}

class _ManageCapacityDialogState extends ConsumerState<ManageCapacityDialog> {
  late TextEditingController _dailyProcessingController;
  late TextEditingController _storageCapacityController;
  late TextEditingController _maxFarmersSlotController;
  late TextEditingController _slotCapacityController;
  late TextEditingController _activeLanesController;
  late Map<String, TextEditingController> _cropCapacityControllers;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.centre;
    _dailyProcessingController = TextEditingController(
      text: c.dailyProcessingCapacityQ.toStringAsFixed(0),
    );
    _storageCapacityController = TextEditingController(
      text: c.storageCapacityQ.toStringAsFixed(0),
    );
    _maxFarmersSlotController = TextEditingController(text: '8');
    _slotCapacityController = TextEditingController(text: '160');
    _activeLanesController = TextEditingController(
      text: c.processingLanesActive.toString(),
    );

    _cropCapacityControllers = {
      for (final support in c.supportedCrops)
        support.cropId: TextEditingController(
          text: (c.dailyCapacityQ[support.cropId] ?? 800).toStringAsFixed(0),
        ),
    };
  }

  @override
  void dispose() {
    _dailyProcessingController.dispose();
    _storageCapacityController.dispose();
    _maxFarmersSlotController.dispose();
    _slotCapacityController.dispose();
    _activeLanesController.dispose();
    for (final ctrl in _cropCapacityControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final dailyProcessing = double.tryParse(_dailyProcessingController.text.trim());
    final storageCap = double.tryParse(_storageCapacityController.text.trim());
    final maxFarmers = int.tryParse(_maxFarmersSlotController.text.trim());
    final slotCap = double.tryParse(_slotCapacityController.text.trim());
    final activeLanes = int.tryParse(_activeLanesController.text.trim());

    if (dailyProcessing == null || dailyProcessing <= 0) {
      setState(() => _error = 'Enter a valid daily processing capacity.');
      return;
    }
    if (maxFarmers == null || maxFarmers <= 0) {
      setState(() => _error = 'Enter a valid max farmers quota per slot.');
      return;
    }
    if (slotCap == null || slotCap <= 0) {
      setState(() => _error = 'Enter a valid max quantity quota per slot.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final updatedCropCap = <String, double>{};
      for (final entry in _cropCapacityControllers.entries) {
        final val = double.tryParse(entry.value.text.trim()) ?? 600.0;
        updatedCropCap[entry.key] = val;
      }

      final updatedCentre = widget.centre.copyWith(
        dailyProcessingCapacityQ: dailyProcessing,
        storageCapacityQ: storageCap ?? widget.centre.storageCapacityQ,
        dailyCapacityQ: updatedCropCap,
        processingLanesActive: activeLanes ?? widget.centre.processingLanesActive,
      );

      await ref.read(centreRepositoryProvider).save(updatedCentre);

      // Update all today and upcoming slots for this centre to match the new slot quota
      final slotRepo = ref.read(slotRepositoryProvider);
      final centreSlots = await slotRepo.forCentre(widget.centre.id);
      final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

      final updatedSlots = <Slot>[];
      for (final s in centreSlots) {
        if (!s.start.isBefore(today)) {
          updatedSlots.add(
            Slot(
              id: s.id,
              centreId: s.centreId,
              cropId: s.cropId,
              start: s.start,
              end: s.end,
              maxFarmers: maxFarmers,
              totalCapacityQ: slotCap,
              baselineFarmers: s.baselineFarmers,
              baselineQuantityQ: s.baselineQuantityQ,
            ),
          );
        }
      }

      if (updatedSlots.isNotEmpty) {
        await slotRepo.saveMany(updatedSlots);
      }

      ref.read(dataRevisionProvider.notifier).bump();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Procurement Centre capacity & slot quotas updated successfully.'),
            backgroundColor: AgrivaColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = 'Failed to save capacity: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cropsAsync = ref.watch(activeCropsProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.tune_rounded, color: AgrivaColors.primary, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Manage Centre Capacity',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        widget.centre.name,
                        style: const TextStyle(fontSize: 11.5, color: AgrivaColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(height: 16),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Overall Processing & Storage Limits',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AgrivaColors.primary),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Daily Processing Cap (Q)',
                            controller: _dailyProcessingController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppTextField(
                            label: 'Active Processing Lanes',
                            controller: _activeLanesController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Hourly Slot Booking Quota',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AgrivaColors.primary),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Enforces strict maximums per 1-hour slot. Farmer slot booking will close when capacity is met.',
                      style: TextStyle(fontSize: 11.5, color: AgrivaColors.textSecondary),
                    ),
                    const SizedBox(height: 10),

                    Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            label: 'Max Farmers / Slot',
                            controller: _maxFarmersSlotController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: AppTextField(
                            label: 'Max Intake / Slot (Q)',
                            controller: _slotCapacityController,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    const Text(
                      'Daily Intake Capacity per Supported Crop (Quintals)',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AgrivaColors.primary),
                    ),
                    const SizedBox(height: 8),

                    cropsAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, st) => const SizedBox.shrink(),
                      data: (crops) {
                        final cropMap = {for (final c in crops) c.id: c.name};
                        return Column(
                          children: [
                            for (final entry in _cropCapacityControllers.entries)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        cropMap[entry.key] ?? entry.key,
                                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: AppTextField(
                                        label: 'Daily Q Limit',
                                        controller: entry.value,
                                        keyboardType: TextInputType.number,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        style: const TextStyle(color: AgrivaColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'Cancel',
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'Save & Apply to Slots',
                    loading: _saving,
                    onPressed: _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
