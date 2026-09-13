import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/theme.dart';
import '../../core/utils/list_extensions.dart';
import '../../models/booking.dart';
import '../../models/centre.dart';
import '../../models/crop.dart';
import '../../models/enums.dart';
import '../../models/farmer.dart';
import '../../models/slot.dart';
import '../../repositories/repository_providers.dart';
import '../../state/auth_controller.dart';
import '../../state/booking_controller.dart';
import '../../state/data_revision.dart';
import '../../state/locale_controller.dart';
import '../../widgets/alert_banner.dart';
import '../../widgets/app_states.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/max_width_body.dart';
import '../../widgets/status_badge.dart';

const _upcomingCardStatuses = [
  BookingStatus.booked,
  BookingStatus.checkedIn,
  BookingStatus.inQueue,
  BookingStatus.underQualityCheck,
  BookingStatus.rescheduleRequired,
];

class _HomeData {
  final Farmer farmer;
  final Booking? upcoming;
  final Slot? upcomingSlot;
  final ProcurementCentre? upcomingCentre;
  final Booking? rescheduleNeeded;

  const _HomeData({
    required this.farmer,
    this.upcoming,
    this.upcomingSlot,
    this.upcomingCentre,
    this.rescheduleNeeded,
  });
}

final _homeDataProvider = FutureProvider.family<_HomeData?, String>((
  ref,
  farmerId,
) async {
  ref.watch(dataRevisionProvider);
  final farmer = await ref.read(farmerRepositoryProvider).getById(farmerId);
  if (farmer == null) return null;

  final bookings = await ref.read(bookingRepositoryProvider).forFarmer(farmerId);
  final slotRepo = ref.read(slotRepositoryProvider);

  final upcomingCandidates = bookings
      .where((b) => _upcomingCardStatuses.contains(b.status))
      .toList();
  Booking? upcoming;
  Slot? upcomingSlot;
  DateTime? earliest;
  for (final b in upcomingCandidates) {
    final slot = await slotRepo.getById(b.slotId);
    if (slot == null) continue;
    if (earliest == null || slot.start.isBefore(earliest)) {
      earliest = slot.start;
      upcoming = b;
      upcomingSlot = slot;
    }
  }
  final upcomingCentre = upcoming != null
      ? await ref.read(centreRepositoryProvider).getById(upcoming.centreId)
      : null;

  final rescheduleNeeded = bookings
      .where((b) => b.status == BookingStatus.rescheduleRequired)
      .firstOrNull;

  return _HomeData(
    farmer: farmer,
    upcoming: upcoming,
    upcomingSlot: upcomingSlot,
    upcomingCentre: upcomingCentre,
    rescheduleNeeded: rescheduleNeeded,
  );
});

class FarmerHomeScreen extends ConsumerWidget {
  final VoidCallback onGoToQueue;
  final VoidCallback onGoToBookings;
  const FarmerHomeScreen({
    super.key,
    required this.onGoToQueue,
    required this.onGoToBookings,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();
    final data = ref.watch(_homeDataProvider(user.id));
    final cropsAsync = ref.watch(activeCropsProvider);
    final currentLocale = ref.watch(localeControllerProvider) ?? const Locale('en');

    return data.when(
      loading: () => const Scaffold(body: LoadingState()),
      error: (e, st) => const Scaffold(body: ErrorState()),
      data: (home) {
        if (home == null) return const Scaffold(body: ErrorState());
        final farmer = home.farmer;
        final upcoming = home.upcoming;

        return Scaffold(
          backgroundColor: AgrivaColors.backgroundFor(context),
          appBar: AppBar(
            title: Row(
              children: [
                Image.asset(
                  'assets/images/app_icon.png',
                  height: 28,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              farmer.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: farmer.isVerified ? AgrivaColors.gold : AgrivaColors.warning,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              farmer.isVerified ? 'VERIFIED' : 'VERIFICATION PENDING',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${farmer.village}, ${farmer.district} • ID: ${farmer.farmerCode}',
                        style: const TextStyle(fontSize: 11, color: Colors.white70),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Language switcher icon
              PopupMenuButton<Locale>(
                tooltip: 'Language',
                initialValue: currentLocale,
                icon: const Icon(Icons.translate_rounded),
                onSelected: (locale) {
                  ref.read(localeControllerProvider.notifier).setLocale(locale);
                },
                itemBuilder: (context) => supportedAgrivaLocales.map((l) {
                  final isSelected = l.languageCode == currentLocale.languageCode;
                  return PopupMenuItem<Locale>(
                    value: l,
                    child: Row(
                      children: [
                        Text(
                          localeDisplayNames[l.languageCode] ?? l.languageCode,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AgrivaColors.primary : AgrivaColors.textPrimaryFor(context),
                          ),
                        ),
                        if (isSelected) ...[
                          const Spacer(),
                          const Icon(Icons.check, size: 16, color: AgrivaColors.primary),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
              IconButton(
                icon: const Icon(Icons.notifications_none_outlined),
                onPressed: () => context.push('/farmer/notifications'),
              ),
              IconButton(
                icon: const Icon(Icons.logout_rounded),
                tooltip: 'Sign Out',
                onPressed: () => showAgrivaSignOutDialog(context, ref),
              ),
            ],
          ),
          body: MaxWidthBody(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(_homeDataProvider(user.id)),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Disruption Alert if any
                  if (home.rescheduleNeeded != null) ...[
                    const AlertBanner(
                      title: 'Procurement Centre Delay Alert',
                      message:
                          'Your scheduled procurement centre has reported a capacity disruption. Review and accept your priority replacement slot.',
                      tone: StatusTone.warning,
                      icon: Icons.warning_amber_rounded,
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.change_circle_outlined, size: 18),
                        label: const Text('Review Priority Replacement Slot'),
                        onPressed: () => context.push(
                          '/farmer/reschedule/${home.rescheduleNeeded!.id}',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Live MSP Season Ticker (real master data from the State
                  // Admin's crop/MSP list, not a fixed snapshot)
                  cropsAsync.when(
                    data: (crops) => crops.isEmpty
                        ? const SizedBox.shrink()
                        : _buildMspTicker(context, crops),
                    loading: () => const SizedBox.shrink(),
                    error: (e, st) => const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 16),

                  // Farmer Registration Verification Status Banner
                  if (!farmer.isVerified) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: farmer.verificationStatus == FarmerVerificationStatus.escalatedToDistrict
                            ? const Color(0xFFEDE7F6)
                            : const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: farmer.verificationStatus == FarmerVerificationStatus.escalatedToDistrict
                              ? const Color(0xFFB39DDB)
                              : const Color(0xFFFFD54F),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            farmer.verificationStatus == FarmerVerificationStatus.escalatedToDistrict
                                ? Icons.hourglass_top_rounded
                                : Icons.pending_actions_rounded,
                            color: farmer.verificationStatus == FarmerVerificationStatus.escalatedToDistrict
                                ? const Color(0xFF5E35B1)
                                : const Color(0xFFF57F17),
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  farmer.verificationStatus == FarmerVerificationStatus.escalatedToDistrict
                                      ? 'Registration Under District Review'
                                      : 'Profile Pending Centre Verification',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14,
                                    color: farmer.verificationStatus == FarmerVerificationStatus.escalatedToDistrict
                                        ? const Color(0xFF4527A0)
                                        : const Color(0xFFE65100),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  farmer.verificationStatus == FarmerVerificationStatus.escalatedToDistrict
                                      ? 'Your profile has been forwarded to the District Administration for verification clearance. Slot booking will unlock once approved.'
                                      : 'Your registration is routed to your regional centre (${farmer.assignedCentreId.isNotEmpty ? farmer.assignedCentreId : "assigned centre"}). The operator must approve your identity and land documents before slot booking is unlocked.',
                                  style: TextStyle(fontSize: 12, color: AgrivaColors.textPrimaryFor(context)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Section Title: Active Procurement Booking
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Procurement Booking',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimaryFor(context)),
                      ),
                      if (upcoming != null)
                        TextButton(
                          onPressed: onGoToBookings,
                          child: const Text('All Bookings →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (upcoming == null || home.upcomingSlot == null || home.upcomingCentre == null)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                      decoration: BoxDecoration(
                        color: AgrivaColors.surfaceFor(context),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AgrivaColors.borderFor(context)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: EmptyState(
                        icon: Icons.agriculture_rounded,
                        title: 'No Active Slot Booking',
                        message: farmer.isVerified
                            ? 'Book a certified government slot to sell your harvest at guaranteed MSP.'
                            : 'Slot booking will unlock once your profile is approved by the Centre Operator.',
                        actionLabel: farmer.isVerified ? 'Book Procurement Slot' : 'View Verification Status',
                        onAction: () => context.push('/farmer/book-slot'),
                      ),
                    )
                  else ...[
                    _UpcomingSlotCard(
                      booking: upcoming,
                      slot: home.upcomingSlot!,
                      centre: home.upcomingCentre!,
                    ),
                    if (upcoming.status == BookingStatus.inQueue ||
                        upcoming.status == BookingStatus.underQualityCheck ||
                        upcoming.status == BookingStatus.checkedIn) ...[
                      const SizedBox(height: 12),
                      _DashboardQueueStats(booking: upcoming, onGoToQueue: onGoToQueue),
                    ],
                  ],

                  const SizedBox(height: 22),

                  // Quick Actions Grid (2x2)
                  Text(
                    'Quick Services',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimaryFor(context)),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Book Slot',
                          subtitle: 'Book grain token',
                          accentColor: AgrivaColors.primary,
                          onTap: () => context.push('/farmer/book-slot'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.event_note_rounded,
                          title: 'My Bookings',
                          subtitle: 'History & status',
                          accentColor: AgrivaColors.info,
                          onTap: onGoToBookings,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.hourglass_top_rounded,
                          title: 'Live Queue',
                          subtitle: 'Track centre tokens',
                          accentColor: AgrivaColors.gold,
                          onTap: onGoToQueue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.report_problem_outlined,
                          title: 'Grievances',
                          subtitle: 'Disputes & delays',
                          accentColor: AgrivaColors.error,
                          onTap: () => context.push('/farmer/grievances'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Farmer Assistance Card
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AgrivaColors.primaryLight50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AgrivaColors.borderFor(context)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.headset_mic_rounded, color: AgrivaColors.primary, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kisan Procurement Helpline: 1800-180-1551',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AgrivaColors.primaryDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Toll-free DoCA grain assistance (8:00 AM – 8:00 PM)',
                                style: TextStyle(fontSize: 11, color: AgrivaColors.textSecondaryFor(context)),
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
          ),
        );
      },
    );
  }

  Widget _buildMspTicker(BuildContext context, List<Crop> crops) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AgrivaColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AgrivaColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, size: 16, color: AgrivaColors.gold),
              const SizedBox(width: 6),
              Text(
                'Government Guaranteed MSP Rates 2026',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimaryFor(context)),
              ),
              const Spacer(),
              const Text(
                'DoCA Verified',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AgrivaColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: crops.map((c) {
                return Container(
                  margin: const EdgeInsets.only(right: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AgrivaColors.primaryLight50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AgrivaColors.borderFor(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${c.name} (${c.season.label})',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AgrivaColors.textPrimaryFor(context)),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '₹${c.msp.toStringAsFixed(0)}/Q',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AgrivaColors.primary),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingSlotCard extends ConsumerWidget {
  final Booking booking;
  final Slot slot;
  final ProcurementCentre centre;
  const _UpcomingSlotCard({
    required this.booking,
    required this.slot,
    required this.centre,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AgrivaColors.surfaceFor(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AgrivaColors.borderFor(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AgrivaColors.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.grain_rounded, color: AgrivaColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      centre.name,
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AgrivaColors.textPrimaryFor(context)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${DateFormat('d MMM yyyy').format(slot.start)} • ${DateFormat('h:mm a').format(slot.start)} – ${DateFormat('h:mm a').format(slot.end)}',
                      style: TextStyle(color: AgrivaColors.textSecondaryFor(context), fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: booking.status.label,
                tone: switch (booking.status) {
                  BookingStatus.booked || BookingStatus.checkedIn => StatusTone.success,
                  BookingStatus.inQueue ||
                  BookingStatus.underQualityCheck ||
                  BookingStatus.rescheduleRequired => StatusTone.warning,
                  _ => StatusTone.inactive,
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _MiniStat(label: 'Token Number', value: '#${booking.token}')),
              Expanded(
                child: _MiniStat(
                  label: 'Booked Quantity',
                  value: '${booking.expectedQuantityQ.toStringAsFixed(0)} Quintals',
                ),
              ),
              Expanded(child: _MiniStat(label: 'Taluk / Block', value: centre.taluk)),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.receipt_long_rounded, size: 16),
              label: const Text('View Booking Token & Details'),
              onPressed: () => context.push('/farmer/booking/${booking.id}'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardQueueStats extends ConsumerWidget {
  final Booking booking;
  final VoidCallback onGoToQueue;
  const _DashboardQueueStats({required this.booking, required this.onGoToQueue});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final position = ref.watch(queuePositionProvider(booking.id)).value ?? -1;
    final wait = ref.watch(estimatedWaitProvider(booking.id)).value ?? 0;
    final total = ref.watch(queueTotalForCentreProvider(booking.centreId)).value ?? 0;

    return InkWell(
      onTap: onGoToQueue,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AgrivaColors.primaryLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AgrivaColors.primaryMedium.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                color: AgrivaColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.timer_outlined, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Queue Position',
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AgrivaColors.primaryDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    position <= 0 ? 'Checked in — Preparing token call' : 'Token #$position of $total in line',
                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AgrivaColors.primary),
                  ),
                  Text(
                    'Estimated wait: ~$wait mins • Tap for live token monitor',
                    style: TextStyle(fontSize: 11, color: AgrivaColors.textSecondaryFor(context)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AgrivaColors.primary),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AgrivaColors.textMutedFor(context), fontWeight: FontWeight.w500)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimaryFor(context))),
      ],
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AgrivaColors.surfaceFor(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AgrivaColors.borderFor(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AgrivaColors.textPrimaryFor(context)),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: AgrivaColors.textSecondaryFor(context)),
            ),
          ],
        ),
      ),
    );
  }
}
