create table if not exists public.urban_place_reviews (
  id text primary key,
  place_id text not null,
  author_id uuid not null references auth.users (id) on delete cascade,
  author_name text not null,
  message text not null,
  category text not null check (
    category in (
      'mobility',
      'environment',
      'resources',
      'transparency',
      'inclusivity',
      'safety'
    )
  ),
  sentiment integer not null default 0,
  verified_inclusivity boolean not null default false,
  score_impact jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default timezone('utc', now())
);

alter table public.urban_place_reviews
add column if not exists score_impact jsonb not null default '{}'::jsonb;

alter table public.urban_place_reviews enable row level security;

grant usage on schema public to authenticated;
grant select, insert on public.urban_place_reviews to authenticated;

drop policy if exists "Authenticated users can read urban place reviews" on public.urban_place_reviews;
create policy "Authenticated users can read urban place reviews"
on public.urban_place_reviews
for select
to authenticated
using (true);

drop policy if exists "Users can insert own urban place reviews" on public.urban_place_reviews;
create policy "Users can insert own urban place reviews"
on public.urban_place_reviews
for insert
to authenticated
with check (auth.uid() = author_id);
