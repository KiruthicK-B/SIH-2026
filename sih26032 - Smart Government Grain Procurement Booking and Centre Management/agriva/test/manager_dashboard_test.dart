import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agriva/app/theme.dart';
import 'package:agriva/features/manager/district_providers.dart';
import 'package:agriva/features/manager/manager_dashboard_screen.dart';
import 'package:agriva/models/centre.dart';
import 'package:agriva/models/enums.dart';
import 'package:agriva/models/user.dart';
import 'package:agriva/state/auth_controller.dart';

class _TestAuthController extends AuthController {
  final AppUser? initialUser;
  _TestAuthController(this.initialUser);

  @override
  AppUser? build() => initialUser;
}

void main() {
  testWidgets('ManagerDashboardScreen renders all dashboard elements', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final mockDistrictData = DistrictData(
      centres: [
        const ProcurementCentre(
          id: 'c1',
          code: 'C01',
          name: 'Centre 1',
          district: 'district-erode',
          taluk: 'Erode',
          latitude: 11.34,
          longitude: 77.72,
          dailyProcessingCapacityQ: 1000,
          storageCapacityQ: 2000,
          currentStorageQ: 500,
          processingLanesTotal: 2,
          processingLanesActive: 2,
          staffNormal: 4,
          staffAvailable: 4,
          status: CentreStatus.open,
        ),
      ],
      bookings: [],
      disruptions: [],
      rescheduleOffers: [],
      procurementRecords: [],
      payments: [],
    );

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _TestAuthController(
          const AppUser(
            id: 'admin-dt-erode',
            name: 'Thiru. S. Kandasamy, IAS',
            role: UserRole.districtAdmin,
            district: 'district-erode',
          ),
        )),
        districtDataProvider('district-erode').overrideWith((ref) => Future.value(mockDistrictData)),
        pendingFarmerVerificationsProvider('district-erode').overrideWith((ref) => Future.value([])),
        centreFarmerStatsProvider('district-erode').overrideWith((ref) => Future.value([])),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AgrivaTheme.light,
          home: const ManagerDashboardScreen(),
        ),
      ),
    );

    // Initial pump
    await tester.pump();
    // Pump to resolve future
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('District Admin'), findsOneWidget);
    expect(find.text('Erode District'), findsOneWidget);
    expect(find.text('Total Centres'), findsOneWidget);
    expect(find.text('Quantity Procured by Day'), findsOneWidget);
    expect(find.text('Procurement Status'), findsOneWidget);
  });

  testWidgets('ManagerDashboardScreen renders with full realistic data', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const centre = ProcurementCentre(
      id: 'c1',
      code: 'C01',
      name: 'Erode Regulated Market Hub',
      district: 'district-erode',
      taluk: 'Erode',
      latitude: 11.34,
      longitude: 77.72,
      dailyProcessingCapacityQ: 1000,
      storageCapacityQ: 2000,
      currentStorageQ: 500,
      processingLanesTotal: 2,
      processingLanesActive: 2,
      staffNormal: 4,
      staffAvailable: 4,
      status: CentreStatus.open,
    );

    final mockDistrictData = DistrictData(
      centres: [centre],
      bookings: [],
      disruptions: [],
      rescheduleOffers: [],
      procurementRecords: [],
      payments: [],
    );

    final stats = [
      const CentreFarmerStats(
        centre: centre,
        totalRegistered: 120,
        approved: 95,
        pending: 15,
        escalated: 10,
        pendingOverdue: 5,
      ),
    ];

    final container = ProviderContainer(
      overrides: [
        authControllerProvider.overrideWith(() => _TestAuthController(
          const AppUser(
            id: 'admin-dt-erode',
            name: 'Thiru. S. Kandasamy, IAS',
            role: UserRole.districtAdmin,
            district: 'district-erode',
          ),
        )),
        districtDataProvider('district-erode').overrideWith((ref) => Future.value(mockDistrictData)),
        pendingFarmerVerificationsProvider('district-erode').overrideWith((ref) => Future.value([])),
        centreFarmerStatsProvider('district-erode').overrideWith((ref) => Future.value(stats)),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AgrivaTheme.light,
          home: const ManagerDashboardScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('District Admin Action Required'), findsOneWidget);
    expect(find.text('Erode Regulated Market Hub has 5 farmer verifications pending > 48 hrs!'), findsOneWidget);
    expect(find.text('120 Total'), findsOneWidget);
    expect(find.text('95 Verified'), findsOneWidget);
    expect(find.text('15 Pending'), findsOneWidget);
    expect(find.text('10 Escalated'), findsOneWidget);
  });
}
