import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/booking.dart';
import '../../models/centre.dart';
import '../../models/disruption.dart';
import '../../models/enums.dart';
import '../../models/farmer.dart';
import '../../models/procurement_record.dart';
import '../../models/payment.dart';
import '../../models/reschedule_offer.dart';
import '../../repositories/repository_providers.dart';
import '../../state/data_revision.dart';

/// Every entity scoped to the centres in one district — the shared data
/// source for the District Admin dashboard, centres, and analytics screens.
class DistrictData {
  final List<ProcurementCentre> centres;
  final List<Booking> bookings;
  final List<Disruption> disruptions;
  final List<RescheduleOffer> rescheduleOffers;
  final List<ProcurementRecord> procurementRecords;
  final List<Payment> payments;

  const DistrictData({
    required this.centres,
    required this.bookings,
    required this.disruptions,
    required this.rescheduleOffers,
    required this.procurementRecords,
    required this.payments,
  });
}

final districtDataProvider = FutureProvider.family<DistrictData, String>((
  ref,
  district,
) async {
  ref.watch(dataRevisionProvider);
  final centres = await ref.read(centreRepositoryProvider).forDistrict(district);
  final bookingRepo = ref.read(bookingRepositoryProvider);
  final disruptionRepo = ref.read(disruptionRepositoryProvider);
  final procurementRepo = ref.read(procurementRepositoryProvider);
  final paymentRepo = ref.read(paymentRepositoryProvider);
  final offerRepo = ref.read(rescheduleOfferRepositoryProvider);

  final centreIds = centres.map((c) => c.id).toSet();
  final allBookings = await bookingRepo.getAll();
  final bookings = allBookings.where((b) => centreIds.contains(b.centreId)).toList();
  final bookingIds = bookings.map((b) => b.id).toSet();

  final allDisruptions = await disruptionRepo.getAll();
  final disruptions = allDisruptions.where((d) => centreIds.contains(d.centreId)).toList();

  final allProcurements = await procurementRepo.getAll();
  final procurementRecords =
      allProcurements.where((p) => bookingIds.contains(p.bookingId)).toList();

  final allPayments = await paymentRepo.getAll();
  final payments =
      allPayments.where((p) => bookingIds.contains(p.bookingId)).toList();

  final allOffers = await offerRepo.getAll();
  final rescheduleOffers =
      allOffers.where((o) => bookingIds.contains(o.bookingId)).toList();

  return DistrictData(
    centres: centres,
    bookings: bookings,
    disruptions: disruptions,
    rescheduleOffers: rescheduleOffers,
    procurementRecords: procurementRecords,
    payments: payments,
  );
});

class CentreFarmerStats {
  final ProcurementCentre centre;
  final int totalRegistered;
  final int approved;
  final int pending;
  final int escalated;
  final int pendingOverdue; // pending > 48 hours

  const CentreFarmerStats({
    required this.centre,
    required this.totalRegistered,
    required this.approved,
    required this.pending,
    required this.escalated,
    required this.pendingOverdue,
  });
}

/// Real-time breakdown of registered farmers in each procurement centre of this district.
final centreFarmerStatsProvider =
    FutureProvider.family<List<CentreFarmerStats>, String>((ref, district) async {
  ref.watch(dataRevisionProvider);
  final centres = await ref.read(centreRepositoryProvider).forDistrict(district);
  final allFarmers = await ref.read(farmerRepositoryProvider).getAll();
  final now = DateTime.now();

  return centres.map((c) {
    final cFarmers = allFarmers.where((f) => f.assignedCentreId == c.id).toList();
    final approved = cFarmers
        .where((f) => f.verificationStatus == FarmerVerificationStatus.approved)
        .length;
    final pending = cFarmers
        .where((f) => f.verificationStatus == FarmerVerificationStatus.pendingApproval)
        .length;
    final escalated = cFarmers
        .where((f) => f.verificationStatus == FarmerVerificationStatus.escalatedToDistrict)
        .length;
    final overdue = cFarmers.where((f) {
      if (f.verificationStatus != FarmerVerificationStatus.pendingApproval) return false;
      final cAt = f.createdAt;
      return cAt != null && now.difference(cAt).inHours > 48;
    }).length;

    return CentreFarmerStats(
      centre: c,
      totalRegistered: cFarmers.length,
      approved: approved,
      pending: pending,
      escalated: escalated,
      pendingOverdue: overdue,
    );
  }).toList();
});

/// Farmers registered in this district whose identity documents need verification
/// or have been escalated to District Admin.
final pendingFarmerVerificationsProvider =
    FutureProvider.family<List<Farmer>, String>((ref, district) async {
  ref.watch(dataRevisionProvider);
  final farmers = await ref.read(farmerRepositoryProvider).getAll();
  final dLower = district.toLowerCase().replaceAll('district-', '').replaceAll('dt-', '').trim();
  return farmers
      .where((f) {
        final fDistrictLower = f.district.toLowerCase().replaceAll('district-', '').replaceAll('dt-', '').trim();
        final matchesDistrict = f.district == district || fDistrictLower == dLower;
        return matchesDistrict &&
            (f.verificationStatus == FarmerVerificationStatus.pendingApproval ||
                f.verificationStatus == FarmerVerificationStatus.escalatedToDistrict);
      })
      .toList()
    ..sort((a, b) => (a.createdAt ?? DateTime(2000)).compareTo(b.createdAt ?? DateTime(2000)));
});
