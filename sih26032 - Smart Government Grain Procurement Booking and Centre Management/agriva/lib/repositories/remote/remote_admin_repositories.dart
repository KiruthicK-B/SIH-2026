import '../../models/admin_user.dart';
import '../../models/broadcast.dart';
import '../admin_repositories.dart';
import 'http_json_repository.dart';

class RemoteAdminRepository extends HttpJsonRepository<AdminUser>
    implements AdminRepository {
  RemoteAdminRepository()
    : super(
        'adminUsers',
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

class RemoteBroadcastRepository extends HttpJsonRepository<Broadcast>
    implements BroadcastRepository {
  RemoteBroadcastRepository()
    : super(
        'broadcasts',
        fromJson: Broadcast.fromJson,
        toJson: (b) => b.toJson(),
        idOf: (b) => b.id,
      );
}
