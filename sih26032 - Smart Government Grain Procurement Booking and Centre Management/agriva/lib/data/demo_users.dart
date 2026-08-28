import '../models/enums.dart';
import '../models/farmer.dart';
import '../models/user.dart';
import 'demo_centres.dart';

const raviFarmerId = 'farmer-ravi';

List<Farmer> buildDemoFarmers() => const [
  Farmer(
    id: raviFarmerId,
    name: 'Ravi Kumar',
    farmerCode: 'FRM-1001',
    village: 'Demo Village',
    distanceKm: 38,
    estimatedTravelMinutes: 60,
    phone: '+91 90000 10001',
  ),
  Farmer(
    id: 'farmer-suresh',
    name: 'Suresh Babu',
    farmerCode: 'FRM-1002',
    village: 'Demo Village',
    distanceKm: 12,
    estimatedTravelMinutes: 20,
    phone: '+91 90000 10002',
  ),
  Farmer(
    id: 'farmer-mohan',
    name: 'Mohan Rao',
    farmerCode: 'FRM-1003',
    village: 'Demo Village',
    distanceKm: 15,
    estimatedTravelMinutes: 25,
    phone: '+91 90000 10003',
  ),
  Farmer(
    id: 'farmer-anil',
    name: 'Anil Kumar',
    farmerCode: 'FRM-1004',
    village: 'Demo Village',
    distanceKm: 20,
    estimatedTravelMinutes: 30,
    phone: '+91 90000 10004',
  ),
  Farmer(
    id: 'farmer-vivek',
    name: 'Vivek Singh',
    farmerCode: 'FRM-1005',
    village: 'Demo Village',
    distanceKm: 25,
    estimatedTravelMinutes: 35,
    phone: '+91 90000 10005',
  ),
  Farmer(
    id: 'farmer-palanikumar',
    name: 'Kumar',
    farmerCode: 'FRM-1006',
    village: 'Demo Village',
    distanceKm: 8,
    estimatedTravelMinutes: 15,
    phone: '+91 90000 10006',
  ),
  Farmer(
    id: 'farmer-selvam',
    name: 'Selvam',
    farmerCode: 'FRM-1007',
    village: 'Demo Village',
    distanceKm: 15,
    estimatedTravelMinutes: 25,
    phone: '+91 90000 10007',
  ),
  Farmer(
    id: 'farmer-arun',
    name: 'Arun',
    farmerCode: 'FRM-1008',
    village: 'Demo Village',
    distanceKm: 40,
    estimatedTravelMinutes: 65,
    phone: '+91 90000 10008',
  ),
];

List<AppUser> buildDemoUsers() => const [
  AppUser(id: raviFarmerId, name: 'Ravi Kumar', role: UserRole.farmer),
  AppUser(
    id: 'user-operator',
    name: 'Suresh Babu',
    role: UserRole.operator,
    centreId: centreAId,
  ),
  AppUser(
    id: 'user-manager',
    name: 'Meena Raj',
    role: UserRole.manager,
    district: 'Demo District',
  ),
  AppUser(id: 'user-admin', name: 'AGRIVA Admin', role: UserRole.admin),
];
