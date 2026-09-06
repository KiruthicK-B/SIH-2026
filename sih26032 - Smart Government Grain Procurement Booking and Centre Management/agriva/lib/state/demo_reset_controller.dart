import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seed_data_service.dart';
import '../repositories/local/hive_json_repository.dart';
import '../repositories/repository_providers.dart';
import 'auth_controller.dart';
import 'data_revision.dart';

final demoResetControllerProvider = Provider(
  (ref) => DemoResetController(ref),
);

/// Wipes every Hive box and reseeds the wide demo dataset — for jury/demo
/// resets and for local development, not a README-required feature.
class DemoResetController {
  final Ref ref;
  const DemoResetController(this.ref);

  Future<void> resetDemo() async {
    for (final name in HiveBootstrap.boxNames) {
      await HiveBootstrap.box(name).clear();
    }
    await SeedDataService(
      farmerRepo: ref.read(farmerRepositoryProvider),
      landRecordRepo: ref.read(landRecordRepositoryProvider),
      cropRepo: ref.read(cropRepositoryProvider),
      centreRepo: ref.read(centreRepositoryProvider),
      slotRepo: ref.read(slotRepositoryProvider),
      districtRepo: ref.read(districtRepositoryProvider),
      bookingRepo: ref.read(bookingRepositoryProvider),
      queueRepo: ref.read(queueRepositoryProvider),
      procurementRepo: ref.read(procurementRepositoryProvider),
      paymentRepo: ref.read(paymentRepositoryProvider),
      disruptionRepo: ref.read(disruptionRepositoryProvider),
      adminRepo: ref.read(adminRepositoryProvider),
      broadcastRepo: ref.read(broadcastRepositoryProvider),
      grievanceRepo: ref.read(grievanceRepositoryProvider),
      notificationRepo: ref.read(notificationRepositoryProvider),
    ).seedIfEmpty();
    await ref.read(authControllerProvider.notifier).logout();
    ref.read(dataRevisionProvider.notifier).bump();
  }
}
