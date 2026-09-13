import '../models/enums.dart';
import '../models/queue_entry.dart';
import 'scheduler_service.dart';

/// Pure queue math: position, estimated wait. Mutations happen by returning
/// new [QueueEntry] lists — callers (the app state notifier) apply them.
class QueueService {
  const QueueService();

  static const _scheduler = SchedulerService();

  /// Active (not-yet-completed) entries for a centre, ordered by the queue's
  /// actual management state — this ordering IS the queue: not-skipped
  /// before skipped (an operator "Skip" always drops to the back), priority
  /// before normal within each of those buckets, then manual `queuePosition`
  /// (what reorder up/down swaps), then arrival time as the final tie-break.
  List<QueueEntry> activeQueueForCentre(
    List<QueueEntry> allEntries,
    Set<String> bookingIdsForCentre,
  ) {
    final active = allEntries
        .where(
          (e) =>
              bookingIdsForCentre.contains(e.bookingId) &&
              e.stage != QueueStage.completed &&
              e.stage != QueueStage.exception,
        )
        .toList();
    active.sort((a, b) {
      if (a.skipped != b.skipped) return a.skipped ? 1 : -1;
      if (a.isPriority != b.isPriority) return a.isPriority ? -1 : 1;
      final posCompare = a.queuePosition.compareTo(b.queuePosition);
      if (posCompare != 0) return posCompare;
      return a.enteredAt.compareTo(b.enteredAt);
    });
    return active;
  }

  int calculateQueuePosition(String bookingId, List<QueueEntry> activeQueue) {
    final idx = activeQueue.indexWhere((e) => e.bookingId == bookingId);
    return idx == -1 ? -1 : idx + 1;
  }

  int calculateEstimatedWait({
    required int queuePosition,
    required int activeLanes,
  }) {
    if (queuePosition <= 0) return 0;
    return _scheduler.estimateWaitMinutes(
      queuePosition: queuePosition,
      activeLanes: activeLanes,
    );
  }
}
