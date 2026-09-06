import '../models/centre.dart';
import '../models/crop.dart';
import '../models/district.dart';
import '../models/slot.dart';
import 'repository.dart';

abstract class CropRepository extends Repository<Crop> {
  Future<List<Crop>> activeCrops();
}

abstract class CentreRepository extends Repository<ProcurementCentre> {
  Future<List<ProcurementCentre>> forDistrict(String district);
}

abstract class SlotRepository extends Repository<Slot> {
  Future<List<Slot>> forCentre(String centreId);
  Future<List<Slot>> forCentreAndDate(String centreId, DateTime date);
}

abstract class DistrictRepository extends Repository<District> {}
