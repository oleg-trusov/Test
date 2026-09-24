-- Working schema for LUMÉA Suite.
-- This file is promoted to a Supabase migration after a dedicated project is provisioned.
-- RLS is enabled explicitly on every Data API table.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create extension if not exists btree_gist with schema extensions;

create type public.platform_role as enum ('platform_admin');
create type public.business_status as enum ('trial', 'active', 'suspended', 'cancelled');
create type public.member_role as enum ('business_owner', 'business_admin', 'receptionist', 'staff');
create type public.member_status as enum ('invited', 'active', 'suspended');
create type public.price_type as enum ('fixed', 'from', 'free', 'custom');
create type public.exception_type as enum ('vacation', 'sick_leave', 'personal_day', 'custom_hours', 'blocked', 'training', 'break');
create type public.appointment_status as enum ('pending', 'confirmed', 'checked_in', 'in_progress', 'completed', 'cancelled_by_customer', 'cancelled_by_business', 'no_show');
create type public.appointment_source as enum ('online', 'admin', 'phone', 'walk_in');
create type public.payment_method as enum ('cash', 'card', 'other');
create type public.payment_status as enum ('pending', 'paid', 'failed', 'refunded', 'partially_refunded');
create type public.discount_type as enum ('fixed', 'percentage');
create type public.media_kind as enum ('logo', 'cover', 'interior', 'portfolio', 'avatar');
create type public.notification_kind as enum ('booking_created', 'booking_confirmed', 'booking_reminder', 'booking_changed', 'booking_cancelled', 'review_request', 'employee_invited');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text,
  phone text,
  first_name text,
  last_name text,
  avatar_url text,
  locale text not null default 'cs',
  platform_role public.platform_role,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.businesses (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles(id),
  name text not null,
  slug text not null unique,
  description text,
  logo_url text,
  cover_url text,
  category text not null,
  timezone text not null default 'Europe/Prague',
  currency text not null default 'CZK' check (currency in ('CZK','EUR','USD','UAH','PLN','GBP')),
  phone text,
  email text,
  website text,
  accent_color text,
  status public.business_status not null default 'trial',
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.business_members (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  role public.member_role not null,
  status public.member_status not null default 'active',
  created_at timestamptz not null default now(),
  unique (business_id, user_id)
);

create table public.branches (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  country text not null,
  city text not null,
  postal_code text,
  address text not null,
  latitude numeric(9,6),
  longitude numeric(9,6),
  phone text,
  timezone text not null,
  is_active boolean not null default true,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  unique (business_id, id)
);

create table public.service_categories (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  name text not null,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (business_id, id)
);

create table public.services (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  category_id uuid,
  name text not null,
  description text,
  duration_minutes integer not null check (duration_minutes > 0),
  price_minor bigint not null default 0 check (price_minor >= 0),
  price_type public.price_type not null default 'fixed',
  currency text not null check (currency in ('CZK','EUR','USD','UAH','PLN','GBP')),
  buffer_before_minutes integer not null default 0 check (buffer_before_minutes >= 0),
  buffer_after_minutes integer not null default 0 check (buffer_after_minutes >= 0),
  is_active boolean not null default true,
  online_booking_enabled boolean not null default true,
  image_url text,
  sort_order integer not null default 0,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, id),
  foreign key (business_id, category_id) references public.service_categories(business_id, id)
);

create table public.service_branches (
  business_id uuid not null references public.businesses(id) on delete cascade,
  service_id uuid not null,
  branch_id uuid not null,
  is_active boolean not null default true,
  primary key (service_id, branch_id),
  foreign key (business_id, service_id) references public.services(business_id, id) on delete cascade,
  foreign key (business_id, branch_id) references public.branches(business_id, id) on delete cascade
);

create table public.staff_profiles (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  profile_id uuid references public.profiles(id) on delete set null,
  display_name text not null,
  bio text,
  job_title text,
  phone text,
  email text,
  avatar_url text,
  is_bookable boolean not null default true,
  is_active boolean not null default true,
  start_date date,
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  unique (business_id, id)
);

create table public.staff_branches (
  business_id uuid not null references public.businesses(id) on delete cascade,
  staff_id uuid not null,
  branch_id uuid not null,
  is_active boolean not null default true,
  primary key (staff_id, branch_id),
  foreign key (business_id, staff_id) references public.staff_profiles(business_id, id) on delete cascade,
  foreign key (business_id, branch_id) references public.branches(business_id, id) on delete cascade
);

create table public.staff_services (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  staff_id uuid not null,
  service_id uuid not null,
  custom_price_minor bigint check (custom_price_minor is null or custom_price_minor >= 0),
  custom_duration_minutes integer check (custom_duration_minutes is null or custom_duration_minutes > 0),
  is_active boolean not null default true,
  unique (staff_id, service_id),
  foreign key (business_id, staff_id) references public.staff_profiles(business_id, id) on delete cascade,
  foreign key (business_id, service_id) references public.services(business_id, id) on delete cascade
);

create table public.business_hours (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  branch_id uuid not null,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  is_open boolean not null default true,
  check (start_time < end_time),
  foreign key (business_id, branch_id) references public.branches(business_id, id) on delete cascade
);

create table public.staff_working_hours (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  staff_id uuid not null,
  branch_id uuid not null,
  day_of_week smallint not null check (day_of_week between 0 and 6),
  start_time time not null,
  end_time time not null,
  check (start_time < end_time),
  foreign key (business_id, staff_id) references public.staff_profiles(business_id, id) on delete cascade,
  foreign key (business_id, branch_id) references public.branches(business_id, id) on delete cascade
);

create table public.schedule_exceptions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  staff_id uuid not null,
  branch_id uuid not null,
  local_date date not null,
  start_time time,
  end_time time,
  type public.exception_type not null,
  reason text,
  is_available boolean not null default false,
  created_at timestamptz not null default now(),
  check ((start_time is null and end_time is null) or (start_time is not null and end_time is not null and start_time < end_time)),
  foreign key (business_id, staff_id) references public.staff_profiles(business_id, id) on delete cascade,
  foreign key (business_id, branch_id) references public.branches(business_id, id) on delete cascade
);

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid references public.profiles(id) on delete set null,
  email text,
  phone text,
  first_name text not null,
  last_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index customers_profile_unique on public.customers(profile_id) where profile_id is not null;

create table public.customer_business_profiles (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  customer_id uuid not null references public.customers(id),
  first_name text not null,
  last_name text,
  phone text,
  email text,
  birth_date date,
  internal_notes text,
  visits_count integer not null default 0,
  cancellations_count integer not null default 0,
  no_show_count integer not null default 0,
  total_spent_minor bigint not null default 0,
  last_visit_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (business_id, customer_id),
  unique (business_id, id)
);

create table public.appointments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  branch_id uuid not null,
  customer_id uuid not null,
  staff_id uuid not null,
  start_at timestamptz not null,
  end_at timestamptz not null,
  occupied_start_at timestamptz not null,
  occupied_end_at timestamptz not null,
  status public.appointment_status not null default 'pending',
  subtotal_minor bigint not null default 0 check (subtotal_minor >= 0),
  discount_minor bigint not null default 0 check (discount_minor >= 0),
  total_minor bigint not null default 0 check (total_minor >= 0),
  currency text not null check (currency in ('CZK','EUR','USD','UAH','PLN','GBP')),
  customer_note text,
  internal_note text,
  source public.appointment_source not null default 'online',
  created_by uuid references public.profiles(id) on delete set null,
  staff_name_snapshot text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (start_at < end_at),
  check (occupied_start_at <= start_at and occupied_end_at >= end_at and occupied_start_at < occupied_end_at),
  unique (business_id, id),
  foreign key (business_id, branch_id) references public.branches(business_id, id),
  foreign key (business_id, customer_id) references public.customer_business_profiles(business_id, id),
  foreign key (business_id, staff_id) references public.staff_profiles(business_id, id)
);

alter table public.appointments
  add constraint appointments_no_staff_overlap
  exclude using gist (
    staff_id with =,
    tstzrange(occupied_start_at, occupied_end_at, '[)') with &&
  )
  where (status in ('pending','confirmed','checked_in','in_progress'));

create table public.appointment_services (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  appointment_id uuid not null,
  service_id uuid,
  service_name_snapshot text not null,
  duration_snapshot integer not null check (duration_snapshot > 0),
  price_snapshot bigint not null check (price_snapshot >= 0),
  buffer_before_snapshot integer not null default 0,
  buffer_after_snapshot integer not null default 0,
  sort_order integer not null default 0,
  foreign key (business_id, appointment_id) references public.appointments(business_id, id) on delete cascade,
  foreign key (business_id, service_id) references public.services(business_id, id) on delete restrict
);

create table public.appointment_status_history (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  appointment_id uuid not null,
  from_status public.appointment_status,
  to_status public.appointment_status not null,
  changed_by uuid references public.profiles(id) on delete set null,
  note text,
  created_at timestamptz not null default now(),
  foreign key (business_id, appointment_id) references public.appointments(business_id, id) on delete cascade
);

create table public.payments (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  booking_id uuid not null,
  customer_id uuid not null,
  amount_minor bigint not null check (amount_minor >= 0),
  currency text not null check (currency in ('CZK','EUR','USD','UAH','PLN','GBP')),
  method public.payment_method not null,
  status public.payment_status not null default 'pending',
  provider text,
  provider_payment_id text,
  created_at timestamptz not null default now(),
  foreign key (business_id, booking_id) references public.appointments(business_id, id),
  foreign key (business_id, customer_id) references public.customer_business_profiles(business_id, id)
);

create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  appointment_id uuid not null unique,
  customer_id uuid not null,
  staff_id uuid,
  rating smallint not null check (rating between 1 and 5),
  body text,
  is_approved boolean not null default true,
  created_at timestamptz not null default now(),
  foreign key (business_id, appointment_id) references public.appointments(business_id, id),
  foreign key (business_id, customer_id) references public.customer_business_profiles(business_id, id),
  foreign key (business_id, staff_id) references public.staff_profiles(business_id, id)
);

create table public.favorites (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  business_id uuid references public.businesses(id) on delete cascade,
  staff_id uuid references public.staff_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  check ((business_id is not null)::int + (staff_id is not null)::int = 1)
);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  business_id uuid references public.businesses(id) on delete cascade,
  kind public.notification_kind not null,
  title text not null,
  body text not null,
  data jsonb not null default '{}'::jsonb,
  read_at timestamptz,
  created_at timestamptz not null default now()
);

create table public.notification_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  email_enabled boolean not null default true,
  in_app_enabled boolean not null default true,
  reminder_24h boolean not null default true,
  reminder_2h boolean not null default true,
  updated_at timestamptz not null default now()
);

create table public.business_settings (
  business_id uuid primary key references public.businesses(id) on delete cascade,
  booking_window_days integer not null default 60 check (booking_window_days between 1 and 365),
  minimum_notice_minutes integer not null default 120 check (minimum_notice_minutes >= 0),
  cancellation_notice_minutes integer not null default 720 check (cancellation_notice_minutes >= 0),
  slot_interval_minutes integer not null default 15 check (slot_interval_minutes in (5,10,15,20,30,60)),
  updated_at timestamptz not null default now()
);

create table public.subscription_plans (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  price_minor bigint not null default 0,
  currency text not null default 'EUR',
  staff_limit integer,
  branch_limit integer,
  features jsonb not null default '{}'::jsonb,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.business_subscriptions (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null unique references public.businesses(id) on delete cascade,
  plan_id uuid not null references public.subscription_plans(id),
  status text not null,
  provider text,
  provider_subscription_id text,
  current_period_end timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.promo_codes (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  code text not null,
  discount_type public.discount_type not null,
  discount_value bigint not null check (discount_value > 0),
  start_date timestamptz,
  end_date timestamptz,
  usage_limit integer check (usage_limit is null or usage_limit > 0),
  used_count integer not null default 0,
  minimum_amount_minor bigint not null default 0,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (business_id, code)
);

create table public.audit_logs (
  id bigint generated always as identity primary key,
  business_id uuid references public.businesses(id) on delete set null,
  actor_id uuid references public.profiles(id) on delete set null,
  action text not null,
  entity text not null,
  entity_id text,
  old_data jsonb,
  new_data jsonb,
  created_at timestamptz not null default now()
);

create table public.media (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  staff_id uuid references public.staff_profiles(id) on delete cascade,
  kind public.media_kind not null,
  storage_path text not null,
  mime_type text not null,
  size_bytes bigint not null check (size_bytes >= 0),
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);

create table public.invites (
  id uuid primary key default gen_random_uuid(),
  business_id uuid not null references public.businesses(id) on delete cascade,
  email text not null,
  role public.member_role not null,
  token_hash text not null unique,
  expires_at timestamptz not null,
  accepted_at timestamptz,
  created_by uuid not null references public.profiles(id),
  created_at timestamptz not null default now()
);

create index business_members_user_idx on public.business_members(user_id, status);
create index branches_business_idx on public.branches(business_id) where deleted_at is null;
create index services_business_idx on public.services(business_id, is_active, online_booking_enabled);
create index staff_profiles_business_idx on public.staff_profiles(business_id, is_active);
create index staff_hours_lookup_idx on public.staff_working_hours(staff_id, branch_id, day_of_week);
create index schedule_exceptions_lookup_idx on public.schedule_exceptions(staff_id, branch_id, local_date);
create index customer_business_search_idx on public.customer_business_profiles(business_id, first_name, last_name);
create index customer_business_phone_idx on public.customer_business_profiles(business_id, phone);
create index customer_business_email_idx on public.customer_business_profiles(business_id, email);
create index appointments_business_start_idx on public.appointments(business_id, start_at);
create index appointments_staff_start_idx on public.appointments(staff_id, start_at);
create index appointments_branch_start_idx on public.appointments(branch_id, start_at);
create index appointments_customer_start_idx on public.appointments(customer_id, start_at desc);
create index notifications_user_unread_idx on public.notifications(user_id, created_at desc) where read_at is null;
create index audit_logs_business_created_idx on public.audit_logs(business_id, created_at desc);

create or replace function private.is_business_member(p_business_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.business_members bm
    where bm.business_id = p_business_id
      and bm.user_id = (select auth.uid())
      and bm.status = 'active'
  );
$$;

create or replace function private.has_business_role(p_business_id uuid, p_roles public.member_role[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.business_members bm
    where bm.business_id = p_business_id
      and bm.user_id = (select auth.uid())
      and bm.status = 'active'
      and bm.role = any(p_roles)
  );
$$;

revoke all on function private.is_business_member(uuid) from public;
revoke all on function private.has_business_role(uuid, public.member_role[]) from public;
grant execute on function private.is_business_member(uuid) to authenticated;
grant execute on function private.has_business_role(uuid, public.member_role[]) to authenticated;

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles(id, email, phone, first_name, last_name)
  values (
    new.id,
    new.email,
    new.phone,
    nullif(new.raw_user_meta_data->>'first_name', ''),
    nullif(new.raw_user_meta_data->>'last_name', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
revoke all on function private.handle_new_user() from public;

create trigger on_auth_user_created
after insert on auth.users
for each row execute procedure private.handle_new_user();

create or replace function public.create_business_onboarding(
  p_name text,
  p_slug text,
  p_category text,
  p_country text,
  p_city text,
  p_address text,
  p_phone text,
  p_timezone text,
  p_currency text
)
returns table (business_id uuid, branch_id uuid)
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_user uuid := (select auth.uid());
  v_business uuid;
  v_branch uuid;
begin
  if v_user is null then raise exception 'AUTH_REQUIRED'; end if;
  if p_currency not in ('CZK','EUR','USD','UAH','PLN','GBP') then raise exception 'INVALID_CURRENCY'; end if;

  insert into public.businesses(owner_id, name, slug, category, timezone, currency, phone)
  values (v_user, trim(p_name), lower(trim(p_slug)), trim(p_category), p_timezone, p_currency, p_phone)
  returning id into v_business;

  insert into public.business_members(business_id, user_id, role, status)
  values (v_business, v_user, 'business_owner', 'active');

  insert into public.branches(business_id, name, country, city, address, phone, timezone)
  values (v_business, trim(p_name), upper(trim(p_country)), trim(p_city), trim(p_address), p_phone, p_timezone)
  returning id into v_branch;

  insert into public.business_settings(business_id) values (v_business);

  return query select v_business, v_branch;
end;
$$;
revoke all on function public.create_business_onboarding(text,text,text,text,text,text,text,text,text) from public;
grant execute on function public.create_business_onboarding(text,text,text,text,text,text,text,text,text) to authenticated;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at before update on public.profiles for each row execute procedure private.set_updated_at();
create trigger businesses_updated_at before update on public.businesses for each row execute procedure private.set_updated_at();
create trigger services_updated_at before update on public.services for each row execute procedure private.set_updated_at();
create trigger customers_updated_at before update on public.customers for each row execute procedure private.set_updated_at();
create trigger customer_business_profiles_updated_at before update on public.customer_business_profiles for each row execute procedure private.set_updated_at();
create trigger appointments_updated_at before update on public.appointments for each row execute procedure private.set_updated_at();
create trigger notification_preferences_updated_at before update on public.notification_preferences for each row execute procedure private.set_updated_at();
create trigger business_settings_updated_at before update on public.business_settings for each row execute procedure private.set_updated_at();
create trigger business_subscriptions_updated_at before update on public.business_subscriptions for each row execute procedure private.set_updated_at();

-- RLS
alter table public.profiles enable row level security;
alter table public.businesses enable row level security;
alter table public.business_members enable row level security;
alter table public.branches enable row level security;
alter table public.service_categories enable row level security;
alter table public.services enable row level security;
alter table public.service_branches enable row level security;
alter table public.staff_profiles enable row level security;
alter table public.staff_branches enable row level security;
alter table public.staff_services enable row level security;
alter table public.business_hours enable row level security;
alter table public.staff_working_hours enable row level security;
alter table public.schedule_exceptions enable row level security;
alter table public.customers enable row level security;
alter table public.customer_business_profiles enable row level security;
alter table public.appointments enable row level security;
alter table public.appointment_services enable row level security;
alter table public.appointment_status_history enable row level security;
alter table public.payments enable row level security;
alter table public.reviews enable row level security;
alter table public.favorites enable row level security;
alter table public.notifications enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.business_settings enable row level security;
alter table public.subscription_plans enable row level security;
alter table public.business_subscriptions enable row level security;
alter table public.promo_codes enable row level security;
alter table public.audit_logs enable row level security;
alter table public.media enable row level security;
alter table public.invites enable row level security;

create policy profiles_self_select on public.profiles for select to authenticated using ((select auth.uid()) = id);
create policy profiles_self_insert on public.profiles for insert to authenticated with check ((select auth.uid()) = id);
create policy profiles_self_update on public.profiles for update to authenticated using ((select auth.uid()) = id) with check ((select auth.uid()) = id);

create policy businesses_public_read on public.businesses for select to anon, authenticated
using (status in ('trial','active') and deleted_at is null);
create policy businesses_owner_insert on public.businesses for insert to authenticated
with check ((select auth.uid()) = owner_id);
create policy businesses_management_update on public.businesses for update to authenticated
using ((select private.has_business_role(id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(id, array['business_owner','business_admin']::public.member_role[])));

create policy business_members_member_read on public.business_members for select to authenticated
using ((select private.is_business_member(business_id)));
create policy business_members_owner_insert on public.business_members for insert to authenticated
with check (
  (role = 'business_owner' and user_id = (select auth.uid()) and exists (
    select 1 from public.businesses b where b.id = business_id and b.owner_id = (select auth.uid())
  ))
  or (select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[]))
);
create policy business_members_management_update on public.business_members for update to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy branches_public_read on public.branches for select to anon, authenticated
using (is_active and deleted_at is null and exists (
  select 1 from public.businesses b where b.id = business_id and b.status in ('trial','active') and b.deleted_at is null
));
create policy branches_manage on public.branches for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy categories_public_read on public.service_categories for select to anon, authenticated using (is_active);
create policy categories_manage on public.service_categories for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy services_public_read on public.services for select to anon, authenticated
using (is_active and online_booking_enabled and deleted_at is null);
create policy services_manage on public.services for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy service_branches_public_read on public.service_branches for select to anon, authenticated using (is_active);
create policy service_branches_manage on public.service_branches for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy staff_public_read on public.staff_profiles for select to anon, authenticated
using (is_active and is_bookable and deleted_at is null);
create policy staff_manage on public.staff_profiles for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy staff_branches_public_read on public.staff_branches for select to anon, authenticated using (is_active);
create policy staff_branches_manage on public.staff_branches for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy staff_services_public_read on public.staff_services for select to anon, authenticated using (is_active);
create policy staff_services_manage on public.staff_services for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy business_hours_public_read on public.business_hours for select to anon, authenticated using (true);
create policy business_hours_manage on public.business_hours for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy staff_hours_member_read on public.staff_working_hours for select to authenticated using ((select private.is_business_member(business_id)));
create policy staff_hours_manage on public.staff_working_hours for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy exceptions_member_read on public.schedule_exceptions for select to authenticated using ((select private.is_business_member(business_id)));
create policy exceptions_manage on public.schedule_exceptions for all to authenticated
using ((select private.is_business_member(business_id)))
with check ((select private.is_business_member(business_id)));

create policy customers_self_read on public.customers for select to authenticated using (profile_id = (select auth.uid()));
create policy customers_self_update on public.customers for update to authenticated using (profile_id = (select auth.uid())) with check (profile_id = (select auth.uid()));

create policy customer_business_member_read on public.customer_business_profiles for select to authenticated using ((select private.is_business_member(business_id)));
create policy customer_business_member_write on public.customer_business_profiles for all to authenticated
using ((select private.is_business_member(business_id)))
with check ((select private.is_business_member(business_id)));

create policy appointments_business_read on public.appointments for select to authenticated using ((select private.is_business_member(business_id)));
create policy appointments_customer_read on public.appointments for select to authenticated using (
  exists (
    select 1
    from public.customer_business_profiles cbp
    join public.customers c on c.id = cbp.customer_id
    where cbp.id = customer_id and c.profile_id = (select auth.uid())
  )
);
create policy appointments_business_write on public.appointments for all to authenticated
using ((select private.is_business_member(business_id)))
with check ((select private.is_business_member(business_id)));

create policy appointment_services_business_read on public.appointment_services for select to authenticated using ((select private.is_business_member(business_id)));
create policy appointment_services_business_write on public.appointment_services for all to authenticated
using ((select private.is_business_member(business_id)))
with check ((select private.is_business_member(business_id)));

create policy status_history_business_read on public.appointment_status_history for select to authenticated using ((select private.is_business_member(business_id)));
create policy status_history_business_insert on public.appointment_status_history for insert to authenticated with check ((select private.is_business_member(business_id)));

create policy payments_business_read on public.payments for select to authenticated using ((select private.is_business_member(business_id)));
create policy payments_business_write on public.payments for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin','receptionist']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin','receptionist']::public.member_role[])));

create policy reviews_public_read on public.reviews for select to anon, authenticated using (is_approved);
create policy reviews_customer_insert on public.reviews for insert to authenticated with check (
  exists (
    select 1
    from public.appointments a
    join public.customer_business_profiles cbp on cbp.id = a.customer_id
    join public.customers c on c.id = cbp.customer_id
    where a.id = appointment_id
      and a.business_id = business_id
      and a.status = 'completed'
      and c.profile_id = (select auth.uid())
  )
);
create policy reviews_business_update on public.reviews for update to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy favorites_self_all on public.favorites for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy notifications_self_read on public.notifications for select to authenticated using (user_id = (select auth.uid()));
create policy notifications_self_update on public.notifications for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy notification_preferences_self_all on public.notification_preferences for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

create policy business_settings_member_read on public.business_settings for select to authenticated using ((select private.is_business_member(business_id)));
create policy business_settings_manage on public.business_settings for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy plans_public_read on public.subscription_plans for select to anon, authenticated using (is_active);
create policy subscriptions_owner_read on public.business_subscriptions for select to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy promo_member_read on public.promo_codes for select to authenticated using ((select private.is_business_member(business_id)));
create policy promo_manage on public.promo_codes for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy audit_owner_read on public.audit_logs for select to authenticated
using (business_id is not null and (select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy media_public_read on public.media for select to anon, authenticated using (true);
create policy media_manage on public.media for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

create policy invites_manage on public.invites for all to authenticated
using ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])))
with check ((select private.has_business_role(business_id, array['business_owner','business_admin']::public.member_role[])));

-- Explicit Data API grants. RLS still controls rows.
grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.businesses to authenticated;
grant select on public.businesses to anon;
grant select, insert, update, delete on public.business_members to authenticated;
grant select, insert, update, delete on public.branches, public.service_categories, public.services, public.service_branches, public.staff_profiles, public.staff_branches, public.staff_services, public.business_hours, public.staff_working_hours, public.schedule_exceptions to authenticated;
grant select on public.branches, public.service_categories, public.services, public.service_branches, public.staff_profiles, public.staff_branches, public.staff_services, public.business_hours to anon;
grant select, update on public.customers to authenticated;
grant select, insert, update, delete on public.customer_business_profiles, public.appointments, public.appointment_services, public.appointment_status_history, public.payments to authenticated;
grant select, insert, update on public.reviews to authenticated;
grant select on public.reviews to anon;
grant select, insert, update, delete on public.favorites to authenticated;
grant select, update on public.notifications to authenticated;
grant select, insert, update, delete on public.notification_preferences to authenticated;
grant select, insert, update, delete on public.business_settings to authenticated;
grant select on public.subscription_plans to anon, authenticated;
grant select on public.business_subscriptions to authenticated;
grant select, insert, update, delete on public.promo_codes to authenticated;
grant select on public.audit_logs to authenticated;
grant select, insert, update, delete on public.media to authenticated;
grant select on public.media to anon;
grant select, insert, update, delete on public.invites to authenticated;

insert into public.subscription_plans(code, name, price_minor, currency, staff_limit, branch_limit, features)
values
  ('free', 'Free', 0, 'EUR', 1, 1, '{"booking":true,"crm":false,"analytics":"basic"}'),
  ('basic', 'Basic', 0, 'EUR', 5, 1, '{"booking":true,"crm":true,"analytics":"basic"}'),
  ('pro', 'Pro', 0, 'EUR', null, null, '{"booking":true,"crm":true,"analytics":"advanced","multi_branch":true}')
on conflict (code) do nothing;
