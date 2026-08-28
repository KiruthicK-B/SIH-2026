/// Statewide manager KPIs. AGRIVA's interactive demo only deep-models two
/// centres; these top-line figures represent the wider network the
/// manager oversees, and are intentionally fixed (README §107-108).
class ManagerKpis {
  static const totalCentres = 12;
  static const farmersToday = 356;
  static const quantityProcuredQ = 5250;
  static const paymentsCompletedLakh = 12.45;
  static const averageWaitingMinutes = 42;
  static const capacityUtilizationPercent = 72;
  static const storageUtilizationPercent = 68;

  static const quantityByDay = [
    420.0,
    610.0,
    540.0,
    700.0,
    680.0,
    590.0,
    730.0,
  ];
  static const quantityByDayLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const avgWaitByCentre = {'Nagpur Centre': 42, 'Akola Centre': 98};
}
