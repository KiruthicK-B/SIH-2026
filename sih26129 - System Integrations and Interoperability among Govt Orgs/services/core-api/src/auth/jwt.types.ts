export interface AuthenticatedUser {
  sub: string;
  username: string;
  roles: string[];
  department: string | null;
  masterId: string | null;
}
