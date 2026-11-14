-- OPTIONAL BACKEND SCHEMA DRAFT ONLY.
-- Review against the currently supported Supabase/Postgres version before applying.
-- Do not run in production until tested with RLS cross-user denial cases.
create extension if not exists pgcrypto;

create table if not exists public.ev_vehicles (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('car','scooter')),
  brand text not null,
  model text not null,
  battery_kwh numeric(10,3) not null check (battery_kwh > 0),
  odometer_km numeric(12,2) not null default 0 check (odometer_km >= 0),
  version bigint not null default 1 check (version > 0),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create unique index if not exists ev_vehicles_id_owner_unique on public.ev_vehicles(id,owner_id);

create table if not exists public.ev_records (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  vehicle_id uuid not null references public.ev_vehicles(id) on delete cascade,
  kind text not null check (kind in ('charging','trip','expense','service','finance','issue')),
  title text not null,
  amount_minor bigint not null default 0 check (amount_minor >= 0),
  currency_code char(3) not null default 'INR',
  occurred_at timestamptz not null,
  details jsonb not null default '{}'::jsonb,
  version bigint not null default 1 check (version > 0),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  constraint ev_records_vehicle_owner_fk foreign key (vehicle_id, owner_id)
    references public.ev_vehicles(id, owner_id)
);
create index if not exists ev_vehicles_owner_updated_idx on public.ev_vehicles(owner_id,updated_at);
create index if not exists ev_records_owner_updated_idx on public.ev_records(owner_id,updated_at);

alter table public.ev_vehicles enable row level security;
alter table public.ev_records enable row level security;

create policy "ev_vehicles_read_own" on public.ev_vehicles
  for select to authenticated using ((select auth.uid()) = owner_id);
create policy "ev_vehicles_insert_own" on public.ev_vehicles
  for insert to authenticated with check ((select auth.uid()) = owner_id);
create policy "ev_vehicles_update_own" on public.ev_vehicles
  for update to authenticated using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);
create policy "ev_vehicles_delete_own" on public.ev_vehicles
  for delete to authenticated using ((select auth.uid()) = owner_id);

create policy "ev_records_read_own" on public.ev_records
  for select to authenticated using ((select auth.uid()) = owner_id);
create policy "ev_records_insert_own" on public.ev_records
  for insert to authenticated with check ((select auth.uid()) = owner_id);
create policy "ev_records_update_own" on public.ev_records
  for update to authenticated using ((select auth.uid()) = owner_id)
  with check ((select auth.uid()) = owner_id);
create policy "ev_records_delete_own" on public.ev_records
  for delete to authenticated using ((select auth.uid()) = owner_id);

-- Access to Data API also requires grants/settings, separate from RLS.
-- Do not add broad public grants or storage policies without review.
