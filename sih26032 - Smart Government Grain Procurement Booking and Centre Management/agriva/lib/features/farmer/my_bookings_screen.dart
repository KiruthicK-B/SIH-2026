import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking.dart';
import '../../models/enums.dart';
import '../../providers/app_state_provider.dart';
import '../../widgets/agriva_app_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/booking_card.dart';
import '../../widgets/max_width_body.dart';

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(
    length: 2,
    vsync: this,
  );

  static const _upcomingStatuses = [
    BookingStatus.confirmed,
    BookingStatus.checkedIn,
    BookingStatus.inQueue,
    BookingStatus.processing,
    BookingStatus.rescheduleRequired,
    BookingStatus.waitlisted,
  ];

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final farmerId = appState.currentUser!.id;
    final myBookings =
        appState.bookings.where((b) => b.farmerId == farmerId).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final upcoming = myBookings
        .where((b) => _upcomingStatuses.contains(b.status))
        .toList();
    final past = myBookings
        .where((b) => !_upcomingStatuses.contains(b.status))
        .toList();

    return Scaffold(
      appBar: AgrivaAppBar(
        title: 'My Bookings',
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Upcoming'),
                Tab(text: 'Past'),
              ],
              indicatorColor: Colors.white,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: MaxWidthBody(
        child: TabBarView(
          controller: _tabController,
          children: [
            _BookingList(
              bookings: upcoming,
              emptyMessage:
                  'No upcoming bookings.\nBook a slot to get started.',
            ),
            _BookingList(
              bookings: past,
              emptyMessage: 'No booking history yet.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingList extends ConsumerWidget {
  final List<Booking> bookings;
  final String emptyMessage;
  const _BookingList({required this.bookings, required this.emptyMessage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) {
      return EmptyState(
        icon: Icons.calendar_today_outlined,
        title: 'Nothing here',
        message: emptyMessage,
      );
    }
    final appState = ref.watch(appStateProvider);
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final booking = bookings[i];
        final slot = appState.slots.firstWhere((s) => s.id == booking.slotId);
        final centre = appState.centres.firstWhere(
          (c) => c.id == booking.centreId,
        );
        return BookingCard(
          booking: booking,
          slot: slot,
          centre: centre,
          onTap: () => context.push('/farmer/booking/${booking.id}'),
          onReschedule: () => context.push('/farmer/reschedule/${booking.id}'),
          onCancel: () {
            final result = ref
                .read(appStateProvider.notifier)
                .cancelBooking(booking.id);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(result.message)));
          },
        );
      },
    );
  }
}
