import '../../models/centre.dart';
import '../../models/crop.dart';
import '../../models/district.dart';
import '../../models/slot.dart';
import '../catalog_repositories.dart';
import 'http_json_repository.dart';

class RemoteCropRepository extends HttpJsonRepository<Crop>
    implements CropRepository {
  RemoteCropRepository()
    : super(
        'crops',
        fromJson: Crop.fromJson,
        toJson: (c) => c.toJson(),
        idOf: (c) => c.id,
      );

  @override
  Future<List<Crop>> activeCrops() async =>
      (await getAll()).where((c) => c.isActive).toList();
}

class RemoteCentreRepository extends HttpJsonRepository<ProcurementCentre>
    implements CentreRepository {
  RemoteCentreRepository()
    : super(
        'centres',
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

class RemoteSlotRepository extends HttpJsonRepository<Slot>
    implements SlotRepository {
  RemoteSlotRepository()
    : super(
        'slots',
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

class RemoteDistrictRepository extends HttpJsonRepository<District>
    implements DistrictRepository {
  RemoteDistrictRepository()
    : super(
        'districts',
        fromJson: District.fromJson,
        toJson: (d) => d.toJson(),
        idOf: (d) => d.id,
      );
}
