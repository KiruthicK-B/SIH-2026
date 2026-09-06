import '../models/audit_log.dart';
import '../models/enums.dart';
import '../models/grievance.dart';
import '../models/notification.dart';
import 'repository.dart';

abstract class GrievanceRepository extends Repository<Grievance> {
  Future<List<Grievance>> forFarmer(String farmerId);
  Future<List<Grievance>> byEscalationLevel(EscalationLevel level);
}

abstract class NotificationRepository extends Repository<NotificationItem> {
  Future<List<NotificationItem>> forUser(String userId);
}

abstract class AuditLogRepository extends Repository<AuditLog> {}
