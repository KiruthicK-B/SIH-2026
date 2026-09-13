import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/common/login_screen.dart';
import '../features/common/otp_screen.dart';
import '../features/common/splash_screen.dart';
import '../features/farmer/book_slot_screen.dart';
import '../features/farmer/booking_details_screen.dart';
import '../features/farmer/farmer_shell.dart';
import '../features/farmer/grievances_screen.dart';
import '../features/farmer/notifications_screen.dart';
import '../features/farmer/raise_grievance_screen.dart';
import '../features/farmer/registration_screen.dart';
import '../features/farmer/reschedule_screen.dart';
import '../features/manager/manager_shell.dart';
import '../features/manager/manager_verifications_screen.dart';
import '../features/operator/checkin_screen.dart';
import '../features/operator/declare_disruption_screen.dart';
import '../features/operator/demo_controls_screen.dart';
import '../features/operator/operator_grievances_screen.dart';
import '../features/operator/operator_shell.dart';
import '../features/operator/operator_verifications_screen.dart';
import '../features/operator/payments_list_screen.dart';
import '../features/operator/quality_inspection_screen.dart';
import '../features/operator/weighment_screen.dart';
import '../features/state_admin/state_admin_shell.dart';
import '../models/enums.dart';
import '../state/auth_controller.dart';
import '../state/locale_controller.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: _RouterRefresh(ref),
    redirect: (context, state) {
      final user = ref.read(authControllerProvider);
      final loggedIn = user != null;
      final loc = state.matchedLocation;

      if (loc == '/splash') return loggedIn ? _homeForRole(user.role) : null;

      const publicRoutes = ['/login', '/login/otp', '/register'];
      if (!loggedIn && !publicRoutes.contains(loc)) return '/login';
      if (loggedIn && publicRoutes.contains(loc)) {
        return _homeForRole(user.role);
      }
      if (loggedIn) {
        final allowed = switch (user.role) {
          UserRole.farmer => loc == '/farmer' || loc.startsWith('/farmer/'),
          UserRole.centreOperator =>
            loc == '/operator' || loc.startsWith('/operator/'),
          UserRole.districtAdmin =>
            loc == '/district-admin' || loc.startsWith('/district-admin/'),
          UserRole.stateAdmin => loc == '/state-admin',
        };
        if (!allowed) return _homeForRole(user.role);
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/login/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) =>
            RegistrationScreen(phone: state.uri.queryParameters['phone'] ?? ''),
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
        path: '/farmer/grievances',
        builder: (context, state) => const GrievancesScreen(),
      ),
      GoRoute(
        path: '/farmer/grievances/new',
        builder: (context, state) => RaiseGrievanceScreen(
          bookingId: state.uri.queryParameters['bookingId'],
        ),
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
        path: '/operator/grievances',
        builder: (context, state) => const OperatorGrievancesScreen(),
      ),
      GoRoute(
        path: '/operator/demo-controls',
        builder: (context, state) => const DemoControlsScreen(),
      ),
      GoRoute(
        path: '/operator/verifications',
        builder: (context, state) => const OperatorVerificationsScreen(),
      ),

      GoRoute(
        path: '/district-admin',
        builder: (context, state) => const ManagerShell(),
      ),
      GoRoute(
        path: '/district-admin/verifications',
        builder: (context, state) => const ManagerVerificationsScreen(),
      ),
      GoRoute(
        path: '/state-admin',
        builder: (context, state) => const StateAdminShell(),
      ),
    ],
  );
});

String _homeForRole(UserRole role) => switch (role) {
  UserRole.farmer => '/farmer',
  UserRole.centreOperator => '/operator',
  UserRole.districtAdmin => '/district-admin',
  UserRole.stateAdmin => '/state-admin',
};

/// Bridges Riverpod state changes into go_router's redirect re-evaluation.
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authControllerProvider, (prev, next) {
      if (prev != next) notifyListeners();
    });
    ref.listen(localeControllerProvider, (prev, next) {
      if (prev != next) notifyListeners();
    });
  }
}
