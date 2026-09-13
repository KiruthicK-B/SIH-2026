import 'package:flutter_test/flutter_test.dart';
import 'package:agriva/models/centre.dart';
import 'package:agriva/models/enums.dart';
import 'package:agriva/models/farmer.dart';
import 'package:agriva/models/slot.dart';
import 'package:agriva/services/scheduler_service.dart';

void main() {
  group('SchedulerService', () {
    const scheduler = SchedulerService();

    final testFarmer = Farmer(
      id: 'farmer-1',
      name: 'Ravi Kumar',
      farmerCode: 'FRM-1001',
      phone: '+91 90000 10001',
      district: 'district-nagpur',
      village: 'Demo Village',
      distanceKm: 12.0,
      estimatedTravelMinutes: 25,
      aadhaarNumber: '123456789012',
      bankAccountNumber: '5000012345',
      bankIfsc: 'SBIN0001234',
      registeredCropIds: const ['crop-wheat'],
      isVerified: true,
      createdAt: DateTime(2026, 1, 1),
    );

    const testCentre = ProcurementCentre(
      id: 'centre-nagpur',
      name: 'Nagpur Central Hub',
      code: 'NGP-01',
      district: 'district-nagpur',
      taluk: 'Nagpur Rural',
      latitude: 21.1458,
      longitude: 79.0882,
      contactNumber: '+91 712 234 5678',
      supportedCrops: [
        CentreCropSupport(cropId: 'crop-wheat', season: CropSeason.rabi),
      ],
      dailyCapacityQ: {'crop-wheat': 800},
      status: CentreStatus.open,
      dailyProcessingCapacityQ: 1200,
      storageCapacityQ: 1500,
      currentStorageQ: 300,
      processingLanesTotal: 2,
      processingLanesActive: 2,
      staffNormal: 8,
      staffAvailable: 8,
    );

    test('recommends slots successfully when user tests during evening/night hours', () {
      final date = DateTime(2026, 9, 5);
      // Simulate testing at 11:30 PM (23:30)
      final lateNightNow = DateTime(2026, 9, 5, 23, 30);

      final slots = List.generate(
        8,
        (i) => Slot(
          id: 'slot-$i',
          centreId: 'centre-nagpur',
          cropId: 'crop-wheat',
          start: DateTime(2026, 9, 5, 9 + i),
          end: DateTime(2026, 9, 5, 10 + i),
          maxFarmers: 10,
          totalCapacityQ: 150,
        ),
      );

      final recommendations = scheduler.getRecommendedSlots(
        farmer: testFarmer,
        centre: testCentre,
        date: date,
        expectedQuantityQ: 50,
        slots: slots,
        bookings: const [],
        disruptions: const [],
        now: lateNightNow,
      );

      expect(recommendations, isNotEmpty);
      expect(recommendations.any((r) => r.feasible), isTrue);
      expect(recommendations.any((r) => r.isRecommended), isTrue);
    });

    test('recommends earliest feasible slot with highest capacity margin', () {
      final date = DateTime(2026, 9, 6);
      final morningNow = DateTime(2026, 9, 6, 7, 0);

      final slots = [
        Slot(
          id: 'slot-early',
          centreId: 'centre-nagpur',
          cropId: 'crop-wheat',
          start: DateTime(2026, 9, 6, 9),
          end: DateTime(2026, 9, 6, 10),
          maxFarmers: 10,
          totalCapacityQ: 150,
        ),
        Slot(
          id: 'slot-later',
          centreId: 'centre-nagpur',
          cropId: 'crop-wheat',
          start: DateTime(2026, 9, 6, 14),
          end: DateTime(2026, 9, 6, 15),
          maxFarmers: 10,
          totalCapacityQ: 150,
        ),
      ];

      final recommendations = scheduler.getRecommendedSlots(
        farmer: testFarmer,
        centre: testCentre,
        date: date,
        expectedQuantityQ: 50,
        slots: slots,
        bookings: const [],
        disruptions: const [],
        now: morningNow,
      );

      expect(recommendations.length, 2);
      final recommended = recommendations.firstWhere((r) => r.isRecommended);
      expect(recommended.slot.id, 'slot-early');
    });

    test('marks slot infeasible if centre is closed', () {
      final closedCentre = testCentre.copyWith(status: CentreStatus.closed);
      final date = DateTime(2026, 9, 6);
      final morningNow = DateTime(2026, 9, 6, 7, 0);

      final slots = [
        Slot(
          id: 'slot-1',
          centreId: 'centre-nagpur',
          cropId: 'crop-wheat',
          start: DateTime(2026, 9, 6, 10),
          end: DateTime(2026, 9, 6, 11),
          maxFarmers: 10,
          totalCapacityQ: 150,
        ),
      ];

      final recommendations = scheduler.getRecommendedSlots(
        farmer: testFarmer,
        centre: closedCentre,
        date: date,
        expectedQuantityQ: 50,
        slots: slots,
        bookings: const [],
        disruptions: const [],
        now: morningNow,
      );

      expect(recommendations.first.feasible, isFalse);
      expect(recommendations.first.invalidReason, SlotInvalidReason.centreClosed);
    });
  });
}
