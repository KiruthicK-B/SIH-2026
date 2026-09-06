import { BadRequestException, Injectable } from '@nestjs/common';

const KEYCLOAK_ADMIN_URL = process.env.KEYCLOAK_ADMIN_URL ?? 'http://keycloak:8080';
const REALM = 'onedesk';

interface CreateCitizenUserInput {
  username: string;
  password: string;
  firstName: string;
  lastName: string;
  masterId: string;
}

/**
 * Programmatic Keycloak user creation for citizen self-registration, using the
 * bootstrap master-realm admin (already present for local dev — see
 * docker-compose.yml's KEYCLOAK_ADMIN/KEYCLOAK_ADMIN_PASSWORD) rather than granting
 * the core-api client's own service account realm-management roles — avoids any
 * realm-export.json/Keycloak client reconfiguration, which wouldn't re-apply to the
 * already-running realm anyway (Keycloak only imports a realm on first boot).
 */
@Injectable()
export class KeycloakAdminService {
  private async getAdminToken(): Promise<string> {
    const username = process.env.KEYCLOAK_ADMIN_USERNAME;
    const password = process.env.KEYCLOAK_ADMIN_PASSWORD;
    // No fallback to Keycloak's well-known dev bootstrap credentials — a missing env
    // var should fail loudly, not silently authenticate as admin/admin.
    if (!username || !password) throw new Error('KEYCLOAK_ADMIN_USERNAME/KEYCLOAK_ADMIN_PASSWORD not configured');

    const res = await fetch(`${KEYCLOAK_ADMIN_URL}/realms/master/protocol/openid-connect/token`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'password',
        client_id: 'admin-cli',
        username,
        password,
      }),
    });
    if (!res.ok) throw new Error(`could not obtain Keycloak admin token: ${res.status}`);
    const body = await res.json();
    return body.access_token;
  }

  /** Creates a real Keycloak user with the `citizen` realm role and a non-temporary
   * password — the citizen never has to visit Keycloak's own hosted page, matching
   * the direct-grant login flow already built. */
  async createCitizenUser(input: CreateCitizenUserInput): Promise<void> {
    const token = await this.getAdminToken();
    const headers = { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' };

    const createRes = await fetch(`${KEYCLOAK_ADMIN_URL}/admin/realms/${REALM}/users`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        username: input.username,
        enabled: true,
        firstName: input.firstName,
        lastName: input.lastName,
        // Every pre-seeded user has a verified email; Keycloak 26's user-profile
        // validation treats an account with none as incomplete and rejects direct
        // grant login with "Account is not fully set up" — there's no real inbox to
        // verify against here, so this is synthesized and marked verified upfront.
        email: `${input.username}@citizen.onedesk.gov.in`,
        emailVerified: true,
        attributes: { master_id: [input.masterId] },
        credentials: [{ type: 'password', value: input.password, temporary: false }],
      }),
    });
    if (createRes.status === 409) {
      throw new BadRequestException('an account with this phone number or ID already exists');
    }
    if (!createRes.ok) {
      throw new Error(`Keycloak user creation failed: ${createRes.status} ${await createRes.text()}`);
    }

    const location = createRes.headers.get('location');
    const userId = location?.split('/').pop();
    if (!userId) throw new Error('Keycloak did not return a user id');

    const roleRes = await fetch(`${KEYCLOAK_ADMIN_URL}/admin/realms/${REALM}/roles/citizen`, { headers });
    if (!roleRes.ok) throw new Error(`could not look up citizen role: ${roleRes.status}`);
    const role = await roleRes.json();

    const assignRes = await fetch(`${KEYCLOAK_ADMIN_URL}/admin/realms/${REALM}/users/${userId}/role-mappings/realm`, {
      method: 'POST',
      headers,
      body: JSON.stringify([{ id: role.id, name: role.name }]),
    });
    if (!assignRes.ok) throw new Error(`could not assign citizen role: ${assignRes.status}`);
  }
}
