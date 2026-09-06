import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/seed_data_service.dart';
import '../repositories/repository_providers.dart';
import 'auth_controller.dart';
import 'data_revision.dart';

final demoResetControllerProvider = Provider(
  (ref) => DemoResetController(ref),
);

/// Wipes every entity through its repository (works against whichever
/// backend repository_providers.dart currently wires — Local/Hive or
/// Remote/HTTP) and reseeds the wide demo dataset — for jury/demo resets
/// and for local development, not a README-required feature.
class DemoResetController {
  final Ref ref;
  const DemoResetController(this.ref);

  Future<void> resetDemo() async {
    await ref.read(farmerRepositoryProvider).clear();
    await ref.read(landRecordRepositoryProvider).clear();
    await ref.read(cropRepositoryProvider).clear();
    await ref.read(centreRepositoryProvider).clear();
    await ref.read(slotRepositoryProvider).clear();
    await ref.read(districtRepositoryProvider).clear();
    await ref.read(bookingRepositoryProvider).clear();
    await ref.read(queueRepositoryProvider).clear();
    await ref.read(procurementRepositoryProvider).clear();
    await ref.read(paymentRepositoryProvider).clear();
    await ref.read(rescheduleOfferRepositoryProvider).clear();
    await ref.read(disruptionRepositoryProvider).clear();
    await ref.read(adminRepositoryProvider).clear();
    await ref.read(broadcastRepositoryProvider).clear();
    await ref.read(grievanceRepositoryProvider).clear();
    await ref.read(notificationRepositoryProvider).clear();
    await ref.read(auditLogRepositoryProvider).clear();

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
