// Mirrors agriva/lib/repositories/local/hive_json_repository.dart HiveBootstrap.boxNames
// exactly — one Postgres table per Hive box, same names, so the app's entityPath
// (see remote/http_json_repository.dart) lines up 1:1 with these table names.
const ENTITY_TABLES = [
  'farmers',
  'landRecords',
  'crops',
  'centres',
  'slots',
  'districts',
  'bookings',
  'queueEntries',
  'procurementRecords',
  'payments',
  'rescheduleOffers',
  'disruptions',
  'adminUsers',
  'broadcasts',
  'grievances',
  'notifications',
  'auditLogs',
];

const ENTITY_TABLE_SET = new Set(ENTITY_TABLES);

function isValidEntity(name) {
  return ENTITY_TABLE_SET.has(name);
}

module.exports = { ENTITY_TABLES, isValidEntity };
