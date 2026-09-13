import { createHmac, timingSafeEqual } from 'node:crypto';

/**
 * The shared secret each live department portal holds. Used in both directions:
 * the portal signs its decision callback with it (verified in
 * InteropController.deptCallback), and core-api signs the short-lived document
 * URLs it hands that portal with it (verified in InteropController.document).
 *
 * Plain module rather than a Nest provider because ConnectorsService (which signs
 * outbound document URLs) and InteropController (which verifies inbound requests)
 * both need it, and neither should own it.
 */
export const DEPARTMENT_BY_SLUG: Record<string, string> = {
  'business-registry': 'Business Registry Portal',
  'license-authority': 'License Authority Portal',
  revenue: 'Revenue Department Portal',
};

export const SLUG_BY_DEPARTMENT: Record<string, string> = Object.fromEntries(
  Object.entries(DEPARTMENT_BY_SLUG).map(([slug, department]) => [department, slug]),
);

export const CALLBACK_SECRETS: Record<string, string> = {
  'Business Registry Portal': process.env.BUSINESS_REGISTRY_PORTAL_CALLBACK_SECRET ?? 'business-registry-portal-dev-secret',
  'License Authority Portal': process.env.LICENSE_AUTHORITY_PORTAL_CALLBACK_SECRET ?? 'license-authority-portal-dev-secret',
  'Revenue Department Portal': process.env.REVENUE_PORTAL_CALLBACK_SECRET ?? 'revenue-portal-dev-secret',
};

/** How long a handed-out document URL stays valid. Long enough for an officer to
 * work a case at their own pace, short enough that a leaked URL isn't a standing
 * grant — the department re-fetches through its own backend, which still holds the
 * URL, so expiry only bites if a case sits untouched for days. */
export const DOC_URL_TTL_MS = 1000 * 60 * 60 * 24 * 3;

export function signDocumentAccess(docId: string, applicationId: string, department: string, expiresAt: number): string {
  const secret = CALLBACK_SECRETS[department];
  if (!secret) return '';
  return createHmac('sha256', secret).update(`${docId}|${applicationId}|${department}|${expiresAt}`).digest('hex');
}

export function verifyDocumentAccess(
  docId: string,
  applicationId: string,
  department: string,
  expiresAt: number,
  signature: string,
): boolean {
  const expected = signDocumentAccess(docId, applicationId, department, expiresAt);
  if (!expected || !signature) return false;
  const a = Buffer.from(expected, 'hex');
  const b = Buffer.from(signature, 'hex');
  return a.length === b.length && timingSafeEqual(a, b);
}

export function verifyCallbackSignature(
  department: string,
  body: { applicationId: string; decision: string; decidedBy: string; decidedAt: string },
  signature: string,
): boolean {
  const secret = CALLBACK_SECRETS[department];
  if (!secret || !signature) return false;
  const expected = createHmac('sha256', secret)
    .update(`${body.applicationId}|${body.decision}|${body.decidedBy}|${body.decidedAt}`)
    .digest('hex');
  const a = Buffer.from(expected, 'hex');
  const b = Buffer.from(signature, 'hex');
  return a.length === b.length && timingSafeEqual(a, b);
}
