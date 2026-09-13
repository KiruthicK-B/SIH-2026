import '../../models/audit_log.dart';
import '../../models/enums.dart';
import '../../models/grievance.dart';
import '../../models/notification.dart';
import '../support_repositories.dart';
import 'hive_json_repository.dart';

class LocalGrievanceRepository extends HiveJsonRepository<Grievance>
    implements GrievanceRepository {
  LocalGrievanceRepository()
    : super(
        HiveBootstrap.box('grievances'),
        fromJson: Grievance.fromJson,
        toJson: (g) => g.toJson(),
        idOf: (g) => g.id,
      );

  @override
  Future<List<Grievance>> forFarmer(String farmerId) async =>
      (await getAll()).where((g) => g.farmerId == farmerId).toList();

  @override
  Future<List<Grievance>> byEscalationLevel(EscalationLevel level) async =>
      (await getAll()).where((g) => g.escalationLevel == level).toList();
}

class LocalNotificationRepository extends HiveJsonRepository<NotificationItem>
    implements NotificationRepository {
  LocalNotificationRepository()
    : super(
        HiveBootstrap.box('notifications'),
        fromJson: NotificationItem.fromJson,
        toJson: (n) => n.toJson(),
        idOf: (n) => n.id,
      );

  @override
  Future<List<NotificationItem>> forUser(String userId) async =>
      (await getAll())
          .where((n) => n.userId == userId || n.userId == 'all')
          .toList();
}

class LocalAuditLogRepository extends HiveJsonRepository<AuditLog>
    implements AuditLogRepository {
  LocalAuditLogRepository()
    : super(
        HiveBootstrap.box('auditLogs'),
        fromJson: AuditLog.fromJson,
        toJson: (a) => a.toJson(),
        idOf: (a) => a.id,
      );
}
