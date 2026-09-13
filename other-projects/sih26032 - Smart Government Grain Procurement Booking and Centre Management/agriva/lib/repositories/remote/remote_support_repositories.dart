import '../../models/audit_log.dart';
import '../../models/enums.dart';
import '../../models/grievance.dart';
import '../../models/notification.dart';
import '../support_repositories.dart';
import 'http_json_repository.dart';

class RemoteGrievanceRepository extends HttpJsonRepository<Grievance>
    implements GrievanceRepository {
  RemoteGrievanceRepository()
    : super(
        'grievances',
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

class RemoteNotificationRepository extends HttpJsonRepository<NotificationItem>
    implements NotificationRepository {
  RemoteNotificationRepository()
    : super(
        'notifications',
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

class RemoteAuditLogRepository extends HttpJsonRepository<AuditLog>
    implements AuditLogRepository {
  RemoteAuditLogRepository()
    : super(
        'auditLogs',
        fromJson: AuditLog.fromJson,
        toJson: (a) => a.toJson(),
        idOf: (a) => a.id,
      );
}
