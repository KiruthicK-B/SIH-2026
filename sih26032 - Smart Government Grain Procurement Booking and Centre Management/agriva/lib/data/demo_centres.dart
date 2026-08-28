import '../models/centre.dart';
import '../models/enums.dart';

const centreAId = 'centre-abc';
const centreBId = 'centre-xyz';

List<ProcurementCentre> buildDemoCentres() => [
  const ProcurementCentre(
    id: centreAId,
    name: 'ABC Government Procurement Centre',
    status: CentreStatus.open,
    dailyProcessingCapacityQ: 1000,
    storageCapacityQ: 1000,
    currentStorageQ: 680,
    processingLanesTotal: 2,
    processingLanesActive: 2,
    staffNormal: 10,
    staffAvailable: 10,
  ),
  const ProcurementCentre(
    id: centreBId,
    name: 'XYZ Government Procurement Centre',
    status: CentreStatus.delayed,
    dailyProcessingCapacityQ: 800,
    storageCapacityQ: 900,
    currentStorageQ: 820,
    processingLanesTotal: 2,
    processingLanesActive: 1,
    staffNormal: 10,
    staffAvailable: 6,
  ),
];
