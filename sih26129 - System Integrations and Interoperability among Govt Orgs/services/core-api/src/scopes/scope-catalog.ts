export interface ScopeDefinition {
  key: string;
  label: string;
  sourceAuthority: string;
  isDefault: boolean;
  /** master_identity column names this scope may populate. */
  columns: string[];
}

// The set of data categories OneDesk can ever pull from the mock govt registry, and
// which of them are always shared (a OneDesk account needs at least a name and a
// login-linked phone number to function at all). Everything else is opt-in, chosen at
// registration and changeable later in Settings — see ScopesService.
export const SCOPES: ScopeDefinition[] = [
  { key: 'identity.basic', label: 'Name, date of birth, gender, photo', sourceAuthority: 'UIDAI (Aadhaar)', isDefault: true, columns: ['citizen_name', 'date_of_birth', 'gender', 'photo_path'] },
  { key: 'identity.contact', label: 'Phone number', sourceAuthority: 'UIDAI (linked mobile)', isDefault: true, columns: ['phone_number'] },
  { key: 'identity.address', label: 'Residential address', sourceAuthority: 'UIDAI (Aadhaar)', isDefault: false, columns: ['address'] },
  { key: 'identity.aadhaar_number', label: 'Aadhaar number', sourceAuthority: 'UIDAI', isDefault: false, columns: ['aadhaar_number'] },
  { key: 'identity.pan', label: 'PAN number', sourceAuthority: 'Income Tax Department', isDefault: false, columns: ['pan_number'] },
  { key: 'identity.employment', label: 'Employment status, employer & occupation', sourceAuthority: 'Self-declared / EPFO-style', isDefault: false, columns: ['employment_status', 'employer_name', 'designation', 'occupation'] },
  { key: 'identity.education', label: 'Highest qualification & institution', sourceAuthority: 'Self-declared / DigiLocker Academic', isDefault: false, columns: ['highest_qualification', 'institution_name'] },
  { key: 'identity.family', label: 'Parent details & siblings', sourceAuthority: 'Self-declared / Family Registry', isDefault: false, columns: ['father_name', 'mother_name', 'parent_phone_number', 'siblings'] },
];

export const DEFAULT_SCOPE_KEYS = SCOPES.filter((s) => s.isDefault).map((s) => s.key);

export function findScope(key: string): ScopeDefinition | undefined {
  return SCOPES.find((s) => s.key === key);
}

// Maps a master_identity column to the matching field on the govt-registry eKYC
// response (digilocker-adapter's /ekyc, camelCase). photo_path has no direct field —
// it's fetched separately from the adapter's /photo endpoint.
const GOVT_FIELD_BY_COLUMN: Record<string, string> = {
  citizen_name: 'name',
  date_of_birth: 'dateOfBirth',
  gender: 'gender',
  address: 'address',
  aadhaar_number: 'aadhaarNumber',
  pan_number: 'panNumber',
  phone_number: 'phoneNumber',
  employment_status: 'employmentStatus',
  employer_name: 'employerName',
  designation: 'designation',
  highest_qualification: 'highestQualification',
  institution_name: 'institutionName',
  occupation: 'occupation',
  father_name: 'fatherName',
  mother_name: 'motherName',
  parent_phone_number: 'parentPhoneNumber',
  siblings: 'siblings',
};

export function extractScopeColumns(scope: ScopeDefinition, govtRecord: Record<string, unknown>): Record<string, unknown> {
  const result: Record<string, unknown> = {};
  for (const column of scope.columns) {
    if (column === 'photo_path') continue;
    const field = GOVT_FIELD_BY_COLUMN[column];
    if (field) result[column] = govtRecord[field] ?? null;
  }
  return result;
}
