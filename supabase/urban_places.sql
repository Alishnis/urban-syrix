create table if not exists public.urban_places (
  id text primary key,
  created_by uuid not null references auth.users (id) on delete cascade,
  name text not null,
  type text not null check (type in ('building', 'construction', 'road', 'incident')),
  incident_subtype text,
  detection_model text,
  detection_preview_url text,
  address text not null,
  description text not null,
  latitude double precision not null,
  longitude double precision not null,
  developer text not null,
  traffic_risk integer not null,
  co2_footprint integer not null,
  green_coverage integer not null,
  base_scores jsonb not null default '{}'::jsonb,
  issues jsonb not null default '[]'::jsonb,
  reviews jsonb not null default '[]'::jsonb,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.urban_places
add column if not exists incident_subtype text;

alter table public.urban_places
add column if not exists detection_model text;

alter table public.urban_places
add column if not exists detection_preview_url text;

alter table public.urban_places enable row level security;

grant usage on schema public to authenticated;
grant select, insert, update, delete on public.urban_places to authenticated;

drop policy if exists "Authenticated users can read urban places" on public.urban_places;
create policy "Authenticated users can read urban places"
on public.urban_places
for select
to authenticated
using (true);

drop policy if exists "Users can insert own urban places" on public.urban_places;
create policy "Users can insert own urban places"
on public.urban_places
for insert
to authenticated
with check (auth.uid() = created_by);

drop policy if exists "Users can update own urban places" on public.urban_places;
create policy "Users can update own urban places"
on public.urban_places
for update
to authenticated
using (auth.uid() = created_by)
with check (auth.uid() = created_by);

drop policy if exists "Users can delete own urban places" on public.urban_places;
create policy "Users can delete own urban places"
on public.urban_places
for delete
to authenticated
using (auth.uid() = created_by);
