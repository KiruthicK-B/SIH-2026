// Mirrors onedesk/src/data/consents.ts exactly.

export type ConsentStatus = 'Active' | 'Revoked' | 'Expired';

export interface Consent {
  id: string;
  dataCategory: string;
  department: string;
  purpose: string;
  status: ConsentStatus;
  grantedOn: string;
  validUntil: string;
  citizenMasterId?: string;
}

export interface PendingConsentRequest {
  id: string;
  department: string;
  purpose: string;
  dataRequested: string[];
  requestedOn: string;
  eligible: boolean;
  eligibilityReasons: string[];
}
