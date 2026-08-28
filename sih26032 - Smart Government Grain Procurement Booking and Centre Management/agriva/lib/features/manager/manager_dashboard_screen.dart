import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/manager_kpis.dart';
import '../../models/enums.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/max_width_body.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);

    int countIn(List<BookingStatus> statuses) =>
        appState.bookings.where((b) => statuses.contains(b.status)).length;
    final completed = countIn([BookingStatus.completed]);
    final inProgress = countIn([
      BookingStatus.checkedIn,
      BookingStatus.inQueue,
      BookingStatus.processing,
    ]);
    final upcoming = countIn([BookingStatus.confirmed]);
    final cancelled = countIn([BookingStatus.cancelled, BookingStatus.noShow]);
    final total = (completed + inProgress + upcoming + cancelled).clamp(
      1,
      1 << 30,
    );

    return Scaffold(
      appBar: const AgrivaAppBar(
        title: 'Manager Dashboard',
        subtitle: 'Demo District',
      ),
      body: MaxWidthBody(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.6,
              children: [
                MetricCard(
                  icon: Icons.storefront_outlined,
                  label: 'Total Centres',
                  value: '${ManagerKpis.totalCentres}',
                ),
                MetricCard(
                  icon: Icons.groups_outlined,
                  label: 'Farmers Today',
                  value: '${ManagerKpis.farmersToday}',
                  accent: AgrivaColors.info,
                ),
                MetricCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Quantity Procured',
                  value: '${ManagerKpis.quantityProcuredQ} Q',
                  accent: AgrivaColors.success,
                ),
                MetricCard(
                  icon: Icons.payments_outlined,
                  label: 'Payments Completed',
                  value: '₹${ManagerKpis.paymentsCompletedLakh} L',
                  accent: AgrivaColors.warning,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Quantity Procured by Day',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              height: 180,
              padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AgrivaColors.border),
              ),
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 ||
                              i >= ManagerKpis.quantityByDayLabels.length)
                            return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              ManagerKpis.quantityByDayLabels[i],
                              style: const TextStyle(
                                fontSize: 10,
                                color: AgrivaColors.textMuted,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < ManagerKpis.quantityByDay.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: ManagerKpis.quantityByDay[i],
                            color: AgrivaColors.primary,
                            width: 16,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Procurement Status',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AgrivaColors.border),
              ),
              child: Row(
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 28,
                        sections: [
                          PieChartSectionData(
                            value: completed.toDouble(),
                            color: AgrivaColors.success,
                            showTitle: false,
                            radius: 20,
                          ),
                          PieChartSectionData(
                            value: inProgress.toDouble(),
                            color: AgrivaColors.warning,
                            showTitle: false,
                            radius: 20,
                          ),
                          PieChartSectionData(
                            value: upcoming.toDouble(),
                            color: AgrivaColors.info,
                            showTitle: false,
                            radius: 20,
                          ),
                          PieChartSectionData(
                            value: cancelled.toDouble(),
                            color: AgrivaColors.textMuted,
                            showTitle: false,
                            radius: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _Legend(
                          'Completed',
                          completed,
                          total,
                          AgrivaColors.success,
                        ),
                        _Legend(
                          'In Progress',
                          inProgress,
                          total,
                          AgrivaColors.warning,
                        ),
                        _Legend('Upcoming', upcoming, total, AgrivaColors.info),
                        _Legend(
                          'Cancelled',
                          cancelled,
                          total,
                          AgrivaColors.textMuted,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  const _Legend(this.label, this.value, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0 : (value / total * 100).round();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 12.5))),
          Text(
            '$value ($pct%)',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
