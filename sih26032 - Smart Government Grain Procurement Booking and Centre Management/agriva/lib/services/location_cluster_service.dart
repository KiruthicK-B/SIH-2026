class ClusterMappingResult {
  final String centreId;
  final String centreCode;
  final String centreName;
  final String clusterName;
  final double approxDistanceKm;
  final int estimatedTravelMinutes;

  const ClusterMappingResult({
    required this.centreId,
    required this.centreCode,
    required this.centreName,
    required this.clusterName,
    required this.approxDistanceKm,
    required this.estimatedTravelMinutes,
  });
}

class LocationClusterService {
  const LocationClusterService();

  static const List<String> supportedDistricts = [
    'Erode',
    'Tiruppur',
    'Thanjavur',
    'Tiruvarur',
    'Madurai',
  ];

  static const Map<String, List<String>> districtTaluks = {
    'Erode': ['Erode Rural', 'Perundurai', 'Gobichettipalayam'],
    'Tiruppur': ['Tiruppur South', 'Dharapuram', 'Kangeyam'],
    'Thanjavur': ['Thanjavur Central', 'Kumbakonam', 'Pattukkottai'],
    'Tiruvarur': ['Tiruvarur North', 'Mannargudi'],
    'Madurai': ['Madurai North', 'Usilampatti'],
  };

  static const Map<String, List<String>> talukVillages = {
    'Erode Rural': ['Kasipalayam', 'Surampatti', 'Villarasampatti', 'Moolapalayam', 'Thindal'],
    'Perundurai': ['Chennimalai', 'Vijayamangalam', 'Ingur', 'Kunnathur', 'Seenapuram'],
    'Gobichettipalayam': ['Lakkampatti', 'Nambiyur', 'Kugalur', 'Alukuli', 'Polavapalayam'],
    'Tiruppur South': ['Velampalayam', 'Chettipalayam', 'Neruperichal', 'Nallur', 'Andipalayam'],
    'Dharapuram': ['Alangiyam', 'Kundadam', 'Kolathupalayam', 'Mulanur', 'Kannivadi'],
    'Kangeyam': ['Muthur', 'Sivanmalai', 'Vellakovil', 'Nathakadaiyur', 'Pappini'],
    'Thanjavur Central': ['Vallam', 'Nanjikottai', 'Punnainallur', 'Pillaiyarpatti', 'Kandiyur'],
    'Kumbakonam': ['Darasuram', 'Swamimalai', 'Thirunageswaram', 'Cholapuram', 'Patteswaram'],
    'Pattukkottai': ['Adirampattinam', 'Madukkur', 'Peravurani', 'Mallipattinam', 'Enathi'],
    'Tiruvarur North': ['Koradacheri', 'Kodavasal', 'Kulikarai', 'Ammaiyappan', 'Peralam'],
    'Mannargudi': ['Needamangalam', 'Kottur', 'Pamani', 'Ullikkottai', 'Vaduvur'],
    'Madurai North': ['Alanganallur', 'Palamedu', 'Samayanallur', 'Sholavandan', 'Vadipatti'],
    'Usilampatti': ['Chekkanurani', 'Sedapatti', 'Valandur', 'Karumathur', 'Elumalai'],
  };

  /// Returns the pre-defined cluster mapping linking district + taluk + village
  /// to its designated official procurement centre.
  static ClusterMappingResult getAssignedCentre({
    required String district,
    required String taluk,
    String? village,
  }) {
    final d = district.trim().toLowerCase();
    final t = taluk.trim().toLowerCase();

    // Erode
    if (d.contains('erode')) {
      if (t.contains('perundurai')) {
        return const ClusterMappingResult(
          centreId: 'centre-erode-02',
          centreCode: 'OP-Erode-02',
          centreName: 'Perundurai Grain Mandi',
          clusterName: 'Perundurai Agricultural Cluster',
          approxDistanceKm: 6.5,
          estimatedTravelMinutes: 15,
        );
      } else if (t.contains('gobi') || t.contains('gobichettipalayam')) {
        return const ClusterMappingResult(
          centreId: 'centre-erode-03',
          centreCode: 'OP-Erode-03',
          centreName: 'Gobichettipalayam Procurement Centre',
          clusterName: 'Gobichettipalayam Taluk Cluster',
          approxDistanceKm: 8.0,
          estimatedTravelMinutes: 20,
        );
      } else {
        return const ClusterMappingResult(
          centreId: 'centre-erode-01',
          centreCode: 'OP-Erode-01',
          centreName: 'Erode Regulated Market Hub',
          clusterName: 'Erode Central Cluster',
          approxDistanceKm: 4.5,
          estimatedTravelMinutes: 12,
        );
      }
    }

    // Tiruppur
    if (d.contains('tiruppur')) {
      if (t.contains('dharapuram')) {
        return const ClusterMappingResult(
          centreId: 'centre-tiruppur-02',
          centreCode: 'OP-Tiruppur-02',
          centreName: 'Dharapuram Grain Centre',
          clusterName: 'Dharapuram Belt Cluster',
          approxDistanceKm: 7.2,
          estimatedTravelMinutes: 18,
        );
      } else if (t.contains('kangeyam')) {
        return const ClusterMappingResult(
          centreId: 'centre-tiruppur-03',
          centreCode: 'OP-Tiruppur-03',
          centreName: 'Kangeyam Agricultural Mandi',
          clusterName: 'Kangeyam Farmer Cluster',
          approxDistanceKm: 5.8,
          estimatedTravelMinutes: 14,
        );
      } else {
        return const ClusterMappingResult(
          centreId: 'centre-tiruppur-01',
          centreCode: 'OP-Tiruppur-01',
          centreName: 'Tiruppur Central APMC Depot',
          clusterName: 'Tiruppur South Cluster',
          approxDistanceKm: 5.0,
          estimatedTravelMinutes: 12,
        );
      }
    }

    // Thanjavur
    if (d.contains('thanjavur')) {
      if (t.contains('kumbakonam')) {
        return const ClusterMappingResult(
          centreId: 'centre-thanjavur-02',
          centreCode: 'OP-Thanjavur-02',
          centreName: 'Kumbakonam Modern Rice Procurement Centre',
          clusterName: 'Kumbakonam Delta Cluster',
          approxDistanceKm: 6.0,
          estimatedTravelMinutes: 15,
        );
      } else if (t.contains('pattukkottai')) {
        return const ClusterMappingResult(
          centreId: 'centre-thanjavur-03',
          centreCode: 'OP-Thanjavur-03',
          centreName: 'Pattukkottai Grain Depot',
          clusterName: 'Pattukkottai Coastal Agricultural Cluster',
          approxDistanceKm: 9.5,
          estimatedTravelMinutes: 22,
        );
      } else {
        return const ClusterMappingResult(
          centreId: 'centre-thanjavur-01',
          centreCode: 'OP-Thanjavur-01',
          centreName: 'Thanjavur Direct Purchase Centre (DPC) Hub',
          clusterName: 'Thanjavur Central Paddy Cluster',
          approxDistanceKm: 3.8,
          estimatedTravelMinutes: 10,
        );
      }
    }

    // Tiruvarur
    if (d.contains('tiruvarur')) {
      if (t.contains('mannargudi')) {
        return const ClusterMappingResult(
          centreId: 'centre-tiruvarur-02',
          centreCode: 'OP-Tiruvarur-02',
          centreName: 'Mannargudi Paddy Procurement Centre',
          clusterName: 'Mannargudi Grain Cluster',
          approxDistanceKm: 5.2,
          estimatedTravelMinutes: 14,
        );
      } else {
        return const ClusterMappingResult(
          centreId: 'centre-tiruvarur-01',
          centreCode: 'OP-Tiruvarur-01',
          centreName: 'Tiruvarur Central DPC',
          clusterName: 'Tiruvarur North Delta Cluster',
          approxDistanceKm: 4.0,
          estimatedTravelMinutes: 11,
        );
      }
    }

    // Madurai
    if (d.contains('madurai')) {
      if (t.contains('usilampatti')) {
        return const ClusterMappingResult(
          centreId: 'centre-madurai-02',
          centreCode: 'OP-Madurai-02',
          centreName: 'Usilampatti Grain Procurement Mandi',
          clusterName: 'Usilampatti Rural Cluster',
          approxDistanceKm: 7.8,
          estimatedTravelMinutes: 20,
        );
      } else {
        return const ClusterMappingResult(
          centreId: 'centre-madurai-01',
          centreCode: 'OP-Madurai-01',
          centreName: 'Madurai Integrated Agricultural Hub',
          clusterName: 'Madurai North Cluster',
          approxDistanceKm: 4.8,
          estimatedTravelMinutes: 13,
        );
      }
    }

    // Default fallback to Erode-01
    return const ClusterMappingResult(
      centreId: 'centre-erode-01',
      centreCode: 'OP-Erode-01',
      centreName: 'Erode Regulated Market Hub',
      clusterName: 'Regional Cluster',
      approxDistanceKm: 5.0,
      estimatedTravelMinutes: 15,
    );
  }
}
