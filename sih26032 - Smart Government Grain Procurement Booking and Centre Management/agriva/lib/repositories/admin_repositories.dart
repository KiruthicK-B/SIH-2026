import '../models/admin_user.dart';
import '../models/broadcast.dart';
import 'repository.dart';

abstract class AdminRepository extends Repository<AdminUser> {
  Future<AdminUser?> findByEmployeeId(String employeeId);
}

abstract class BroadcastRepository extends Repository<Broadcast> {}
