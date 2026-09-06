import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:agriva/app/theme.dart';
import 'package:agriva/models/admin_user.dart';
import 'package:agriva/models/enums.dart';
import 'package:agriva/models/user.dart';
import 'package:agriva/repositories/local/hive_json_repository.dart';
import 'package:agriva/repositories/repository_providers.dart';
import 'package:agriva/state/auth_controller.dart';
import 'package:agriva/widgets/metric_card.dart';
import 'package:agriva/features/operator/operator_more_screen.dart';
import 'package:agriva/features/manager/manager_more_screen.dart';
import 'package:agriva/features/manager/manager_shell.dart';
import 'package:agriva/features/state_admin/state_admin_account_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetricCard Layout Safety', () {
    testWidgets('MetricCard builds inside an unbounded Row without throwing flex error', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AgrivaTheme.light,
          home: Scaffold(
            body: Row(
              children: const [
                Expanded(
                  child: MetricCard(
                    icon: Icons.event_note,
                    label: 'Total Bookings',
                    value: '12',
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: MetricCard(
                    icon: Icons.check_circle,
                    label: 'Completed',
                    value: '8',
                    accent: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Total Bookings'), findsOneWidget);
      expect(find.text('12'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
    });

    testWidgets('MetricCard builds inside GridView with 1.25 aspect ratio without overflowing', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AgrivaTheme.light,
          home: Scaffold(
            body: GridView.count(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              children: const [
                MetricCard(icon: Icons.store, label: 'Centres', value: '13'),
                MetricCard(icon: Icons.people, label: 'Farmers', value: '45'),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Centres'), findsOneWidget);
      expect(find.text('13'), findsOneWidget);
    });
  });

  group('Account and Profile Screens Layout', () {
    testWidgets('OperatorMoreScreen builds without overflowing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _TestAuthController(
            const AppUser(
              id: 'admin-op-erode-01',
              name: 'K. Shanmugam',
              role: UserRole.centreOperator,
              centreId: 'centre-erode-01',
              district: 'district-erode',
            ),
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AgrivaTheme.light,
            home: const OperatorMoreScreen(),
          ),
        ),
      );
      expect(find.text('K. Shanmugam'), findsOneWidget);
      expect(find.text('CENTRE OPERATOR'), findsOneWidget);
      expect(find.text('Sign Out to Login Portal'), findsOneWidget);
    });

    testWidgets('ManagerMoreScreen builds without overflowing', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

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
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AgrivaTheme.light,
            home: const ManagerMoreScreen(),
          ),
        ),
      );
      expect(find.text('Thiru. S. Kandasamy, IAS'), findsOneWidget);
      expect(find.text('DISTRICT ADMIN'), findsOneWidget);
      expect(find.text('Sign Out to Login Portal'), findsOneWidget);
    });

    testWidgets('StateAdminAccountScreen builds without overflowing or overriding', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer(
        overrides: [
          authControllerProvider.overrideWith(() => _TestAuthController(
            const AppUser(
              id: 'admin-st-admin',
              name: 'Dr. K. Vijayakumar, IAS',
              role: UserRole.stateAdmin,
            ),
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AgrivaTheme.light,
            home: const StateAdminAccountScreen(),
          ),
        ),
      );
      expect(find.text('Dr. K. Vijayakumar, IAS'), findsOneWidget);
      expect(find.text('STATE HEAD'), findsOneWidget);
      expect(find.text('Sign Out to Login Portal'), findsOneWidget);
    });
  });

  group('Session Restoration', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('agriva_test_');
      Hive.init(tempDir.path);
      for (final boxName in HiveBootstrap.boxNames) {
        await Hive.openBox<String>(boxName);
      }
    });

    tearDown(() async {
      await Hive.close();
      try {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      } catch (_) {}
    });

    test('AuthController saves and restores session from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'agriva_session': 'districtAdmin|admin-dt-erode',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final auth = container.read(authControllerProvider.notifier);
      expect(container.read(authControllerProvider), isNull);

      final adminRepo = container.read(adminRepositoryProvider);
      await adminRepo.save(
        const AdminUser(
          id: 'admin-dt-erode',
          name: 'Thiru. S. Kandasamy, IAS',
          role: UserRole.districtAdmin,
          employeeId: 'DT-Erode',
          passwordHash: 'agriva123',
          district: 'district-erode',
        ),
      );

      await auth.restoreSession();
      final restored = container.read(authControllerProvider);
      expect(restored, isNotNull);
      expect(restored?.name, 'Thiru. S. Kandasamy, IAS');
      expect(restored?.role, UserRole.districtAdmin);
      expect(restored?.district, 'district-erode');
    });

    testWidgets('ManagerDashboardScreen and ManagerShell build and display fully', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final admin = const AdminUser(
        id: 'admin-dt-erode',
        name: 'Thiru. S. Kandasamy, IAS',
        role: UserRole.districtAdmin,
        employeeId: 'DT-Erode',
        passwordHash: 'agriva123',
        district: 'district-erode',
      );
      await container.read(adminRepositoryProvider).save(admin);
      await container.read(authControllerProvider.notifier).loginAsAdmin(admin);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AgrivaTheme.light,
            home: const ManagerShell(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('District Admin'), findsOneWidget);
      expect(find.text('Erode District'), findsOneWidget);
    });
  });
}

class _TestAuthController extends AuthController {
  final AppUser? initialUser;
  _TestAuthController(this.initialUser);

  @override
  AppUser? build() => initialUser;
}
