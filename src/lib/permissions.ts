export const businessRoles = ['business_owner', 'business_admin', 'receptionist', 'staff'] as const;
export type BusinessRole = (typeof businessRoles)[number];

export const permissions = [
  'appointments.read',
  'appointments.create',
  'appointments.update',
  'customers.read',
  'customers.update',
  'analytics.view',
  'services.manage',
  'staff.manage',
  'billing.manage',
] as const;
export type Permission = (typeof permissions)[number];

const rolePermissions: Record<BusinessRole, ReadonlySet<Permission>> = {
  business_owner: new Set(permissions),
  business_admin: new Set(permissions.filter((permission) => permission !== 'billing.manage')),
  receptionist: new Set([
    'appointments.read',
    'appointments.create',
    'appointments.update',
    'customers.read',
    'customers.update',
  ]),
  staff: new Set([
    'appointments.read',
    'appointments.update',
    'customers.read',
  ]),
};

export function roleHasPermission(role: BusinessRole, permission: Permission) {
  return rolePermissions[role].has(permission);
}
