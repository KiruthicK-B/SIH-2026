import '../models/enums.dart';
import '../models/queue_entry.dart';
import 'scheduler_service.dart';

/// Pure queue math: position, estimated wait. Mutations happen by returning
/// new [QueueEntry] lists — callers (the app state notifier) apply them.
class QueueService {
  const QueueService();

  static const _scheduler = SchedulerService();

  /// Active (not-yet-completed) entries for a centre, ordered by stage
  /// priority then arrival time — this ordering IS the queue.
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
    active.sort((a, b) => a.enteredAt.compareTo(b.enteredAt));
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
