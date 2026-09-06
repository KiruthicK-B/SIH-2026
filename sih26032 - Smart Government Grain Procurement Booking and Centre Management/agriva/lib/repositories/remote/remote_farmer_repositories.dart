import '../../models/farmer.dart';
import '../../models/land_record.dart';
import '../farmer_repositories.dart';
import 'http_json_repository.dart';

class RemoteFarmerRepository extends HttpJsonRepository<Farmer>
    implements FarmerRepository {
  RemoteFarmerRepository()
    : super(
        'farmers',
        fromJson: Farmer.fromJson,
        toJson: (f) => f.toJson(),
        idOf: (f) => f.id,
      );

  @override
  Future<Farmer?> findByPhone(String phone) async {
    final target = Farmer.normalizePhone(phone);
    final all = await getAll();
    for (final f in all) {
      if (Farmer.normalizePhone(f.phone) == target) return f;
    }
    return null;
  }

  @override
  Future<bool> existsByPhoneAndAadhaar(String phone, String aadhaar) async {
    final targetPhone = Farmer.normalizePhone(phone);
    final all = await getAll();
    return all.any(
      (f) =>
          Farmer.normalizePhone(f.phone) == targetPhone &&
          f.aadhaarNumber == aadhaar,
    );
  }
}

class RemoteLandRecordRepository extends HttpJsonRepository<LandRecord>
    implements LandRecordRepository {
  RemoteLandRecordRepository()
    : super(
        'landRecords',
        fromJson: LandRecord.fromJson,
        toJson: (l) => l.toJson(),
        idOf: (l) => l.id,
      );

  @override
  Future<List<LandRecord>> forFarmer(String farmerId) async =>
      (await getAll()).where((l) => l.farmerId == farmerId).toList();
}
