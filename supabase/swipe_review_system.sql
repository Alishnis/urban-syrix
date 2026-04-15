create extension if not exists "pgcrypto";

create table if not exists public.organization_reputation (
  organization_id text primary key references public.urban_places (id) on delete cascade,
  approved_reviews_count integer not null default 0,
  average_rating numeric(4, 2) not null default 0,
  reputation_score numeric(5, 2) not null default 0,
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.review_swipes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  organization_id text not null references public.urban_places (id) on delete cascade,
  direction text not null check (direction in ('right', 'left')),
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.swipe_reviews (
  id uuid primary key default gen_random_uuid(),
  swipe_id uuid not null references public.review_swipes (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  organization_id text not null references public.urban_places (id) on delete cascade,
  category text not null default 'safety',
  summary text not null check (char_length(trim(summary)) >= 8),
  details text not null check (char_length(trim(details)) >= 16),
  rating integer not null check (rating between 1 and 5),
  media_urls text[] not null default '{}',
  moderation_status text not null default 'pending' check (
    moderation_status in ('pending', 'approved', 'rejected', 'published')
  ),
  moderation_reason text,
  moderation_note text,
  moderated_by uuid references auth.users (id) on delete set null,
  moderated_at timestamptz,
  published_at timestamptz,
  public_visible boolean not null default false,
  created_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.reward_ledger (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  milestone integer not null check (milestone > 0),
  approved_reviews_count integer not null,
  reward_type text not null default 'gift_card_magnum_cash_and_carry',
  reward_status text not null default 'issued' check (reward_status in ('issued', 'claimed', 'expired')),
  issued_at timestamptz not null default timezone('utc', now()),
  unique (user_id, milestone)
);

create index if not exists idx_review_swipes_user_created
on public.review_swipes (user_id, created_at desc);

create index if not exists idx_swipe_reviews_status_created
on public.swipe_reviews (moderation_status, created_at asc);

create index if not exists idx_swipe_reviews_org_published
on public.swipe_reviews (organization_id, public_visible, published_at desc);

create index if not exists idx_reward_ledger_user_milestone
on public.reward_ledger (user_id, milestone desc);

alter table public.review_swipes enable row level security;
alter table public.swipe_reviews enable row level security;
alter table public.reward_ledger enable row level security;
alter table public.organization_reputation enable row level security;

grant usage on schema public to authenticated;
grant select, insert on public.review_swipes to authenticated;
grant select, insert on public.swipe_reviews to authenticated;
grant select on public.reward_ledger to authenticated;
grant select on public.organization_reputation to authenticated;

drop policy if exists "Users can insert their swipes" on public.review_swipes;
create policy "Users can insert their swipes"
on public.review_swipes
for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can read own swipes" on public.review_swipes;
create policy "Users can read own swipes"
on public.review_swipes
for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "Users can insert own swipe reviews" on public.swipe_reviews;
create policy "Users can insert own swipe reviews"
on public.swipe_reviews
for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "Users can read own and published reviews" on public.swipe_reviews;
create policy "Users can read own and published reviews"
on public.swipe_reviews
for select to authenticated
using (auth.uid() = user_id or public_visible = true);

drop policy if exists "Admins can read all swipe reviews" on public.swipe_reviews;
create policy "Admins can read all swipe reviews"
on public.swipe_reviews
for select to authenticated
using (exists (
  select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'
));

drop policy if exists "Admins can update moderation status" on public.swipe_reviews;
create policy "Admins can update moderation status"
on public.swipe_reviews
for update to authenticated
using (exists (
  select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'
))
with check (exists (
  select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'
));

drop policy if exists "Users can read own rewards" on public.reward_ledger;
create policy "Users can read own rewards"
on public.reward_ledger
for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "Admins can read all rewards" on public.reward_ledger;
create policy "Admins can read all rewards"
on public.reward_ledger
for select to authenticated
using (exists (
  select 1 from public.profiles p where p.id = auth.uid() and p.role = 'admin'
));

drop policy if exists "Published reputation is readable" on public.organization_reputation;
create policy "Published reputation is readable"
on public.organization_reputation
for select to authenticated
using (true);

create or replace function public.user_is_admin(user_id uuid)
returns boolean
language sql
stable
as $$
  select exists (
    select 1 from public.profiles p where p.id = user_id and p.role = 'admin'
  );
$$;

create or replace function public.submit_swipe_review(
  p_organization_id text,
  p_direction text,
  p_summary text,
  p_details text,
  p_category text,
  p_rating integer,
  p_media_urls text[]
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_swipe_id uuid;
  v_review_id uuid;
  v_recent_count integer;
begin
  if v_user_id is null then
    raise exception 'Authentication required';
  end if;

  if p_direction not in ('right', 'left') then
    raise exception 'Invalid swipe direction';
  end if;

  select count(*)
  into v_recent_count
  from public.review_swipes
  where user_id = v_user_id
    and created_at >= timezone('utc', now()) - interval '1 hour';

  if v_recent_count >= 80 then
    raise exception 'Rate limit reached. Please wait before submitting again.';
  end if;

  insert into public.review_swipes (user_id, organization_id, direction)
  values (v_user_id, p_organization_id, p_direction)
  returning id into v_swipe_id;

  insert into public.swipe_reviews (
    swipe_id,
    user_id,
    organization_id,
    category,
    summary,
    details,
    rating,
    media_urls
  )
  values (
    v_swipe_id,
    v_user_id,
    p_organization_id,
    coalesce(nullif(trim(p_category), ''), 'safety'),
    p_summary,
    p_details,
    p_rating,
    coalesce(p_media_urls, '{}')
  )
  returning id into v_review_id;

  return v_review_id;
end;
$$;

create or replace function public.moderate_swipe_review(
  p_review_id uuid,
  p_decision text,
  p_reason text,
  p_note text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  v_admin_id uuid := auth.uid();
  v_review public.swipe_reviews%rowtype;
  v_user_approved_count integer;
  v_milestone integer;
begin
  if v_admin_id is null or not public.user_is_admin(v_admin_id) then
    raise exception 'Admin access required';
  end if;

  if p_decision not in ('approved', 'rejected') then
    raise exception 'Invalid moderation decision';
  end if;

  select *
  into v_review
  from public.swipe_reviews
  where id = p_review_id
  for update;

  if not found then
    raise exception 'Review not found';
  end if;

  if v_review.moderation_status <> 'pending' then
    return;
  end if;

  update public.swipe_reviews
  set moderation_status = case when p_decision = 'approved' then 'published' else 'rejected' end,
      moderation_reason = p_reason,
      moderation_note = p_note,
      moderated_by = v_admin_id,
      moderated_at = timezone('utc', now()),
      public_visible = (p_decision = 'approved'),
      published_at = case when p_decision = 'approved' then timezone('utc', now()) else null end
  where id = p_review_id;

  if p_decision = 'approved' then
    insert into public.organization_reputation (
      organization_id,
      approved_reviews_count,
      average_rating,
      reputation_score,
      updated_at
    )
    values (
      v_review.organization_id,
      1,
      v_review.rating,
      v_review.rating * 20,
      timezone('utc', now())
    )
    on conflict (organization_id) do update
    set approved_reviews_count = public.organization_reputation.approved_reviews_count + 1,
        average_rating = (
          (public.organization_reputation.average_rating * public.organization_reputation.approved_reviews_count + excluded.average_rating) /
          (public.organization_reputation.approved_reviews_count + 1)
        ),
        reputation_score = (
          (
            (public.organization_reputation.average_rating * public.organization_reputation.approved_reviews_count + excluded.average_rating) /
            (public.organization_reputation.approved_reviews_count + 1)
          ) * 20
        ),
        updated_at = timezone('utc', now());

    select count(*)
    into v_user_approved_count
    from public.swipe_reviews
    where user_id = v_review.user_id
      and moderation_status in ('approved', 'published');

    v_milestone := floor(v_user_approved_count / 1000);
    if v_milestone > 0 then
      insert into public.reward_ledger (
        user_id,
        milestone,
        approved_reviews_count
      )
      values (
        v_review.user_id,
        v_milestone,
        v_user_approved_count
      )
      on conflict (user_id, milestone) do nothing;
    end if;
  end if;
end;
$$;

grant execute on function public.submit_swipe_review(
  text, text, text, text, text, integer, text[]
) to authenticated;

grant execute on function public.moderate_swipe_review(
  uuid, text, text, text
) to authenticated;
