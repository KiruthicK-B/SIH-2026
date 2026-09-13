import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/theme.dart';
import 'data/seed_data_service.dart';
import 'repositories/local/hive_json_repository.dart';
import 'repositories/repository_providers.dart';
import 'state/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const _BootstrapApp());
}

class _BootstrapApp extends StatefulWidget {
  const _BootstrapApp();

  @override
  State<_BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<_BootstrapApp> {
  ProviderContainer? _container;
  Object? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initialize();
    });
  }

  Future<void> _initialize() async {
    try {
      await HiveBootstrap.init();

      final container = ProviderContainer();
      final seedService = SeedDataService(
        farmerRepo: container.read(farmerRepositoryProvider),
        landRecordRepo: container.read(landRecordRepositoryProvider),
        cropRepo: container.read(cropRepositoryProvider),
        centreRepo: container.read(centreRepositoryProvider),
        slotRepo: container.read(slotRepositoryProvider),
        districtRepo: container.read(districtRepositoryProvider),
        bookingRepo: container.read(bookingRepositoryProvider),
        queueRepo: container.read(queueRepositoryProvider),
        procurementRepo: container.read(procurementRepositoryProvider),
        paymentRepo: container.read(paymentRepositoryProvider),
        disruptionRepo: container.read(disruptionRepositoryProvider),
        adminRepo: container.read(adminRepositoryProvider),
        broadcastRepo: container.read(broadcastRepositoryProvider),
        grievanceRepo: container.read(grievanceRepositoryProvider),
        notificationRepo: container.read(notificationRepositoryProvider),
      );

      if (!mounted) {
        container.dispose();
        return;
      }
      // Await database seeding before mounting AgrivaApp so the UI never mounts
      // against half-cleared or unseeded Hive boxes on cold launch or hot restart (R).
      try {
        await seedService.seedIfEmpty();
        await seedService.ensureUpcomingSlots();
      } catch (seedErr) {
        debugPrint('Agriva seed failed: $seedErr');
      }

      // Restore user session if previously logged in so returning to the app
      // maintains the active dashboard (Farmer, Operator, District, State).
      try {
        await container.read(authControllerProvider.notifier).restoreSession();
      } catch (sessionErr) {
        debugPrint('Agriva session restore failed: $sessionErr');
      }

      if (!mounted) {
        container.dispose();
        return;
      }
      setState(() => _container = container);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final container = _container;
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: const AgrivaApp(),
      );
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AgrivaTheme.light,
      home: Scaffold(
        backgroundColor: AgrivaColors.surface,
        body: Center(
          child: _error == null
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image(
                      image: AssetImage('assets/images/app_icon.png'),
                      height: 72,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 18),
                    CircularProgressIndicator(color: AgrivaColors.primary),
                  ],
                )
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Unable to start Agriva.\n$_error',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AgrivaColors.error,
                      fontSize: 16,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
