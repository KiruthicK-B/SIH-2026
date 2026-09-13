import '../models/admin_user.dart';
import '../models/booking.dart';
import '../models/centre.dart';
import '../models/crop.dart';
import '../models/disruption.dart';
import '../models/district.dart';
import '../models/enums.dart';
import '../models/farmer.dart';
import '../models/land_record.dart';
import '../models/notification.dart';
import '../models/payment.dart';
import '../models/procurement_record.dart';
import '../models/queue_entry.dart';
import '../models/slot.dart';
import '../repositories/admin_repositories.dart';
import '../repositories/booking_repositories.dart';
import '../repositories/catalog_repositories.dart';
import '../repositories/farmer_repositories.dart';
import '../repositories/support_repositories.dart';

// 5 Tamil Nadu Districts
const districtErodeId = 'district-erode';
const districtTiruppurId = 'district-tiruppur';
const districtThanjavurId = 'district-thanjavur';
const districtTiruvarurId = 'district-tiruvarur';
const districtMaduraiId = 'district-madurai';

// 13 Procurement Centres
const centreErode01Id = 'centre-erode-01';
const centreErode02Id = 'centre-erode-02';
const centreErode03Id = 'centre-erode-03';
const centreTiruppur01Id = 'centre-tiruppur-01';
const centreTiruppur02Id = 'centre-tiruppur-02';
const centreTiruppur03Id = 'centre-tiruppur-03';
const centreThanjavur01Id = 'centre-thanjavur-01';
const centreThanjavur02Id = 'centre-thanjavur-02';
const centreThanjavur03Id = 'centre-thanjavur-03';
const centreTiruvarur01Id = 'centre-tiruvarur-01';
const centreTiruvarur02Id = 'centre-tiruvarur-02';
const centreMadurai01Id = 'centre-madurai-01';
const centreMadurai02Id = 'centre-madurai-02';

// 9 MSP Crops
const cropPaddyCommonId = 'crop-paddy-common';
const cropPaddyGradeAId = 'crop-paddy-grade-a';
const cropMaizeId = 'crop-maize';
const cropRagiId = 'crop-ragi';
const cropJowarId = 'crop-jowar';
const cropBajraId = 'crop-bajra';
const cropUradId = 'crop-urad';
const cropMoongId = 'crop-moong';
const cropCottonId = 'crop-cotton';

// Primary Demo Farmers
const muruganFarmerId = 'farmer-murugan';
const senthilFarmerId = 'farmer-senthil';
const palanisamyFarmerId = 'farmer-palanisamy';
const thangavelFarmerId = 'farmer-thangavel';
const selvanathanFarmerId = 'farmer-selvanathan';

class SeedDataService {
  final FarmerRepository farmerRepo;
  final LandRecordRepository landRecordRepo;
  final CropRepository cropRepo;
  final CentreRepository centreRepo;
  final SlotRepository slotRepo;
  final DistrictRepository districtRepo;
  final BookingRepository bookingRepo;
  final QueueRepository queueRepo;
  final ProcurementRepository procurementRepo;
  final PaymentRepository paymentRepo;
  final DisruptionRepository disruptionRepo;
  final AdminRepository adminRepo;
  final BroadcastRepository broadcastRepo;
  final GrievanceRepository grievanceRepo;
  final NotificationRepository notificationRepo;

  const SeedDataService({
    required this.farmerRepo,
    required this.landRecordRepo,
    required this.cropRepo,
    required this.centreRepo,
    required this.slotRepo,
    required this.districtRepo,
    required this.bookingRepo,
    required this.queueRepo,
    required this.procurementRepo,
    required this.paymentRepo,
    required this.disruptionRepo,
    required this.adminRepo,
    required this.broadcastRepo,
    required this.grievanceRepo,
    required this.notificationRepo,
  });

  static const _centreCropSchedule = [
    (centreErode01Id, cropPaddyCommonId),
    (centreErode02Id, cropMaizeId),
    (centreErode03Id, cropRagiId),
    (centreTiruppur01Id, cropCottonId),
    (centreTiruppur02Id, cropMaizeId),
    (centreTiruppur03Id, cropBajraId),
    (centreThanjavur01Id, cropPaddyGradeAId),
    (centreThanjavur02Id, cropPaddyCommonId),
    (centreThanjavur03Id, cropUradId),
    (centreTiruvarur01Id, cropPaddyCommonId),
    (centreTiruvarur02Id, cropPaddyGradeAId),
    (centreMadurai01Id, cropPaddyCommonId),
    (centreMadurai02Id, cropJowarId),
  ];

  static const _slotWindowDays = 15;

  Future<void> seedIfEmpty() async {
    final districts = await districtRepo.getAll();
    final dtAdmin = await adminRepo.findByEmployeeId('DT-Erode');
    final opAdmin = await adminRepo.findByEmployeeId('OP-Erode-01');
    final stAdmin = await adminRepo.findByEmployeeId('ST-Admin');
    final allAreTN = districts.isNotEmpty && districts.every((d) => d.stateCode == 'TN');
    final hasAll5Districts = districts.length == 5 &&
        districts.any((d) => d.id == districtErodeId) &&
        districts.any((d) => d.id == districtTiruppurId) &&
        districts.any((d) => d.id == districtThanjavurId) &&
        districts.any((d) => d.id == districtTiruvarurId) &&
        districts.any((d) => d.id == districtMaduraiId);

    if (allAreTN && hasAll5Districts && dtAdmin != null && opAdmin != null && stAdmin != null) {
      return;
    }

    // Clear old state completely and perform a fresh seed
    await _clearAll();
    await _seed(DateTime.now());
  }

  Future<void> _clearAll() async {
    // Truly clear Hive boxes
    await districtRepo.clear();
    await cropRepo.clear();
    await centreRepo.clear();
    await slotRepo.clear();
    await farmerRepo.clear();
    await landRecordRepo.clear();
    await adminRepo.clear();
    await bookingRepo.clear();
    await queueRepo.clear();
    await procurementRepo.clear();
    await paymentRepo.clear();
    await disruptionRepo.clear();
    await broadcastRepo.clear();
    await grievanceRepo.clear();
    await notificationRepo.clear();
  }

  Future<void> ensureUpcomingSlots({DateTime? now}) async {
    final today = _dayOf(now ?? DateTime.now());
    final existing = await slotRepo.getAll();
    final existingDayKeys = existing
        .map((s) => '${s.centreId}|${s.date.toIso8601String()}')
        .toSet();

    final newSlots = <Slot>[];
    for (var dayOffset = 0; dayOffset < _slotWindowDays; dayOffset++) {
      final slotDay = today.add(Duration(days: dayOffset));
      for (final (cId, cCrop) in _centreCropSchedule) {
        final key = '$cId|${slotDay.toIso8601String()}';
        if (existingDayKeys.contains(key)) continue;
        newSlots.addAll(_hourlySlots(
          centreId: cId,
          cropId: cCrop,
          day: slotDay,
          startHour: 8,
          endHour: 17,
          maxFarmers: 8,
          totalCapacityQ: 160,
          baselineFarmersByHour: const [1, 2, 2, 1, 1, 2, 1, 1, 1],
          baselineQuantityByHour: const [15, 25, 20, 10, 15, 20, 10, 10, 10],
        ));
      }
    }
    if (newSlots.isNotEmpty) await slotRepo.saveMany(newSlots);
  }

  static DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime _at(DateTime day, int hour, [int minute = 0]) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  Future<void> _seed(DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);

    // ---------------- 1. 5 Tamil Nadu Districts ----------------
    await districtRepo.saveMany(const [
      District(id: districtErodeId, name: 'Erode', stateCode: 'TN'),
      District(id: districtTiruppurId, name: 'Tiruppur', stateCode: 'TN'),
      District(id: districtThanjavurId, name: 'Thanjavur', stateCode: 'TN'),
      District(id: districtTiruvarurId, name: 'Tiruvarur', stateCode: 'TN'),
      District(id: districtMaduraiId, name: 'Madurai', stateCode: 'TN'),
    ]);

    // ---------------- 2. 9 MSP Crops (Tamil Nadu Focus) ----------------
    await cropRepo.saveMany(const [
      Crop(
        id: cropPaddyCommonId,
        name: 'Paddy (Common)',
        localNames: {
          'ta': 'நெல் (சாதாரண)',
          'en': 'Paddy (Common)',
          'hi': 'धान (सामान्य)',
        },
        msp: 2300,
        season: CropSeason.kharif,
        qualityParameters: [
          QualityParameter(name: 'Moisture', minAcceptable: 0, maxAcceptable: 17),
          QualityParameter(name: 'Foreign Matter', minAcceptable: 0, maxAcceptable: 2),
        ],
      ),
      Crop(
        id: cropPaddyGradeAId,
        name: 'Paddy (Grade A)',
        localNames: {
          'ta': 'நெல் (கிரேடு ஏ)',
          'en': 'Paddy (Grade A)',
          'hi': 'धान (ग्रेड ए)',
        },
        msp: 2320,
        season: CropSeason.kharif,
        qualityParameters: [
          QualityParameter(name: 'Moisture', minAcceptable: 0, maxAcceptable: 17),
          QualityParameter(name: 'Foreign Matter', minAcceptable: 0, maxAcceptable: 1.5),
        ],
      ),
      Crop(
        id: cropMaizeId,
        name: 'Maize (Makka Cholam)',
        localNames: {
          'ta': 'மக்காச்சோளம்',
          'en': 'Maize',
          'hi': 'मक्का',
        },
        msp: 2090,
        season: CropSeason.kharif,
        qualityParameters: [
          QualityParameter(name: 'Moisture', minAcceptable: 0, maxAcceptable: 14),
        ],
      ),
      Crop(
        id: cropRagiId,
        name: 'Ragi (Finger Millet / Kelvaragu)',
        localNames: {
          'ta': 'கேழ்வரகு / ராகி',
          'en': 'Ragi',
          'hi': 'रागी',
        },
        msp: 4290,
        season: CropSeason.kharif,
        qualityParameters: [
          QualityParameter(name: 'Moisture', minAcceptable: 0, maxAcceptable: 12),
        ],
      ),
      Crop(
        id: cropJowarId,
        name: 'Jowar / Sorghum (Cholam)',
        localNames: {
          'ta': 'சோளம்',
          'en': 'Jowar (Sorghum)',
          'hi': 'ज्वार',
        },
        msp: 3371,
        season: CropSeason.kharif,
        qualityParameters: [
          QualityParameter(name: 'Moisture', minAcceptable: 0, maxAcceptable: 12),
        ],
      ),
      Crop(
        id: cropBajraId,
        name: 'Bajra / Pearl Millet (Kambu)',
        localNames: {
          'ta': 'கம்பு',
          'en': 'Bajra (Pearl Millet)',
          'hi': 'बाजरा',
        },
        msp: 2625,
        season: CropSeason.kharif,
        qualityParameters: [
          QualityParameter(name: 'Moisture', minAcceptable: 0, maxAcceptable: 12),
        ],
      ),
      Crop(
        id: cropUradId,
        name: 'Black Gram / Urad (Ulunthu)',
        localNames: {
          'ta': 'உளுந்து',
          'en': 'Black Gram (Urad)',
          'hi': 'उड़द',
        },
        msp: 7400,
        season: CropSeason.rabi,
        qualityParameters: [
          QualityParameter(name: 'Moisture', minAcceptable: 0, maxAcceptable: 12),
        ],
      ),
      Crop(
        id: cropMoongId,
        name: 'Green Gram / Moong (Pasi Payiru)',
        localNames: {
          'ta': 'பாசிப்பயறு',
          'en': 'Green Gram (Moong)',
          'hi': 'मूंग',
        },
        msp: 8682,
        season: CropSeason.kharif,
        qualityParameters: [
          QualityParameter(name: 'Moisture', minAcceptable: 0, maxAcceptable: 12),
        ],
      ),
      Crop(
        id: cropCottonId,
        name: 'Cotton (Medium Staple)',
        localNames: {
          'ta': 'பருத்தி',
          'en': 'Cotton',
          'hi': 'कपास',
        },
        msp: 7121,
        season: CropSeason.kharif,
        qualityParameters: [
          QualityParameter(name: 'Moisture', minAcceptable: 0, maxAcceptable: 12),
        ],
      ),
    ]);

    // ---------------- 3. 13 Procurement Centres across 5 TN Districts ----------------
    await centreRepo.saveMany([
      // Erode District (3 Centres)
      const ProcurementCentre(
        id: centreErode01Id,
        name: 'Erode Regulated Market Hub',
        code: 'OP-Erode-01',
        district: districtErodeId,
        taluk: 'Erode Rural',
        latitude: 11.3410,
        longitude: 77.7172,
        contactNumber: '+91 424 225 1101',
        supportedCrops: [
          CentreCropSupport(cropId: cropPaddyCommonId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropPaddyGradeAId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropRagiId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropMaizeId, season: CropSeason.kharif),
        ],
        dailyCapacityQ: {
          cropPaddyCommonId: 1000,
          cropPaddyGradeAId: 800,
          cropRagiId: 400,
          cropMaizeId: 500,
        },
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 1500,
        storageCapacityQ: 2000,
        currentStorageQ: 750,
        processingLanesTotal: 3,
        processingLanesActive: 3,
        staffNormal: 14,
        staffAvailable: 14,
      ),
      const ProcurementCentre(
        id: centreErode02Id,
        name: 'Perundurai Grain Mandi',
        code: 'OP-Erode-02',
        district: districtErodeId,
        taluk: 'Perundurai',
        latitude: 11.2750,
        longitude: 77.5830,
        contactNumber: '+91 424 225 1102',
        supportedCrops: [
          CentreCropSupport(cropId: cropMaizeId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropRagiId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropPaddyCommonId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropCottonId, season: CropSeason.kharif),
        ],
        dailyCapacityQ: {
          cropMaizeId: 800,
          cropRagiId: 500,
          cropPaddyCommonId: 600,
          cropCottonId: 400,
        },
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 1200,
        storageCapacityQ: 1600,
        currentStorageQ: 610,
        processingLanesTotal: 2,
        processingLanesActive: 2,
        staffNormal: 10,
        staffAvailable: 10,
      ),
      const ProcurementCentre(
        id: centreErode03Id,
        name: 'Gobichettipalayam Procurement Centre',
        code: 'OP-Erode-03',
        district: districtErodeId,
        taluk: 'Gobichettipalayam',
        latitude: 11.4550,
        longitude: 77.4330,
        contactNumber: '+91 424 225 1103',
        supportedCrops: [
          CentreCropSupport(cropId: cropRagiId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropPaddyCommonId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropPaddyGradeAId, season: CropSeason.kharif),
        ],
        dailyCapacityQ: {
          cropRagiId: 600,
          cropPaddyCommonId: 800,
          cropPaddyGradeAId: 600,
        },
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 1000,
        storageCapacityQ: 1400,
        currentStorageQ: 420,
        processingLanesTotal: 2,
        processingLanesActive: 2,
        staffNormal: 8,
        staffAvailable: 8,
      ),

      // Tiruppur District (3 Centres)
      const ProcurementCentre(
        id: centreTiruppur01Id,
        name: 'Tiruppur Central APMC Depot',
        code: 'OP-Tiruppur-01',
        district: districtTiruppurId,
        taluk: 'Tiruppur South',
        latitude: 11.1085,
        longitude: 77.3411,
        contactNumber: '+91 421 224 2201',
        supportedCrops: [
          CentreCropSupport(cropId: cropCottonId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropMaizeId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropBajraId, season: CropSeason.kharif),
        ],
        dailyCapacityQ: {cropCottonId: 900, cropMaizeId: 600, cropBajraId: 400},
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 1400,
        storageCapacityQ: 1800,
        currentStorageQ: 810,
        processingLanesTotal: 3,
        processingLanesActive: 3,
        staffNormal: 12,
        staffAvailable: 12,
      ),
      const ProcurementCentre(
        id: centreTiruppur02Id,
        name: 'Dharapuram Grain Centre',
        code: 'OP-Tiruppur-02',
        district: districtTiruppurId,
        taluk: 'Dharapuram',
        latitude: 10.7300,
        longitude: 77.5200,
        contactNumber: '+91 421 224 2202',
        supportedCrops: [
          CentreCropSupport(cropId: cropMaizeId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropJowarId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropBajraId, season: CropSeason.kharif),
        ],
        dailyCapacityQ: {cropMaizeId: 700, cropJowarId: 500, cropBajraId: 400},
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 1100,
        storageCapacityQ: 1350,
        currentStorageQ: 530,
        processingLanesTotal: 2,
        processingLanesActive: 2,
        staffNormal: 9,
        staffAvailable: 9,
      ),
      const ProcurementCentre(
        id: centreTiruppur03Id,
        name: 'Kangeyam Agricultural Mandi',
        code: 'OP-Tiruppur-03',
        district: districtTiruppurId,
        taluk: 'Kangeyam',
        latitude: 11.0000,
        longitude: 77.5600,
        contactNumber: '+91 421 224 2203',
        supportedCrops: [
          CentreCropSupport(cropId: cropBajraId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropUradId, season: CropSeason.rabi),
          CentreCropSupport(cropId: cropCottonId, season: CropSeason.kharif),
        ],
        dailyCapacityQ: {cropBajraId: 600, cropUradId: 400, cropCottonId: 500},
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 950,
        storageCapacityQ: 1200,
        currentStorageQ: 390,
        processingLanesTotal: 2,
        processingLanesActive: 2,
        staffNormal: 8,
        staffAvailable: 8,
      ),

      // Thanjavur District (3 Centres)
      const ProcurementCentre(
        id: centreThanjavur01Id,
        name: 'Thanjavur Direct Purchase Centre (DPC) Hub',
        code: 'OP-Thanjavur-01',
        district: districtThanjavurId,
        taluk: 'Thanjavur Central',
        latitude: 10.7870,
        longitude: 79.1378,
        contactNumber: '+91 4362 230 3301',
        supportedCrops: [
          CentreCropSupport(cropId: cropPaddyCommonId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropPaddyGradeAId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropUradId, season: CropSeason.rabi),
        ],
        dailyCapacityQ: {
          cropPaddyCommonId: 1500,
          cropPaddyGradeAId: 1200,
          cropUradId: 500,
        },
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 2000,
        storageCapacityQ: 2500,
        currentStorageQ: 980,
        processingLanesTotal: 4,
        processingLanesActive: 4,
        staffNormal: 18,
        staffAvailable: 18,
      ),
      const ProcurementCentre(
        id: centreThanjavur02Id,
        name: 'Kumbakonam Modern Rice Procurement Centre',
        code: 'OP-Thanjavur-02',
        district: districtThanjavurId,
        taluk: 'Kumbakonam',
        latitude: 10.9601,
        longitude: 79.3845,
        contactNumber: '+91 4362 230 3302',
        supportedCrops: [
          CentreCropSupport(cropId: cropPaddyCommonId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropPaddyGradeAId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropMoongId, season: CropSeason.kharif),
        ],
        dailyCapacityQ: {
          cropPaddyCommonId: 1200,
          cropPaddyGradeAId: 1000,
          cropMoongId: 400,
        },
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 1600,
        storageCapacityQ: 1900,
        currentStorageQ: 720,
        processingLanesTotal: 3,
        processingLanesActive: 3,
        staffNormal: 14,
        staffAvailable: 14,
      ),
      const ProcurementCentre(
        id: centreThanjavur03Id,
        name: 'Pattukkottai Grain Depot',
        code: 'OP-Thanjavur-03',
        district: districtThanjavurId,
        taluk: 'Pattukkottai',
        latitude: 10.4300,
        longitude: 79.3200,
        contactNumber: '+91 4362 230 3303',
        supportedCrops: [
          CentreCropSupport(cropId: cropPaddyCommonId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropUradId, season: CropSeason.rabi),
          CentreCropSupport(cropId: cropMoongId, season: CropSeason.kharif),
        ],
        dailyCapacityQ: {
          cropPaddyCommonId: 800,
          cropUradId: 500,
          cropMoongId: 300,
        },
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 1100,
        storageCapacityQ: 1400,
        currentStorageQ: 520,
        processingLanesTotal: 2,
        processingLanesActive: 2,
        staffNormal: 10,
        staffAvailable: 10,
      ),

      // Tiruvarur District (2 Centres)
      const ProcurementCentre(
        id: centreTiruvarur01Id,
        name: 'Tiruvarur Central DPC',
        code: 'OP-Tiruvarur-01',
        district: districtTiruvarurId,
        taluk: 'Tiruvarur North',
        latitude: 10.7700,
        longitude: 79.6400,
        contactNumber: '+91 4366 220 4401',
        supportedCrops: [
          CentreCropSupport(cropId: cropPaddyCommonId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropPaddyGradeAId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropUradId, season: CropSeason.rabi),
        ],
        dailyCapacityQ: {
          cropPaddyCommonId: 1400,
          cropPaddyGradeAId: 1100,
          cropUradId: 450,
        },
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 1800,
        storageCapacityQ: 2200,
        currentStorageQ: 890,
        processingLanesTotal: 3,
        processingLanesActive: 3,
        staffNormal: 15,
        staffAvailable: 15,
      ),
      const ProcurementCentre(
        id: centreTiruvarur02Id,
        name: 'Mannargudi Paddy Procurement Centre',
        code: 'OP-Tiruvarur-02',
        district: districtTiruvarurId,
        taluk: 'Mannargudi',
        latitude: 10.6600,
        longitude: 79.4500,
        contactNumber: '+91 4366 220 4402',
        supportedCrops: [
          CentreCropSupport(cropId: cropPaddyCommonId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropPaddyGradeAId, season: CropSeason.kharif),
        ],
        dailyCapacityQ: {
          cropPaddyCommonId: 1100,
          cropPaddyGradeAId: 900,
        },
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 1300,
        storageCapacityQ: 1600,
        currentStorageQ: 640,
        processingLanesTotal: 2,
        processingLanesActive: 2,
        staffNormal: 11,
        staffAvailable: 11,
      ),

      // Madurai District (2 Centres)
      const ProcurementCentre(
        id: centreMadurai01Id,
        name: 'Madurai Integrated Agricultural Hub',
        code: 'OP-Madurai-01',
        district: districtMaduraiId,
        taluk: 'Madurai North',
        latitude: 9.9252,
        longitude: 78.1198,
        contactNumber: '+91 452 250 5501',
        supportedCrops: [
          CentreCropSupport(cropId: cropPaddyCommonId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropJowarId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropBajraId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropUradId, season: CropSeason.rabi),
        ],
        dailyCapacityQ: {
          cropPaddyCommonId: 1000,
          cropJowarId: 600,
          cropBajraId: 500,
          cropUradId: 400,
        },
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 1500,
        storageCapacityQ: 1800,
        currentStorageQ: 710,
        processingLanesTotal: 3,
        processingLanesActive: 3,
        staffNormal: 13,
        staffAvailable: 13,
      ),
      const ProcurementCentre(
        id: centreMadurai02Id,
        name: 'Usilampatti Grain Procurement Mandi',
        code: 'OP-Madurai-02',
        district: districtMaduraiId,
        taluk: 'Usilampatti',
        latitude: 9.9700,
        longitude: 77.7900,
        contactNumber: '+91 452 250 5502',
        supportedCrops: [
          CentreCropSupport(cropId: cropJowarId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropBajraId, season: CropSeason.kharif),
          CentreCropSupport(cropId: cropMaizeId, season: CropSeason.kharif),
        ],
        dailyCapacityQ: {
          cropJowarId: 700,
          cropBajraId: 600,
          cropMaizeId: 500,
        },
        status: CentreStatus.open,
        dailyProcessingCapacityQ: 1100,
        storageCapacityQ: 1300,
        currentStorageQ: 480,
        processingLanesTotal: 2,
        processingLanesActive: 2,
        staffNormal: 9,
        staffAvailable: 9,
      ),
    ]);

    // ---------------- 4. Admin Users (Operators, District Admins, State Admin) ----------------
    // All passwords strictly: agriva123
    await adminRepo.saveMany([
      // 13 Centre Operators: OP-<district>-<number>
      const AdminUser(
        id: 'admin-op-erode-01',
        name: 'K. Shanmugam',
        role: UserRole.centreOperator,
        employeeId: 'OP-Erode-01',
        passwordHash: 'agriva123',
        district: districtErodeId,
        centreId: centreErode01Id,
      ),
      const AdminUser(
        id: 'admin-op-erode-02',
        name: 'M. Ramanathan',
        role: UserRole.centreOperator,
        employeeId: 'OP-Erode-02',
        passwordHash: 'agriva123',
        district: districtErodeId,
        centreId: centreErode02Id,
      ),
      const AdminUser(
        id: 'admin-op-erode-03',
        name: 'V. Natarajan',
        role: UserRole.centreOperator,
        employeeId: 'OP-Erode-03',
        passwordHash: 'agriva123',
        district: districtErodeId,
        centreId: centreErode03Id,
      ),
      const AdminUser(
        id: 'admin-op-tiruppur-01',
        name: 'P. Velusamy',
        role: UserRole.centreOperator,
        employeeId: 'OP-Tiruppur-01',
        passwordHash: 'agriva123',
        district: districtTiruppurId,
        centreId: centreTiruppur01Id,
      ),
      const AdminUser(
        id: 'admin-op-tiruppur-02',
        name: 'C. Karthikeyan',
        role: UserRole.centreOperator,
        employeeId: 'OP-Tiruppur-02',
        passwordHash: 'agriva123',
        district: districtTiruppurId,
        centreId: centreTiruppur02Id,
      ),
      const AdminUser(
        id: 'admin-op-tiruppur-03',
        name: 'T. Ganesan',
        role: UserRole.centreOperator,
        employeeId: 'OP-Tiruppur-03',
        passwordHash: 'agriva123',
        district: districtTiruppurId,
        centreId: centreTiruppur03Id,
      ),
      const AdminUser(
        id: 'admin-op-thanjavur-01',
        name: 'S. Balasubramanian',
        role: UserRole.centreOperator,
        employeeId: 'OP-Thanjavur-01',
        passwordHash: 'agriva123',
        district: districtThanjavurId,
        centreId: centreThanjavur01Id,
      ),
      const AdminUser(
        id: 'admin-op-thanjavur-02',
        name: 'R. Sivakumar',
        role: UserRole.centreOperator,
        employeeId: 'OP-Thanjavur-02',
        passwordHash: 'agriva123',
        district: districtThanjavurId,
        centreId: centreThanjavur02Id,
      ),
      const AdminUser(
        id: 'admin-op-thanjavur-03',
        name: 'N. Dharmalingam',
        role: UserRole.centreOperator,
        employeeId: 'OP-Thanjavur-03',
        passwordHash: 'agriva123',
        district: districtThanjavurId,
        centreId: centreThanjavur03Id,
      ),
      const AdminUser(
        id: 'admin-op-tiruvarur-01',
        name: 'A. Murugesan',
        role: UserRole.centreOperator,
        employeeId: 'OP-Tiruvarur-01',
        passwordHash: 'agriva123',
        district: districtTiruvarurId,
        centreId: centreTiruvarur01Id,
      ),
      const AdminUser(
        id: 'admin-op-tiruvarur-02',
        name: 'K. Rajendran',
        role: UserRole.centreOperator,
        employeeId: 'OP-Tiruvarur-02',
        passwordHash: 'agriva123',
        district: districtTiruvarurId,
        centreId: centreTiruvarur02Id,
      ),
      const AdminUser(
        id: 'admin-op-madurai-01',
        name: 'M. Muthuramalingam',
        role: UserRole.centreOperator,
        employeeId: 'OP-Madurai-01',
        passwordHash: 'agriva123',
        district: districtMaduraiId,
        centreId: centreMadurai01Id,
      ),
      const AdminUser(
        id: 'admin-op-madurai-02',
        name: 'S. Pandian',
        role: UserRole.centreOperator,
        employeeId: 'OP-Madurai-02',
        passwordHash: 'agriva123',
        district: districtMaduraiId,
        centreId: centreMadurai02Id,
      ),

      // 5 District Admins: DT-<district>
      const AdminUser(
        id: 'admin-dt-erode',
        name: 'Thiru. S. Kandasamy, IAS',
        role: UserRole.districtAdmin,
        employeeId: 'DT-Erode',
        passwordHash: 'agriva123',
        district: districtErodeId,
      ),
      const AdminUser(
        id: 'admin-dt-tiruppur',
        name: 'Tmt. R. Jayanthi, IAS',
        role: UserRole.districtAdmin,
        employeeId: 'DT-Tiruppur',
        passwordHash: 'agriva123',
        district: districtTiruppurId,
      ),
      const AdminUser(
        id: 'admin-dt-thanjavur',
        name: 'Thiru. D. Baskaran, IAS',
        role: UserRole.districtAdmin,
        employeeId: 'DT-Thanjavur',
        passwordHash: 'agriva123',
        district: districtThanjavurId,
      ),
      const AdminUser(
        id: 'admin-dt-tiruvarur',
        name: 'Tmt. V. Geetha, IAS',
        role: UserRole.districtAdmin,
        employeeId: 'DT-Tiruvarur',
        passwordHash: 'agriva123',
        district: districtTiruvarurId,
      ),
      const AdminUser(
        id: 'admin-dt-madurai',
        name: 'Thiru. P. Saravanan, IAS',
        role: UserRole.districtAdmin,
        employeeId: 'DT-Madurai',
        passwordHash: 'agriva123',
        district: districtMaduraiId,
      ),

      // State Admin: ST-Admin
      const AdminUser(
        id: 'admin-st-admin',
        name: 'Dr. K. Radhakrishnan, IAS',
        role: UserRole.stateAdmin,
        employeeId: 'ST-Admin',
        passwordHash: 'agriva123',
      ),
    ]);

    // ---------------- 5. Farmers (Diverse Realistic Workflow States) ----------------
    final seededFarmers = [
      // 1. Murugan: Approved, Ready to Book Slot
      Farmer(
        id: muruganFarmerId,
        name: 'R. Murugan',
        farmerCode: 'FRM-TN-1001',
        phone: '9876543210',
        preferredLanguage: 'ta',
        district: districtErodeId,
        taluk: 'Erode Rural',
        village: 'Thindal',
        doorNo: '14/2B',
        street: 'Kovai Main Road',
        pincode: '638012',
        assignedCentreId: centreErode01Id,
        distanceKm: 4.2,
        estimatedTravelMinutes: 12,
        aadhaarNumber: '543210987654',
        bankAccountNumber: '98765432101234',
        bankIfsc: 'SBIN0001420',
        registeredCropIds: const [cropPaddyCommonId, cropPaddyGradeAId, cropRagiId],
        verificationStatus: FarmerVerificationStatus.approved,
        verifiedAt: today.subtract(const Duration(days: 30)),
        verifiedBy: 'OP-Erode-01',
        createdAt: today.subtract(const Duration(days: 45)),
      ),

      // 2. Senthil: Pending Verification (>48 hrs overdue alert demonstration!)
      Farmer(
        id: senthilFarmerId,
        name: 'K. Senthil',
        farmerCode: 'FRM-TN-1002',
        phone: '9876543211',
        preferredLanguage: 'ta',
        district: districtErodeId,
        taluk: 'Erode Rural',
        village: 'Villarasampatti',
        doorNo: '7/1A',
        street: 'Panchayat Office Street',
        pincode: '638012',
        assignedCentreId: centreErode01Id,
        distanceKm: 5.5,
        estimatedTravelMinutes: 16,
        aadhaarNumber: '654321098765',
        bankAccountNumber: '45678901234567',
        bankIfsc: 'IOBA0000312',
        registeredCropIds: const [cropPaddyCommonId, cropRagiId],
        verificationStatus: FarmerVerificationStatus.pendingApproval,
        createdAt: today.subtract(const Duration(days: 3)), // Overdue > 48 hrs!
      ),

      // 3. Palanisamy: Active In Queue (Token T003 at OP-Erode-01)
      Farmer(
        id: palanisamyFarmerId,
        name: 'M. Palanisamy',
        farmerCode: 'FRM-TN-1003',
        phone: '9876543212',
        preferredLanguage: 'ta',
        district: districtErodeId,
        taluk: 'Erode Rural',
        village: 'Kasipalayam',
        doorNo: '23/4',
        street: 'Bhavani Road',
        pincode: '638009',
        assignedCentreId: centreErode01Id,
        distanceKm: 3.1,
        estimatedTravelMinutes: 10,
        aadhaarNumber: '765432109876',
        bankAccountNumber: '32109876543210',
        bankIfsc: 'CANB0001004',
        registeredCropIds: const [cropPaddyCommonId],
        verificationStatus: FarmerVerificationStatus.approved,
        verifiedAt: today.subtract(const Duration(days: 60)),
        verifiedBy: 'OP-Erode-01',
        createdAt: today.subtract(const Duration(days: 75)),
      ),

      // 4. Thangavel: Escalated to District Admin (DT-Erode) for Land Clarification
      Farmer(
        id: thangavelFarmerId,
        name: 'S. Thangavel',
        farmerCode: 'FRM-TN-1004',
        phone: '9876543213',
        preferredLanguage: 'ta',
        district: districtErodeId,
        taluk: 'Erode Rural',
        village: 'Surampatti',
        doorNo: '55/A',
        street: 'Anna Nagar 2nd Street',
        pincode: '638009',
        assignedCentreId: centreErode01Id,
        distanceKm: 4.8,
        estimatedTravelMinutes: 14,
        aadhaarNumber: '876543210987',
        bankAccountNumber: '78901234567890',
        bankIfsc: 'UBIN0542311',
        registeredCropIds: const [cropPaddyCommonId, cropMaizeId],
        verificationStatus: FarmerVerificationStatus.escalatedToDistrict,
        escalationNotes:
            'Patta survey boundary number SY-78/2 overlaps with adjacent canal boundary. Transferred to District Admin for Tahsildar clearance.',
        escalatedAt: today.subtract(const Duration(hours: 18)),
        createdAt: today.subtract(const Duration(days: 2)),
      ),

      // 5. Selvanathan: Completed Weighment & Payment Disbursed (₹1,15,000 DBT)
      Farmer(
        id: selvanathanFarmerId,
        name: 'V. Selvanathan',
        farmerCode: 'FRM-TN-1005',
        phone: '9876543214',
        preferredLanguage: 'ta',
        district: districtErodeId,
        taluk: 'Perundurai',
        village: 'Chennimalai',
        doorNo: '108',
        street: 'Weavers Colony',
        pincode: '638051',
        assignedCentreId: centreErode02Id,
        distanceKm: 6.8,
        estimatedTravelMinutes: 18,
        aadhaarNumber: '987654321098',
        bankAccountNumber: '65432109876543',
        bankIfsc: 'SBIN0002105',
        registeredCropIds: const [cropMaizeId, cropPaddyCommonId],
        verificationStatus: FarmerVerificationStatus.approved,
        verifiedAt: today.subtract(const Duration(days: 90)),
        verifiedBy: 'OP-Erode-02',
        createdAt: today.subtract(const Duration(days: 100)),
      ),

      // 6. Chinnasamy: Tiruppur Farmer (Approved)
      Farmer(
        id: 'farmer-chinnasamy',
        name: 'A. Chinnasamy',
        farmerCode: 'FRM-TN-2001',
        phone: '9876543215',
        preferredLanguage: 'ta',
        district: districtTiruppurId,
        taluk: 'Tiruppur South',
        village: 'Velampalayam',
        doorNo: '34',
        street: 'Cotton Market Lane',
        pincode: '641652',
        assignedCentreId: centreTiruppur01Id,
        distanceKm: 5.2,
        estimatedTravelMinutes: 15,
        aadhaarNumber: '123456789012',
        bankAccountNumber: '11223344556677',
        bankIfsc: 'SBIN0003301',
        registeredCropIds: const [cropCottonId, cropMaizeId],
        verificationStatus: FarmerVerificationStatus.approved,
        verifiedAt: today.subtract(const Duration(days: 40)),
        verifiedBy: 'OP-Tiruppur-01',
        createdAt: today.subtract(const Duration(days: 60)),
      ),

      // 7. Natarajan: Thanjavur Farmer (Approved)
      Farmer(
        id: 'farmer-natarajan',
        name: 'P. Natarajan',
        farmerCode: 'FRM-TN-3001',
        phone: '9876543216',
        preferredLanguage: 'ta',
        district: districtThanjavurId,
        taluk: 'Thanjavur Central',
        village: 'Vallam',
        doorNo: '19',
        street: 'Cauvery River Road',
        pincode: '613403',
        assignedCentreId: centreThanjavur01Id,
        distanceKm: 4.1,
        estimatedTravelMinutes: 11,
        aadhaarNumber: '234567890123',
        bankAccountNumber: '88776655443322',
        bankIfsc: 'IOBA0001140',
        registeredCropIds: const [cropPaddyCommonId, cropPaddyGradeAId],
        verificationStatus: FarmerVerificationStatus.approved,
        verifiedAt: today.subtract(const Duration(days: 50)),
        verifiedBy: 'OP-Thanjavur-01',
        createdAt: today.subtract(const Duration(days: 70)),
      ),
    ];

    await farmerRepo.saveMany(seededFarmers);

    // ---------------- 6. Land Records ----------------
    await landRecordRepo.saveMany([
      for (final f in seededFarmers)
        LandRecord(
          id: 'land-${f.id}',
          farmerId: f.id,
          surveyNumber: 'SY-${f.farmerCode.split('-').last}/1',
          areaInAcres: 3.5,
          village: f.village,
          district: f.district,
          ownershipType: LandOwnershipType.owner,
        ),
    ]);

    // ---------------- 7. Slots (Rolling multi-centre schedule) ----------------
    final slots = <Slot>[];

    for (var dayOffset = 0; dayOffset < _slotWindowDays; dayOffset++) {
      final slotDay = today.add(Duration(days: dayOffset));
      for (final (cId, cCrop) in _centreCropSchedule) {
        slots.addAll(_hourlySlots(
          centreId: cId,
          cropId: cCrop,
          day: slotDay,
          startHour: 8,
          endHour: 17,
          maxFarmers: 8,
          totalCapacityQ: 160,
          baselineFarmersByHour: const [1, 2, 2, 1, 1, 2, 1, 1, 1],
          baselineQuantityByHour: const [15, 25, 20, 10, 15, 20, 10, 10, 10],
        ));
      }
    }

    Slot slotFor(String centreId, DateTime day, int hour) => slots.firstWhere(
          (s) => s.centreId == centreId && s.start == _at(day, hour),
        );

    final pastSlotDay = today.subtract(const Duration(days: 5));
    final pastSlotSelvanathan = Slot(
      id: 'slot-past-selvanathan',
      centreId: centreErode02Id,
      cropId: cropMaizeId,
      start: _at(pastSlotDay, 9),
      end: _at(pastSlotDay, 10),
      maxFarmers: 8,
      totalCapacityQ: 160,
    );
    slots.add(pastSlotSelvanathan);
    await slotRepo.saveMany(slots);

    // ---------------- 8. Bookings & Lifecycle Records ----------------
    // A. Palanisamy — Active In Live Queue (Under Quality Inspection)
    final palanisamySlot = slotFor(centreErode01Id, today, 9);
    final palanisamyBooking = Booking(
      id: 'AGR-20001',
      farmerId: palanisamyFarmerId,
      centreId: centreErode01Id,
      slotId: palanisamySlot.id,
      expectedQuantityQ: 45,
      status: BookingStatus.inQueue,
      token: 'T003',
      createdAt: today.subtract(const Duration(days: 1)),
      checkedInAt: _at(today, 9, 15),
    );

    // Dummy companion bookings for live queue realism (Tokens T001, T002)
    final companionBooking1 = Booking(
      id: 'AGR-20002',
      farmerId: 'farmer-companion-1',
      centreId: centreErode01Id,
      slotId: palanisamySlot.id,
      expectedQuantityQ: 40,
      status: BookingStatus.underQualityCheck,
      token: 'T001',
      createdAt: today.subtract(const Duration(days: 1)),
      checkedInAt: _at(today, 8, 50),
    );

    final companionBooking2 = Booking(
      id: 'AGR-20003',
      farmerId: 'farmer-companion-2',
      centreId: centreErode01Id,
      slotId: palanisamySlot.id,
      expectedQuantityQ: 50,
      status: BookingStatus.inQueue,
      token: 'T002',
      createdAt: today.subtract(const Duration(days: 1)),
      checkedInAt: _at(today, 9, 05),
    );

    // B. Selvanathan — Completed Weighment & Payment Disbursed (₹1,15,000 DBT)
    final selvanathanBooking = Booking(
      id: 'AGR-10001',
      farmerId: selvanathanFarmerId,
      centreId: centreErode02Id,
      slotId: pastSlotSelvanathan.id,
      expectedQuantityQ: 55,
      status: BookingStatus.paymentCompleted,
      token: 'T101',
      createdAt: pastSlotDay.subtract(const Duration(days: 2)),
      checkedInAt: _at(pastSlotDay, 9),
    );

    await bookingRepo.saveMany([
      palanisamyBooking,
      companionBooking1,
      companionBooking2,
      selvanathanBooking,
    ]);

    // ---------------- 9. Queue Entries (Live Queue Management) ----------------
    await queueRepo.saveMany([
      QueueEntry(
        id: 'q-1',
        bookingId: companionBooking1.id,
        token: companionBooking1.token,
        stage: QueueStage.qualityCheck,
        enteredAt: _at(today, 8, 50),
        queuePosition: 1,
        estimatedCallTime: _at(today, 9, 20),
      ),
      QueueEntry(
        id: 'q-2',
        bookingId: companionBooking2.id,
        token: companionBooking2.token,
        stage: QueueStage.arrived,
        enteredAt: _at(today, 9, 05),
        queuePosition: 2,
        estimatedCallTime: _at(today, 9, 35),
      ),
      QueueEntry(
        id: 'q-3',
        bookingId: palanisamyBooking.id,
        token: palanisamyBooking.token,
        stage: QueueStage.arrived,
        enteredAt: _at(today, 9, 15),
        queuePosition: 3,
        estimatedCallTime: _at(today, 9, 50),
      ),
    ]);

    // ---------------- 10. Procurement & Payment Records ----------------
    // For Selvanathan (Completed DBT payout)
    final procSelvanathan = ProcurementRecord(
      id: 'proc-selvanathan',
      bookingId: selvanathanBooking.id,
      weighedQuantityQ: 55.0,
      acceptedQuantityQ: 55.0,
      rejectedQuantityQ: 0.0,
      moisturePercent: 12.8,
      qualityGrade: 'Grade A',
      inspectedBy: 'K. Shanmugam',
      inspectionTime: _at(pastSlotDay, 9, 30),
    );
    await procurementRepo.save(procSelvanathan);

    await paymentRepo.save(
      Payment(
        id: 'pay-selvanathan',
        bookingId: selvanathanBooking.id,
        farmerId: selvanathanFarmerId,
        amount: 114950.0,
        status: PaymentStatus.completed,
        transactionRef: 'DBT-TN-9821049281',
        initiatedAt: _at(pastSlotDay, 11, 00),
        completedAt: _at(pastSlotDay, 15, 30),
        lastUpdated: _at(pastSlotDay, 15, 30),
      ),
    );

    // ---------------- 11. Disruption Example for Erode-01 (Dynamic Alert Demo) ----------------
    await disruptionRepo.save(
      Disruption(
        id: 'disrupt-erode-01',
        centreId: centreErode01Id,
        type: DisruptionType.inspectionDelay,
        start: _at(today, 8, 30),
        expectedResolution: _at(today, 10, 30),
        status: DisruptionStatus.active,
        affectedSlotIds: [palanisamySlot.id],
        affectedProcessingLanes: 1,
      ),
    );

    // ---------------- 12. Notification Items ----------------
    await notificationRepo.saveMany([
      NotificationItem(
        id: 'ntf-1',
        userId: palanisamyFarmerId,
        title: 'Check-in Confirmed • Token #T003 Issued',
        message: 'You have entered the live queue at Erode Regulated Market Hub. Estimated wait is 35 mins.',
        timestamp: _at(today, 9, 15),
        type: NotificationType.queueUpdate,
      ),
      NotificationItem(
        id: 'ntf-2',
        userId: palanisamyFarmerId,
        title: 'Centre Operational Alert',
        message: 'Weighbridge 2 recalibration is underway. Real-time queue tracker will keep you updated.',
        timestamp: _at(today, 9, 20),
        type: NotificationType.delay,
      ),
      NotificationItem(
        id: 'ntf-3',
        userId: selvanathanFarmerId,
        title: 'MSP DBT Credit Confirmed',
        message: 'Payment of ₹1,14,950 has been credited to your bank account via PFMS Ref DBT-TN-9821049281.',
        timestamp: _at(pastSlotDay, 15, 30),
        type: NotificationType.paymentUpdate,
      ),
    ]);
  }

  static List<Slot> _hourlySlots({
    required String centreId,
    required String cropId,
    required DateTime day,
    required int startHour,
    required int endHour,
    required int maxFarmers,
    required double totalCapacityQ,
    List<int> baselineFarmersByHour = const [],
    List<double> baselineQuantityByHour = const [],
  }) {
    final result = <Slot>[];
    for (var h = startHour; h < endHour; h++) {
      final index = h - startHour;
      final bf = index < baselineFarmersByHour.length ? baselineFarmersByHour[index] : 0;
      final bq = index < baselineQuantityByHour.length ? baselineQuantityByHour[index] : 0.0;
      result.add(
        Slot(
          id: 'slot-$centreId-${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}-$h',
          centreId: centreId,
          cropId: cropId,
          start: _at(day, h),
          end: _at(day, h + 1),
          maxFarmers: maxFarmers,
          totalCapacityQ: totalCapacityQ,
          baselineFarmers: bf,
          baselineQuantityQ: bq,
        ),
      );
    }
    return result;
  }
}
