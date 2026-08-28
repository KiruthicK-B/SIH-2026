import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/common/splash_screen.dart';
import '../features/common/role_select_screen.dart';
import '../features/farmer/farmer_shell.dart';
import '../features/farmer/book_slot_screen.dart';
import '../features/farmer/booking_details_screen.dart';
import '../features/farmer/notifications_screen.dart';
import '../features/farmer/reschedule_screen.dart';
import '../features/operator/operator_shell.dart';
import '../features/operator/checkin_screen.dart';
import '../features/operator/declare_disruption_screen.dart';
import '../features/operator/quality_inspection_screen.dart';
import '../features/operator/weighment_screen.dart';
import '../features/operator/payments_list_screen.dart';
import '../features/operator/demo_controls_screen.dart';
import '../features/manager/manager_shell.dart';
import '../providers/app_state_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final appState = ref.read(appStateProvider);
      final loggedIn = appState.currentUser != null;
      final loc = state.matchedLocation;

      if (loc == '/splash') return null;
      if (!loggedIn && loc != '/role-select') return '/role-select';
      if (loggedIn && loc == '/role-select') {
        return switch (appState.currentUser!.role.name) {
          'farmer' => '/farmer',
          'operator' => '/operator',
          'manager' => '/manager',
          _ => '/operator',
        };
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/role-select',
        builder: (context, state) => const RoleSelectScreen(),
      ),

      GoRoute(
        path: '/farmer',
        builder: (context, state) => const FarmerShell(),
      ),
      GoRoute(
        path: '/farmer/book-slot',
        builder: (context, state) => const BookSlotScreen(),
      ),
      GoRoute(
        path: '/farmer/booking/:id',
        builder: (context, state) =>
            BookingDetailsScreen(bookingId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/farmer/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/farmer/reschedule/:bookingId',
        builder: (context, state) =>
            RescheduleScreen(bookingId: state.pathParameters['bookingId']!),
      ),

      GoRoute(
        path: '/operator',
        builder: (context, state) => const OperatorShell(),
      ),
      GoRoute(
        path: '/operator/checkin/:bookingId',
        builder: (context, state) =>
            CheckinScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: '/operator/disruption',
        builder: (context, state) => const DeclareDisruptionScreen(),
      ),
      GoRoute(
        path: '/operator/quality/:bookingId',
        builder: (context, state) => QualityInspectionScreen(
          bookingId: state.pathParameters['bookingId']!,
        ),
      ),
      GoRoute(
        path: '/operator/weighment/:bookingId',
        builder: (context, state) =>
            WeighmentScreen(bookingId: state.pathParameters['bookingId']!),
      ),
      GoRoute(
        path: '/operator/payments',
        builder: (context, state) => const PaymentsListScreen(),
      ),
      GoRoute(
        path: '/operator/demo-controls',
        builder: (context, state) => const DemoControlsScreen(),
      ),

      GoRoute(
        path: '/manager',
        builder: (context, state) => const ManagerShell(),
      ),
    ],
  );
});

/// Bridges Riverpod state changes into go_router's redirect re-evaluation.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(appStateProvider, (prev, next) {
      if (prev?.currentUser != next.currentUser) notifyListeners();
    });
  }
}
