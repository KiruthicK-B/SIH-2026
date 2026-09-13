import '../models/farmer.dart';
import '../models/land_record.dart';
import 'repository.dart';

abstract class FarmerRepository extends Repository<Farmer> {
  Future<Farmer?> findByPhone(String phone);

  /// README §5.1 duplicate-registration guard: same phone+Aadhaar combo.
  Future<bool> existsByPhoneAndAadhaar(String phone, String aadhaar);
}

abstract class LandRecordRepository extends Repository<LandRecord> {
  Future<List<LandRecord>> forFarmer(String farmerId);
}
