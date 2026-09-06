import '../../models/centre.dart';
import '../../models/crop.dart';
import '../../models/district.dart';
import '../../models/slot.dart';
import '../catalog_repositories.dart';
import 'hive_json_repository.dart';

class LocalCropRepository extends HiveJsonRepository<Crop>
    implements CropRepository {
  LocalCropRepository()
    : super(
        HiveBootstrap.box('crops'),
        fromJson: Crop.fromJson,
        toJson: (c) => c.toJson(),
        idOf: (c) => c.id,
      );

  @override
  Future<List<Crop>> activeCrops() async =>
      (await getAll()).where((c) => c.isActive).toList();
}

class LocalCentreRepository extends HiveJsonRepository<ProcurementCentre>
    implements CentreRepository {
  LocalCentreRepository()
    : super(
        HiveBootstrap.box('centres'),
        fromJson: ProcurementCentre.fromJson,
        toJson: (c) => c.toJson(),
        idOf: (c) => c.id,
      );

  @override
  Future<List<ProcurementCentre>> forDistrict(String district) async {
    final all = await getAll();
    final dLower = district.toLowerCase().replaceAll('district-', '').replaceAll('dt-', '').trim();
    return all.where((c) {
      if (c.district == district) return true;
      final cLower = c.district.toLowerCase().replaceAll('district-', '').replaceAll('dt-', '').trim();
      return cLower == dLower;
    }).toList();
  }
}

class LocalSlotRepository extends HiveJsonRepository<Slot>
    implements SlotRepository {
  LocalSlotRepository()
    : super(
        HiveBootstrap.box('slots'),
        fromJson: Slot.fromJson,
        toJson: (s) => s.toJson(),
        idOf: (s) => s.id,
      );

  @override
  Future<List<Slot>> forCentre(String centreId) async =>
      (await getAll()).where((s) => s.centreId == centreId).toList();

  @override
  Future<List<Slot>> forCentreAndDate(String centreId, DateTime date) async {
    final day = DateTime(date.year, date.month, date.day);
    return (await getAll())
        .where((s) => s.centreId == centreId && s.date == day)
        .toList();
  }
}

class LocalDistrictRepository extends HiveJsonRepository<District>
    implements DistrictRepository {
  LocalDistrictRepository()
    : super(
        HiveBootstrap.box('districts'),
        fromJson: District.fromJson,
        toJson: (d) => d.toJson(),
        idOf: (d) => d.id,
      );
}
