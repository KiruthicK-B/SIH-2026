import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/status_mapper.dart';
import '../../models/enums.dart';
import '../../state/auth_controller.dart';
import '../../state/grievance_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/max_width_body.dart';

/// README §5.1 "Support" — raise/track grievances, with escalation-level
/// visibility as they move centre → district → state.
class GrievancesScreen extends ConsumerWidget {
  const GrievancesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();
    final grievancesAsync = ref.watch(grievancesForFarmerProvider(user.id));

    return Scaffold(
      appBar: const AgrivaAppBar(title: 'Grievances'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/farmer/grievances/new'),
        icon: const Icon(Icons.add),
        label: const Text('Raise Grievance'),
      ),
      body: MaxWidthBody(
        child: grievancesAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (list) {
            if (list.isEmpty) {
              return const EmptyState(
                icon: Icons.support_agent_outlined,
                title: 'No grievances raised',
                message: 'If something goes wrong with a booking, you can raise it here.',
              );
            }
            final sorted = [...list]..sort((a, b) => b.raisedAt.compareTo(a.raisedAt));
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, i) {
                final g = sorted[i];
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AgrivaColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(g.category.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          StatusBadge(label: g.status.label, tone: toneForGrievanceStatus(g.status)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(g.description, style: const TextStyle(fontSize: 13, color: AgrivaColors.textSecondary)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.route_outlined, size: 14, color: AgrivaColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Escalation: ${g.escalationLevel.label}',
                            style: const TextStyle(fontSize: 11.5, color: AgrivaColors.textMuted),
                          ),
                          const Spacer(),
                          Text(
                            DateFormat('d MMM').format(g.raisedAt),
                            style: const TextStyle(fontSize: 11.5, color: AgrivaColors.textMuted),
                          ),
                        ],
                      ),
                      if (g.resolutionNote != null) ...[
                        const Divider(height: 20),
                        Text(
                          'Resolution: ${g.resolutionNote}',
                          style: const TextStyle(fontSize: 12.5, color: AgrivaColors.success),
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
}
