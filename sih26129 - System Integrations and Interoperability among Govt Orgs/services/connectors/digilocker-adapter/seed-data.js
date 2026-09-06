// Committed seed rows for the mock UIDAI/govt registry. Deliberately empty — the
// registry now starts with only real, admin-added records (see the "Add Person"
// button on the platform console's Govt Identity Registry tab, backed by
// POST /admin/records) rather than invented demo people. A gitignored
// seed-data.local.js may still add a real developer-owned row for local demos; see
// loadSeedRows() in index.js.
module.exports = []
