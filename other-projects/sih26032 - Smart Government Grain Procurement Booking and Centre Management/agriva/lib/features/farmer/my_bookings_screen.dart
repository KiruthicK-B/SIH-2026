import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/booking.dart';
import '../../models/enums.dart';
import '../../state/auth_controller.dart';
import '../../state/booking_controller.dart';
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
  late final TabController _tabController = TabController(length: 2, vsync: this);

  static const _upcomingStatuses = [
    BookingStatus.booked,
    BookingStatus.checkedIn,
    BookingStatus.inQueue,
    BookingStatus.underQualityCheck,
    BookingStatus.rescheduleRequired,
    BookingStatus.waitlisted,
  ];

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider);
    if (user == null) return const SizedBox.shrink();
    final bookingsAsync = ref.watch(bookingsForFarmerProvider(user.id));

    return Scaffold(
      appBar: AgrivaAppBar(
        title: 'My Bookings',
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Past')],
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
        ),
      ),
      body: MaxWidthBody(
        child: bookingsAsync.when(
          loading: () => const LoadingState(),
          error: (e, st) => const ErrorState(),
          data: (all) {
            final sorted = [...all]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
            final upcoming = sorted.where((b) => _upcomingStatuses.contains(b.status)).toList();
            final past = sorted.where((b) => !_upcomingStatuses.contains(b.status)).toList();
            return TabBarView(
              controller: _tabController,
              children: [
                _BookingList(
                  bookings: upcoming,
                  emptyMessage: 'No upcoming bookings.\nBook a slot to get started.',
                ),
                _BookingList(bookings: past, emptyMessage: 'No booking history yet.'),
              ],
            );
          },
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
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final booking = bookings[i];
        final slotAsync = ref.watch(slotByIdProvider(booking.slotId));
        final centreAsync = ref.watch(centreByIdProvider(booking.centreId));
        final slot = slotAsync.value;
        final centre = centreAsync.value;
        if (slot == null || centre == null) {
          return const SizedBox(height: 90, child: LoadingState());
        }
        return BookingCard(
          booking: booking,
          slot: slot,
          centre: centre,
          onTap: () => context.push('/farmer/booking/${booking.id}'),
          onReschedule: () => context.push('/farmer/reschedule/${booking.id}'),
          onCancel: () async {
            final result = await ref
                .read(bookingControllerProvider)
                .cancelBooking(booking.id);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
            }
          },
        );
      },
    );
  }
}
