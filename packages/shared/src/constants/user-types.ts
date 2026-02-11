import type { UserType } from '../types/pricing';

export const USER_TYPE_LABELS: Record<UserType, string> = {
  resident: 'San Diego Resident',
  nonresident: 'Visitor',
  staff: 'Staff/Volunteer',
  volunteer: 'Volunteer',
  ada: 'ADA/Disabled',
};

export const USER_TYPE_DESCRIPTIONS: Record<UserType, string> = {
  resident: 'San Diego residents with valid ID get discounted parking rates',
  nonresident: 'Visitors and tourists pay standard parking rates',
  staff: 'Balboa Park staff members with valid credentials',
  volunteer: 'Registered volunteers at Balboa Park institutions',
  ada: 'Holders of valid ADA placards or disabled parking permits',
};

export const USER_TYPE_ICONS: Record<UserType, string> = {
  resident: '\u{1F3E0}',
  nonresident: '\u{1F30D}',
  staff: '\u{1F4BC}',
  volunteer: '\u{1F91D}',
  ada: '\u267F',
};
