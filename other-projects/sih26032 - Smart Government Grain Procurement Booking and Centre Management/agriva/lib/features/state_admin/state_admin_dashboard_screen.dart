import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../models/enums.dart';
import '../../state/grievance_controller.dart';
import '../../state/state_admin_controller.dart';
import '../../widgets/app_states.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/max_width_body.dart';
import '../../widgets/metric_card.dart';

class StateAdminDashboardScreen extends ConsumerWidget {
  const StateAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final districts = ref.watch(districtsProvider);
    final grievances = ref.watch(allGrievancesProvider);
    final summaryAsync = ref.watch(statewideSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('State Overview'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => showAgrivaSignOutDialog(context, ref),
          ),
        ],
      ),
      body: MaxWidthBody(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              summaryAsync.when(
                loading: () => const LoadingState(),
                error: (e, st) => const ErrorState(),
                data: (summary) => GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.25,
                  children: [
                    MetricCard(
                      icon: Icons.storefront_outlined,
                      label: 'Centres statewide',
                      value: '${summary.totalCentres}',
                    ),
                    MetricCard(
                      icon: Icons.groups_outlined,
                      label: 'Farmers served today',
                      value: '${summary.farmersToday}',
                    ),
                    MetricCard(
                      icon: Icons.scale_outlined,
                      label: 'Quantity procured (Q)',
                      value: summary.quantityProcuredQ.toStringAsFixed(0),
                      accent: AgrivaColors.leaf,
                    ),
                    MetricCard(
                      icon: Icons.currency_rupee,
                      label: 'Payments completed (₹ Lakh)',
                      value: summary.paymentsCompletedLakh.toStringAsFixed(2),
                      accent: AgrivaColors.gold,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('Districts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              const SizedBox(height: 10),
              districts.when(
                loading: () => const LoadingState(),
                error: (e, st) => const ErrorState(),
                data: (list) => Column(
                  children: list
                      .map(
                        (d) => Card(
                          child: ListTile(
                            leading: const Icon(Icons.map_outlined, color: AgrivaColors.primary),
                            title: Text(d.name),
                            subtitle: Text(d.stateCode),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Grievance escalation log',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
              grievances.when(
                loading: () => const LoadingState(),
                error: (e, st) => const ErrorState(),
                data: (list) {
                  if (list.isEmpty) {
                    return const EmptyState(
                      title: 'No grievances',
                      message: 'Nothing has been raised yet.',
                    );
                  }
                  return Column(
                    children: list.map((g) {
                      return Card(
                        child: ListTile(
                          title: Text(g.category.label),
                          subtitle: Text(g.description, maxLines: 1, overflow: TextOverflow.ellipsis),
                          trailing: Text(
                            g.status.label,
                            style: TextStyle(fontSize: 12, color: AgrivaColors.textSecondaryFor(context)),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
