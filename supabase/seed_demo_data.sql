-- Demo seed data for urban_places / urban_place_reviews (English content).
-- Run this AFTER the cleanup truncate, in the Supabase SQL Editor.
--
-- IMPORTANT: replace the email below with the account that should "own"
-- these demo records (must already exist in auth.users, e.g. your admin
-- account). All rows below resolve created_by/author_id from that email.

do $$
declare
  v_user_id uuid;
begin
  select id into v_user_id
  from auth.users
  where email = 'dilnaz.romankul@zimran.io'  -- <-- change if needed
  limit 1;

  if v_user_id is null then
    raise exception 'No auth.users row found for that email. Update the email in this script first.';
  end if;

  -- ── Urban places ─────────────────────────────────────────────────────
  insert into public.urban_places (
    id, created_by, name, type, incident_subtype,
    photo_url, detection_model, detection_preview_url,
    address, description, latitude, longitude, developer,
    traffic_risk, co2_footprint, green_coverage,
    base_scores, issues, reviews
  ) values
  (
    'place_pipe_district7', v_user_id, 'Pipe Replacement — District 7', 'construction', null,
    null, null, null,
    '14 Abay Ave, District 7', 'Scheduled utility maintenance with low traffic impact.',
    43.238293, 76.945465, 'CityWorks Infrastructure LLP',
    2, 18, 55,
    '{"mobility": 78, "environment": 65, "resources": 70, "transparency": 82, "inclusivity": 60, "safety": 75}'::jsonb,
    '[{"title": "Temporary lane closure", "category": "mobility", "days_open": 5, "severity": 2}]'::jsonb,
    '[]'::jsonb
  ),
  (
    'place_gas_leak_response', v_user_id, 'Gas Leak Response', 'incident', 'other',
    null, 'Manual Incident Report', null,
    'Corner of Dostyk Ave & Kabanbay Batyr St', 'Emergency services deployed with an active exclusion perimeter.',
    43.235100, 76.951200, 'Municipal Emergency Services',
    8, 5, 40,
    '{"mobility": 40, "environment": 55, "resources": 60, "transparency": 70, "inclusivity": 65, "safety": 30}'::jsonb,
    '[{"title": "Active exclusion perimeter", "category": "safety", "days_open": 1, "severity": 5}]'::jsonb,
    '[]'::jsonb
  ),
  (
    'place_grid_modernization', v_user_id, 'Grid Modernization', 'construction', null,
    null, null, null,
    '7 Al-Farabi Ave', 'Substation upgrade in progress with short planned outages.',
    43.221500, 76.909800, 'Zharyq Power Networks',
    3, 22, 48,
    '{"mobility": 80, "environment": 58, "resources": 52, "transparency": 75, "inclusivity": 62, "safety": 72}'::jsonb,
    '[{"title": "Planned short outages", "category": "resources", "days_open": 20, "severity": 2}]'::jsonb,
    '[]'::jsonb
  ),
  (
    'place_riverside_towers', v_user_id, 'Riverside Towers', 'building', null,
    null, null, null,
    '22 Seifullin St', 'Mixed-use residential complex with rooftop green space.',
    43.255600, 76.928900, 'Nurly Development Group',
    4, 35, 68,
    '{"mobility": 70, "environment": 74, "resources": 66, "transparency": 60, "inclusivity": 72, "safety": 80}'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb
  ),
  (
    'place_almaty_ring_road', v_user_id, 'Almaty Ring Road Extension', 'road', null,
    null, null, null,
    'BAKAD Section 3', 'New ring-road segment easing cross-town traffic.',
    43.198700, 76.851200, 'Kazakhstan Highway Authority',
    5, 40, 30,
    '{"mobility": 88, "environment": 45, "resources": 58, "transparency": 68, "inclusivity": 55, "safety": 70}'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb
  ),
  (
    'place_traffic_accident_report', v_user_id, 'Traffic Accident — Furmanov St', 'incident', 'car_accident',
    null, 'YOLOv8 Traffic Accident Detection', null,
    'Furmanov St, near Gogol St intersection', 'Two-vehicle collision reported and confirmed via automated detection.',
    43.256900, 76.945100, 'Municipal Emergency Services',
    9, 3, 35,
    '{"mobility": 35, "environment": 60, "resources": 58, "transparency": 70, "inclusivity": 60, "safety": 25}'::jsonb,
    '[{"title": "Lane blocked by collision", "category": "safety", "days_open": 1, "severity": 4}]'::jsonb,
    '[]'::jsonb
  )
  on conflict (id) do nothing;

  -- ── Reviews ──────────────────────────────────────────────────────────
  insert into public.urban_place_reviews (
    id, place_id, author_id, author_name, message, category,
    sentiment, verified_inclusivity, score_impact
  ) values
  (
    'review_riverside_towers_1', 'place_riverside_towers', v_user_id, 'Aigerim K.',
    'The rooftop garden is a great addition, but the entrance ramp needs better signage for wheelchair access.',
    'inclusivity', 1, false,
    '{"mobility": 0, "environment": 0, "resources": 0, "transparency": 0, "inclusivity": 3, "safety": 0}'::jsonb
  ),
  (
    'review_ring_road_1', 'place_almaty_ring_road', v_user_id, 'Daniyar S.',
    'Traffic on the old route has dropped noticeably since this section opened.',
    'mobility', 1, false,
    '{"mobility": 5, "environment": -1, "resources": 0, "transparency": 0, "inclusivity": 0, "safety": 1}'::jsonb
  ),
  (
    'review_grid_modernization_1', 'place_grid_modernization', v_user_id, 'Madina T.',
    'Planned outage notices were sent with enough notice, appreciate the transparency.',
    'transparency', 1, false,
    '{"mobility": 0, "environment": 0, "resources": 1, "transparency": 4, "inclusivity": 0, "safety": 0}'::jsonb
  )
  on conflict (id) do nothing;
end $$;
