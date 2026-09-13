import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/admin_user.dart';
import '../models/broadcast.dart';
import '../models/crop.dart';
import '../models/district.dart';
import '../models/enums.dart';
import '../models/notification.dart';
import '../repositories/repository_providers.dart';
import 'data_revision.dart';
import 'op_result.dart';

final cropsProvider = FutureProvider<List<Crop>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.read(cropRepositoryProvider).getAll();
});

final districtsProvider = FutureProvider<List<District>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.read(districtRepositoryProvider).getAll();
});

final adminUsersProvider = FutureProvider<List<AdminUser>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.read(adminRepositoryProvider).getAll();
});

final broadcastsProvider = FutureProvider<List<Broadcast>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.read(broadcastRepositoryProvider).getAll();
});

/// Statewide totals for the State Admin dashboard, computed from the real
/// repositories across every district — not a fixed demo snapshot.
class StatewideSummary {
  final int totalCentres;
  final int farmersToday;
  final double quantityProcuredQ;
  final double paymentsCompletedLakh;

  const StatewideSummary({
    required this.totalCentres,
    required this.farmersToday,
    required this.quantityProcuredQ,
    required this.paymentsCompletedLakh,
  });
}

final statewideSummaryProvider = FutureProvider<StatewideSummary>((ref) async {
  ref.watch(dataRevisionProvider);
  final centres = await ref.read(centreRepositoryProvider).getAll();
  final bookings = await ref.read(bookingRepositoryProvider).getAll();
  final procurementRecords = await ref.read(procurementRepositoryProvider).getAll();
  final payments = await ref.read(paymentRepositoryProvider).getAll();

  final today = DateTime.now();
  bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  final farmersToday = bookings
      .where((b) => b.checkedInAt != null && isSameDay(b.checkedInAt!, today))
      .map((b) => b.farmerId)
      .toSet()
      .length;

  final quantityProcuredQ = procurementRecords.fold<double>(
    0,
    (sum, p) => sum + (p.acceptedQuantityQ ?? 0),
  );

  final paymentsCompletedLakh = payments
          .where((p) => p.status == PaymentStatus.completed)
          .fold<double>(0, (sum, p) => sum + p.amount) /
      100000;

  return StatewideSummary(
    totalCentres: centres.length,
    farmersToday: farmersToday,
    quantityProcuredQ: quantityProcuredQ,
    paymentsCompletedLakh: paymentsCompletedLakh,
  );
});

final stateAdminControllerProvider = Provider<StateAdminController>(
  (ref) => StateAdminController(ref),
);

/// State/Super Admin master-data + account management + broadcasts
/// (README §5.4).
class StateAdminController {
  final Ref ref;
  const StateAdminController(this.ref);

  void _bump() => ref.read(dataRevisionProvider.notifier).bump();

  // ---------------- Crop / MSP master data ----------------

  Future<OpResult> updateMsp(String cropId, double newMsp) async {
    final repo = ref.read(cropRepositoryProvider);
    final crop = await repo.getById(cropId);
    if (crop == null) return const OpResult(false, 'Crop not found.');
    await repo.save(crop.copyWith(msp: newMsp));
    _bump();
    return const OpResult(true, 'MSP updated.');
  }

  Future<OpResult> setCropActive(String cropId, bool isActive) async {
    final repo = ref.read(cropRepositoryProvider);
    final crop = await repo.getById(cropId);
    if (crop == null) return const OpResult(false, 'Crop not found.');
    await repo.save(crop.copyWith(isActive: isActive));
    _bump();
    return const OpResult(true, 'Crop updated.');
  }

  Future<OpResult> addCrop(Crop crop) async {
    await ref.read(cropRepositoryProvider).save(crop);
    _bump();
    return const OpResult(true, 'Crop added.');
  }

  // ---------------- District Admin account management ----------------

  Future<OpResult> createDistrictAdmin({
    required String name,
    required String employeeId,
    required String district,
  }) async {
    final repo = ref.read(adminRepositoryProvider);
    if (await repo.findByEmployeeId(employeeId) != null) {
      return const OpResult(false, 'Employee ID already in use.');
    }
    final tempPassword = 'Agv${100000 + Random().nextInt(900000)}';
    await repo.save(
      AdminUser(
        id: 'admin-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        role: UserRole.districtAdmin,
        employeeId: employeeId,
        passwordHash: tempPassword,
        district: district,
      ),
    );
    _bump();
    return OpResult(true, 'District Admin created. Temporary password: $tempPassword');
  }

  Future<OpResult> deactivateAdmin(String adminId) async {
    final repo = ref.read(adminRepositoryProvider);
    final admin = await repo.getById(adminId);
    if (admin == null) return const OpResult(false, 'Admin not found.');
    await repo.save(
      admin.copyWith(lockedUntil: DateTime.now().add(const Duration(days: 3650))),
    );
    _bump();
    return const OpResult(true, 'Account deactivated.');
  }

  Future<OpResult> resetAdminPassword(String adminId) async {
    final repo = ref.read(adminRepositoryProvider);
    final admin = await repo.getById(adminId);
    if (admin == null) return const OpResult(false, 'Admin not found.');
    final tempPassword = 'Agv${100000 + Random().nextInt(900000)}';
    await repo.save(
      admin.copyWith(passwordHash: tempPassword, loginAttempts: 0, clearLock: true),
    );
    _bump();
    return OpResult(true, 'Temporary password: $tempPassword');
  }

  // ---------------- Broadcasts ----------------

  Future<OpResult> createBroadcast({
    required String title,
    required String message,
    required String createdBy,
    String? targetDistrict,
    String? targetCrop,
    Map<String, String> localizedMessage = const {},
  }) async {
    final broadcastRepo = ref.read(broadcastRepositoryProvider);
    final broadcast = Broadcast(
      id: 'broadcast-${DateTime.now().microsecondsSinceEpoch}',
      title: title,
      message: message,
      targetDistrict: targetDistrict,
      targetCrop: targetCrop,
      createdBy: createdBy,
      createdAt: DateTime.now(),
      localizedMessage: localizedMessage,
    );
    await broadcastRepo.save(broadcast);

    // Deliver as a notification to every farmer, or those matching the
    // district/crop filter, in their own language (README §5.4).
    final farmers = await ref.read(farmerRepositoryProvider).getAll();
    final notificationRepo = ref.read(notificationRepositoryProvider);
    final targeted = farmers.where(
      (f) =>
          (targetDistrict == null || f.district == targetDistrict) &&
          (targetCrop == null || f.registeredCropIds.contains(targetCrop)),
    );
    for (final farmer in targeted) {
      await notificationRepo.save(
        NotificationItem(
          id: 'ntf-${DateTime.now().microsecondsSinceEpoch}-${farmer.id}',
          userId: farmer.id,
          title: title,
          message: broadcast.messageFor(farmer.preferredLanguage),
          timestamp: DateTime.now(),
          type: NotificationType.broadcast,
          language: farmer.preferredLanguage,
        ),
      );
    }
    _bump();
    return const OpResult(true, 'Broadcast sent.');
  }
}
