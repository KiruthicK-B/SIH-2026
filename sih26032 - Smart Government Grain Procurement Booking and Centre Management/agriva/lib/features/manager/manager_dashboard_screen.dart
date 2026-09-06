import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../models/enums.dart';
import '../../state/auth_controller.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/metric_card.dart';
import '../../widgets/max_width_body.dart';
import 'district_providers.dart';

class ManagerDashboardScreen extends ConsumerWidget {
  const ManagerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    final userDistrict = user?.district;
    final districtKey = (userDistrict != null && userDistrict.isNotEmpty)
        ? userDistrict
        : 'district-erode';
    final districtDisplay = districtKey
        .replaceAll('district-', '')
        .replaceAll('dt-', '');
    final formattedDistrict = districtDisplay.isEmpty
        ? 'Erode District'
        : '${districtDisplay[0].toUpperCase()}${districtDisplay.substring(1)} District';

    final dataAsync = ref.watch(districtDataProvider(districtKey));
    final pendingVerificationsAsync = ref.watch(
      pendingFarmerVerificationsProvider(districtKey),
    );
    final centreStatsAsync = ref.watch(centreFarmerStatsProvider(districtKey));

    return Scaffold(
      appBar: AgrivaAppBar(
        title: 'District Admin',
        subtitle: formattedDistrict,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: 'Sign Out',
            onPressed: () => showAgrivaSignOutDialog(context, ref),
          ),
        ],
      ),
      body: MaxWidthBody(
        child: dataAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (data) {
            int countIn(List<BookingStatus> statuses) =>
                data.bookings.where((b) => statuses.contains(b.status)).length;
            final completed = countIn([BookingStatus.paymentCompleted, BookingStatus.accepted]);
            final inProgress = countIn([
              BookingStatus.checkedIn,
              BookingStatus.inQueue,
              BookingStatus.underQualityCheck,
            ]);
            final upcoming = countIn([BookingStatus.booked]);
            final cancelled = countIn([BookingStatus.cancelled, BookingStatus.noShow]);
            final total = (completed + inProgress + upcoming + cancelled).clamp(1, 1 << 30);

            bool isSameDay(DateTime a, DateTime b) =>
                a.year == b.year && a.month == b.month && a.day == b.day;
            final today = DateTime.now();

            final farmersToday = data.bookings
                .where((b) {
                  final cAt = b.checkedInAt;
                  return cAt != null && isSameDay(cAt, today);
                })
                .map((b) => b.farmerId)
                .toSet()
                .length;

            final quantityProcuredToday = data.procurementRecords
                .where((p) => isSameDay(p.inspectionTime, today))
                .fold<double>(0, (sum, p) => sum + (p.acceptedQuantityQ ?? 0));

            final paymentsCompletedLakh = data.payments
                    .where((p) => p.status == PaymentStatus.completed)
                    .fold<double>(0, (sum, p) => sum + p.amount) /
                100000;

            // Quantity procured per day for the last 7 days from real records
            final last7Days = List.generate(
              7,
              (i) => DateTime(today.year, today.month, today.day)
                  .subtract(Duration(days: 6 - i)),
            );
            final quantityByDay = last7Days
                .map(
                  (day) => data.procurementRecords
                      .where((p) => isSameDay(p.inspectionTime, day))
                      .fold<double>(0, (sum, p) => sum + (p.acceptedQuantityQ ?? 0)),
                )
                .toList();
            final quantityByDayLabels =
                last7Days.map((d) => DateFormat('E').format(d)).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                centreStatsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (stats) {
                    final overdueCentres = stats.where((s) => s.pendingOverdue > 0).toList();
                    final totalEscalated = stats.fold<int>(0, (sum, s) => sum + s.escalated);
                    if (overdueCentres.isEmpty && totalEscalated == 0) {
                      return const SizedBox.shrink();
                    }

                    final firstOverdueName = overdueCentres.isNotEmpty
                        ? overdueCentres.first.centre.name
                        : 'Direct Purchase Centre';
                    final firstOverdueCount = overdueCentres.isNotEmpty
                        ? overdueCentres.first.pendingOverdue
                        : 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFBE9E7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AgrivaColors.error.withValues(alpha: 0.4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.notifications_active_rounded, color: AgrivaColors.error, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'District Admin Action Required',
                                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AgrivaColors.error),
                                ),
                                Text(
                                  overdueCentres.isNotEmpty
                                      ? '$firstOverdueName has $firstOverdueCount farmer verifications pending > 48 hrs!'
                                      : '$totalEscalated farmer verification(s) escalated by centre operators awaiting your clearance.',
                                  style: const TextStyle(fontSize: 11.5, color: AgrivaColors.textPrimary),
                                ),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AgrivaColors.error,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => context.push('/district-admin/verifications'),
                            child: const Text('Review Now', style: TextStyle(color: Colors.white, fontSize: 11.5)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                pendingVerificationsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (e, st) => const SizedBox.shrink(),
                  data: (pending) {
                    if (pending.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.push('/district-admin/verifications'),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AgrivaColors.warningBg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AgrivaColors.gold.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.verified_user_outlined, color: AgrivaColors.warning),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${pending.length} farmer${pending.length == 1 ? '' : 's'} awaiting verification',
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                    ),
                                    const Text(
                                      'Review Aadhaar & land record documents to approve',
                                      style: TextStyle(fontSize: 11.5, color: AgrivaColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AgrivaColors.textSecondary),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.25,
                  children: [
                    MetricCard(icon: Icons.storefront_outlined, label: 'Total Centres', value: '${data.centres.length}'),
                    MetricCard(
                      icon: Icons.groups_outlined,
                      label: 'Farmers Today',
                      value: '$farmersToday',
                      accent: AgrivaColors.info,
                    ),
                    MetricCard(
                      icon: Icons.inventory_2_outlined,
                      label: 'Quantity Procured',
                      value: '${quantityProcuredToday.toStringAsFixed(0)} Q',
                      accent: AgrivaColors.success,
                    ),
                    MetricCard(
                      icon: Icons.payments_outlined,
                      label: 'Payments Completed',
                      value: '₹${paymentsCompletedLakh.toStringAsFixed(2)} L',
                      accent: AgrivaColors.warning,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Quantity Procured by Day', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _DailyProcurementBarChart(
                  quantities: quantityByDay,
                  labels: quantityByDayLabels,
                ),
                const SizedBox(height: 24),
                const Text('Procurement Status', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _ProcurementStatusCard(
                  completed: completed,
                  inProgress: inProgress,
                  upcoming: upcoming,
                  cancelled: cancelled,
                  total: total,
                ),
                const SizedBox(height: 24),

                // Centre-Wise Farmer Registration & Verification Distribution
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        'Farmer Registrations by Centre',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => context.push('/district-admin/verifications'),
                      child: const Text('View All Verifications →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                centreStatsAsync.when(
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Failed to load centre stats: $e', style: const TextStyle(color: AgrivaColors.error)),
                  data: (stats) {
                    final isDark = Theme.of(context).brightness == Brightness.dark;
                    final cardBg = isDark ? AgrivaColors.surfaceDark : Colors.white;
                    final cardBorder = isDark ? AgrivaColors.borderDark : AgrivaColors.border;

                    return Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cardBorder),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < stats.length; i++)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                border: i < stats.length - 1
                                    ? Border(bottom: BorderSide(color: cardBorder))
                                    : null,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          stats[i].centre.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        stats[i].centre.code,
                                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? AgrivaColors.primaryAccentDark : AgrivaColors.primary),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Taluk: ${stats[i].centre.taluk}',
                                    style: TextStyle(fontSize: 11, color: isDark ? AgrivaColors.textSecondaryDark : AgrivaColors.textMuted),
                                  ),
                                  const SizedBox(height: 8),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 5,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF1E382A) : AgrivaColors.primaryLight50,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${stats[i].totalRegistered} Total',
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? AgrivaColors.primaryAccentDark : AgrivaColors.primary),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF163E24) : const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '${stats[i].approved} Verified',
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF4ADE80) : const Color(0xFF2E7D32)),
                                        ),
                                      ),
                                      if (stats[i].pending > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF3E2D12) : AgrivaColors.warningBg,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${stats[i].pending} Pending',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFFBBF24) : AgrivaColors.warning),
                                          ),
                                        ),
                                      if (stats[i].escalated > 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: isDark ? const Color(0xFF3E2512) : AgrivaColors.goldLight,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${stats[i].escalated} Escalated',
                                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFFF59E0B) : AgrivaColors.goldDark),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DailyProcurementBarChart extends StatelessWidget {
  final List<double> quantities;
  final List<String> labels;

  const _DailyProcurementBarChart({
    required this.quantities,
    required this.labels,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AgrivaColors.surfaceDark : Colors.white;
    final cardBorder = isDark ? AgrivaColors.borderDark : AgrivaColors.border;
    final primaryColor = isDark ? AgrivaColors.primaryAccentDark : AgrivaColors.primary;
    final inactiveBarColor = isDark ? const Color(0xFF263B2E) : const Color(0xFFE8ECE9);

    final maxQ = quantities.fold<double>(0, (a, b) => a > b ? a : b);
    final safeMax = maxQ <= 0 ? 100.0 : maxQ;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < quantities.length && i < labels.length; i++) ...[
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (quantities[i] > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              '${quantities[i].toStringAsFixed(0)}Q',
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.w700,
                                color: primaryColor,
                              ),
                            ),
                          ),
                        Container(
                          height: (100 * (quantities[i] / safeMax)).clamp(6.0, 100.0),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: quantities[i] > 0
                                ? primaryColor
                                : inactiveBarColor,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(5)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                Expanded(
                  child: Text(
                    labels[i],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: i == labels.length - 1 ? FontWeight.w700 : FontWeight.w500,
                      color: i == labels.length - 1 ? primaryColor : (isDark ? AgrivaColors.textSecondaryDark : AgrivaColors.textMuted),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProcurementStatusCard extends StatelessWidget {
  final int completed;
  final int inProgress;
  final int upcoming;
  final int cancelled;
  final int total;

  const _ProcurementStatusCard({
    required this.completed,
    required this.inProgress,
    required this.upcoming,
    required this.cancelled,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AgrivaColors.surfaceDark : Colors.white;
    final cardBorder = isDark ? AgrivaColors.borderDark : AgrivaColors.border;
    final inactiveBarColor = isDark ? const Color(0xFF263B2E) : const Color(0xFFE8ECE9);

    final hasData = (completed + inProgress + upcoming + cancelled) > 0;
    final safeTotal = hasData ? (completed + inProgress + upcoming + cancelled) : 1;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Segmented Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: hasData
                  ? Row(
                      children: [
                        if (completed > 0)
                          Expanded(
                            flex: completed,
                            child: Container(color: AgrivaColors.success),
                          ),
                        if (inProgress > 0)
                          Expanded(
                            flex: inProgress,
                            child: Container(color: AgrivaColors.warning),
                          ),
                        if (upcoming > 0)
                          Expanded(
                            flex: upcoming,
                            child: Container(color: AgrivaColors.info),
                          ),
                        if (cancelled > 0)
                          Expanded(
                            flex: cancelled,
                            child: Container(color: isDark ? const Color(0xFF64748B) : AgrivaColors.textMuted),
                          ),
                      ],
                    )
                  : Container(color: inactiveBarColor),
            ),
          ),
          const SizedBox(height: 16),
          // Legend Breakdown
          _LegendRow(label: 'Completed', count: completed, total: safeTotal, color: isDark ? const Color(0xFF4ADE80) : AgrivaColors.success),
          _LegendRow(label: 'In Progress', count: inProgress, total: safeTotal, color: isDark ? const Color(0xFFFBBF24) : AgrivaColors.warning),
          _LegendRow(label: 'Upcoming', count: upcoming, total: safeTotal, color: isDark ? const Color(0xFF60A5FA) : AgrivaColors.info),
          _LegendRow(label: 'Cancelled / No-Show', count: cancelled, total: safeTotal, color: isDark ? const Color(0xFF94A3B8) : AgrivaColors.textMuted),
        ],
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final int count;
  final int total;
  final Color color;

  const _LegendRow({
    required this.label,
    required this.count,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pct = total == 0 ? 0 : (count / total * 100).round();
    final textColor = isDark ? AgrivaColors.textPrimaryDark : AgrivaColors.textPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13, color: textColor)),
          ),
          Text(
            '$count ($pct%)',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textColor),
          ),
        ],
      ),
    );
  }
}
