import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/crop.dart';
import '../../models/enums.dart';
import '../../state/state_admin_controller.dart';
import '../../widgets/app_states.dart';
import '../../widgets/max_width_body.dart';

class StateAdminCropsScreen extends ConsumerWidget {
  const StateAdminCropsScreen({super.key});

  Future<void> _editMsp(BuildContext context, WidgetRef ref, Crop crop) async {
    final controller = TextEditingController(text: crop.msp.toStringAsFixed(0));
    final newMsp = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('MSP for ${crop.name}'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            prefixText: '₹ ',
            suffixText: '/ quintal',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, double.tryParse(controller.text)),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newMsp != null) {
      await ref.read(stateAdminControllerProvider).updateMsp(crop.id, newMsp);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final crops = ref.watch(cropsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Crops & MSP')),
      body: MaxWidthBody(
        child: crops.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (list) => ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final crop = list[i];
              return Card(
                child: ListTile(
                  title: Text(crop.name),
                  subtitle: Text('${crop.season.label} · ${crop.unit}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '₹${crop.msp.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AgrivaColors.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Switch(
                        value: crop.isActive,
                        onChanged: (v) => ref
                            .read(stateAdminControllerProvider)
                            .setCropActive(crop.id, v),
                      ),
                    ],
                  ),
                  onTap: () => _editMsp(context, ref, crop),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
