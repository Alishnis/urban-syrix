-- Allows unauthenticated (anon) clients to read the public map data,
-- so visitors can browse urban_places/urban_place_reviews before signing in.
-- Run this in the Supabase SQL editor after the earlier setup scripts.

grant usage on schema public to anon;
grant select on public.urban_places to anon;
grant select on public.urban_place_reviews to anon;

drop policy if exists "Anonymous users can read urban places" on public.urban_places;
create policy "Anonymous users can read urban places"
on public.urban_places for select to anon using (true);

drop policy if exists "Anonymous users can read urban place reviews" on public.urban_place_reviews;
create policy "Anonymous users can read urban place reviews"
on public.urban_place_reviews for select to anon using (true);
