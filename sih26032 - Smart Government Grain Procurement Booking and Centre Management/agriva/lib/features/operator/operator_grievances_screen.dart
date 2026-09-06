import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/utils/status_mapper.dart';
import '../../models/enums.dart';
import '../../models/grievance.dart';
import '../../repositories/repository_providers.dart';
import '../../state/auth_controller.dart';
import '../../state/data_revision.dart';
import '../../state/grievance_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

final _grievancesForCentreProvider = FutureProvider.family<List<Grievance>, String>((
  ref,
  centreId,
) async {
  ref.watch(dataRevisionProvider);
  final centreBookingIds = (await ref.read(bookingRepositoryProvider).forCentre(centreId))
      .map((b) => b.id)
      .toSet();
  final all = await ref.read(grievanceRepositoryProvider).getAll();
  return all.where((g) => g.relatedBookingId != null && centreBookingIds.contains(g.relatedBookingId)).toList()
    ..sort((a, b) => b.raisedAt.compareTo(a.raisedAt));
});

class OperatorGrievancesScreen extends ConsumerWidget {
  const OperatorGrievancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final centreId = user?.centreId;
    if (centreId == null || centreId.isEmpty) return const SizedBox.shrink();
    final grievancesAsync = ref.watch(_grievancesForCentreProvider(centreId));

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Grievances'),
      body: MaxWidthBody(
        child: grievancesAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.support_agent_outlined,
                title: 'No grievances for this centre',
                message: 'Grievances raised against your centre appear here.',
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final g = list[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AgrivaColors.surfaceFor(context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AgrivaColors.borderFor(context)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              g.category.label,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          StatusBadge(label: g.status.label, tone: toneForGrievanceStatus(g.status)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(g.description, style: TextStyle(fontSize: 13, color: AgrivaColors.textSecondaryFor(context))),
                      if (g.status == GrievanceStatus.open || g.status == GrievanceStatus.inReview) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            TextButton(
                              onPressed: () => ref.read(grievanceControllerProvider).escalate(g.id, EscalationLevel.district),
                              child: const Text('Escalate to District'),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => _resolve(context, ref, g.id),
                              child: const Text('Resolve'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _resolve(BuildContext context, WidgetRef ref, String grievanceId) async {
    final controller = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Resolve Grievance'),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Resolution note')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Resolve')),
        ],
      ),
    );
    if (note != null && note.trim().isNotEmpty) {
      await ref.read(grievanceControllerProvider).resolve(grievanceId, note.trim());
    }
  }
}
