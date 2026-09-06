import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enums.dart';
import '../models/grievance.dart';
import '../models/notification.dart';
import '../repositories/repository_providers.dart';
import '../repositories/support_repositories.dart';
import 'data_revision.dart';
import 'op_result.dart';

final grievancesForFarmerProvider =
    FutureProvider.family<List<Grievance>, String>((ref, farmerId) {
      ref.watch(dataRevisionProvider);
      return ref.read(grievanceRepositoryProvider).forFarmer(farmerId);
    });

final grievancesByEscalationProvider =
    FutureProvider.family<List<Grievance>, EscalationLevel>((ref, level) {
      ref.watch(dataRevisionProvider);
      return ref.read(grievanceRepositoryProvider).byEscalationLevel(level);
    });

final allGrievancesProvider = FutureProvider<List<Grievance>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.read(grievanceRepositoryProvider).getAll();
});

final grievanceControllerProvider = Provider<GrievanceController>(
  (ref) => GrievanceController(ref),
);

/// Farmer raise/track + Centre/District/State respond/escalate/resolve
/// (README §5.1 "Support", §5.2/§5.3/§5.4 grievance handling).
class GrievanceController {
  final Ref ref;
  const GrievanceController(this.ref);

  GrievanceRepository get _repo => ref.read(grievanceRepositoryProvider);

  void _bump() => ref.read(dataRevisionProvider.notifier).bump();

  Future<void> _notify(String userId, String title, String message) =>
      ref.read(notificationRepositoryProvider).save(
        NotificationItem(
          id: 'ntf-${DateTime.now().microsecondsSinceEpoch}',
          userId: userId,
          title: title,
          message: message,
          timestamp: DateTime.now(),
          type: NotificationType.grievanceUpdate,
        ),
      );

  Future<OpResult> raiseGrievance({
    required String farmerId,
    String? relatedBookingId,
    required GrievanceCategory category,
    required String description,
    bool isEmergency = false,
  }) async {
    if (description.trim().isEmpty) {
      return const OpResult(false, 'Please describe the issue.');
    }
    final grievance = Grievance(
      id: 'griev-${DateTime.now().microsecondsSinceEpoch}',
      farmerId: farmerId,
      relatedBookingId: relatedBookingId,
      category: category,
      description: description,
      raisedAt: DateTime.now(),
      isEmergency: isEmergency,
    );
    await _repo.save(grievance);
    _bump();
    return OpResult(true, 'Grievance raised. Reference: ${grievance.id}.', id: grievance.id);
  }

  Future<OpResult> escalate(String grievanceId, EscalationLevel toLevel) async {
    final g = await _repo.getById(grievanceId);
    if (g == null) return const OpResult(false, 'Grievance not found.');
    await _repo.save(
      g.copyWith(status: GrievanceStatus.escalated, escalationLevel: toLevel),
    );
    await _notify(
      g.farmerId,
      'Grievance Escalated',
      'Your grievance has been escalated to the ${toLevel.label.toLowerCase()} level.',
    );
    _bump();
    return const OpResult(true, 'Grievance escalated.');
  }

  Future<OpResult> resolve(String grievanceId, String resolutionNote) async {
    final g = await _repo.getById(grievanceId);
    if (g == null) return const OpResult(false, 'Grievance not found.');
    await _repo.save(
      g.copyWith(
        status: GrievanceStatus.resolved,
        resolvedAt: DateTime.now(),
        resolutionNote: resolutionNote,
      ),
    );
    await _notify(
      g.farmerId,
      'Grievance Resolved',
      resolutionNote,
    );
    _bump();
    return const OpResult(true, 'Grievance marked resolved.');
  }

  Future<OpResult> markInReview(String grievanceId) async {
    final g = await _repo.getById(grievanceId);
    if (g == null) return const OpResult(false, 'Grievance not found.');
    await _repo.save(g.copyWith(status: GrievanceStatus.inReview));
    _bump();
    return const OpResult(true, 'Marked in review.');
  }
}
