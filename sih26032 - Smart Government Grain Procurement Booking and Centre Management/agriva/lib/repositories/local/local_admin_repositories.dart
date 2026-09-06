import '../../models/admin_user.dart';
import '../../models/broadcast.dart';
import '../admin_repositories.dart';
import 'hive_json_repository.dart';

class LocalAdminRepository extends HiveJsonRepository<AdminUser>
    implements AdminRepository {
  LocalAdminRepository()
    : super(
        HiveBootstrap.box('adminUsers'),
        fromJson: AdminUser.fromJson,
        toJson: (a) => a.toJson(),
        idOf: (a) => a.id,
      );

  @override
  Future<AdminUser?> findByEmployeeId(String employeeId) async {
    final all = await getAll();
    for (final a in all) {
      if (a.employeeId.toLowerCase() == employeeId.toLowerCase()) return a;
    }
    return null;
  }
}

class LocalBroadcastRepository extends HiveJsonRepository<Broadcast>
    implements BroadcastRepository {
  LocalBroadcastRepository()
    : super(
        HiveBootstrap.box('broadcasts'),
        fromJson: Broadcast.fromJson,
        toJson: (b) => b.toJson(),
        idOf: (b) => b.id,
      );
}
