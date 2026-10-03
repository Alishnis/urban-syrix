-- Wipes all existing urban_places / urban_place_reviews rows and replaces
-- them with a polished demo data set (real photos, written descriptions,
-- and reviews) spread across different parts of the city, for
-- portfolio/demo purposes.
--
-- Run this in the Supabase SQL Editor. Safe to re-run — it always clears
-- the two tables first, then re-inserts a fixed, known set of rows.
--
-- IMPORTANT: replace the email below with the account that should "own"
-- these demo records (must already exist in auth.users).

delete from public.urban_place_reviews;
delete from public.urban_places;

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

  -- ── Urban places (spread across different districts/coordinates) ────
  insert into public.urban_places (
    id, created_by, name, type, incident_subtype,
    photo_url, detection_model, detection_preview_url,
    address, description, latitude, longitude, developer,
    traffic_risk, co2_footprint, green_coverage,
    base_scores, issues, reviews
  ) values
  -- Buildings
  (
    'place_riverside_residences', v_user_id, 'Riverside Residences', 'building', null,
    'https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=1200&q=80', null, null,
    '22 Dostyk Ave, District 3',
    '14-story mixed-use residential tower completed in 2025. Ground-floor retail, '
    'underground parking for 180 cars, and a rooftop solar array covering 30% of '
    'common-area electricity load. Fully occupied since Q3.',
    43.239120, 76.948870, 'Riverside Development Group',
    3, 22, 48,
    '{"mobility": 74, "environment": 70, "resources": 68, "transparency": 80, "inclusivity": 72, "safety": 85}'::jsonb,
    '[]'::jsonb, '[]'::jsonb
  ),
  (
    'place_almaly_tower', v_user_id, 'Almaly Business Tower', 'building', null,
    'https://images.unsplash.com/photo-1512917774080-9991f1c4c750?w=1200&q=80', null, null,
    '48 Gogol St, Almaly District',
    '22-floor Class A office tower, LEED Gold certified. Shared coworking floor '
    'on level 3, EV charging in the basement garage, and a public plaza with '
    'seating open to pedestrians at street level.',
    43.258760, 76.929340, 'Almaly Urban Partners',
    2, 19, 44,
    '{"mobility": 70, "environment": 75, "resources": 66, "transparency": 78, "inclusivity": 68, "safety": 82}'::jsonb,
    '[]'::jsonb, '[]'::jsonb
  ),
  (
    'place_medeu_apartments', v_user_id, 'Medeu Foothill Apartments', 'building', null,
    'https://images.unsplash.com/photo-1558036117-15d82a90b9b1?w=1200&q=80', null, null,
    '7 Kosmonavtov St, Medeu District',
    'Low-rise apartment complex (6 buildings, 4 floors each) at the foot of the '
    'Medeu hills. Known for mountain views and a shared courtyard with a '
    'playground; popular with young families.',
    43.168230, 77.054610, 'Medeu Residential Group',
    2, 14, 62,
    '{"mobility": 58, "environment": 80, "resources": 70, "transparency": 65, "inclusivity": 74, "safety": 78}'::jsonb,
    '[]'::jsonb, '[]'::jsonb
  ),
  -- Construction
  (
    'place_district7_construction', v_user_id, 'New Residential Complex — District 7', 'construction', null,
    'https://images.unsplash.com/photo-1541888946425-d81bb19240f5?w=1200&q=80', null, null,
    '14 Abay Ave, District 7',
    '12-story residential complex under construction. Expected completion Q2 2027. '
    'Builder permits verified with the municipal planning office; two active cranes '
    'on site, daytime-only working hours (07:00-19:00) to limit noise impact.',
    43.238293, 76.945465, 'CityWorks Infrastructure LLP',
    4, 30, 40,
    '{"mobility": 60, "environment": 55, "resources": 62, "transparency": 76, "inclusivity": 58, "safety": 70}'::jsonb,
    '[{"title": "Temporary lane closure on Abay Ave", "category": "mobility", "days_open": 12, "severity": 2}]'::jsonb,
    '[]'::jsonb
  ),
  (
    'place_nauryzbay_mall', v_user_id, 'Nauryzbay Retail & Transit Hub', 'construction', null,
    'https://images.unsplash.com/photo-1577086664693-894d8405334a?w=1200&q=80', null, null,
    '103 Rayymbek Ave, Nauryzbay District',
    'Mixed retail and bus-interchange development, ground broken six months ago. '
    'Includes a covered transit platform for four bus lines and 2,400 m² of '
    'retail space. Community consultation sessions held monthly.',
    43.291450, 76.851220, 'Nauryzbay Urban Development',
    5, 28, 33,
    '{"mobility": 52, "environment": 50, "resources": 58, "transparency": 82, "inclusivity": 64, "safety": 68}'::jsonb,
    '[{"title": "Partial sidewalk closure on Rayymbek Ave", "category": "mobility", "days_open": 20, "severity": 2}]'::jsonb,
    '[]'::jsonb
  ),
  -- Roads
  (
    'place_dostyk_road_works', v_user_id, 'Dostyk Avenue Resurfacing', 'road', null,
    'https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=1200&q=80', null, null,
    'Dostyk Ave, between Kabanbay Batyr St and Satpayev St',
    'Full-depth asphalt resurfacing and new drainage channels along a 1.2 km stretch '
    'of Dostyk Avenue. One lane in each direction remains open; completion targeted '
    'before the winter season.',
    43.235870, 76.951900, 'Almaty City Roads Department',
    6, 15, 35,
    '{"mobility": 45, "environment": 58, "resources": 64, "transparency": 70, "inclusivity": 55, "safety": 60}'::jsonb,
    '[{"title": "Single-lane traffic, both directions", "category": "mobility", "days_open": 8, "severity": 3}]'::jsonb,
    '[]'::jsonb
  ),
  (
    'place_al_farabi_bridge', v_user_id, 'Al-Farabi Overpass Repair', 'road', null,
    'https://images.unsplash.com/photo-1545558014-8692077e9b5c?w=1200&q=80', null, null,
    'Al-Farabi Ave overpass, near Dostyk junction',
    'Structural inspection revealed surface cracking on the overpass deck. '
    'Emergency repair crews resurfacing and reinforcing a 200 m section; '
    'overnight closures only (23:00-05:00) to minimize disruption.',
    43.202640, 76.909870, 'Almaty City Roads Department',
    5, 12, 38,
    '{"mobility": 50, "environment": 60, "resources": 62, "transparency": 74, "inclusivity": 58, "safety": 64}'::jsonb,
    '[{"title": "Overnight lane closures", "category": "mobility", "days_open": 5, "severity": 2}]'::jsonb,
    '[]'::jsonb
  ),
  -- Incidents
  (
    'place_warehouse_fire', v_user_id, 'Warehouse Fire — Industrial Zone', 'incident', 'fire',
    'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?w=1200&q=80',
    'YOLOv8 Fire Detection', 'https://images.unsplash.com/photo-1601584115197-04ecc0da31d7?w=1200&q=80',
    'Industrial Zone, Block 4, Warehouse 12',
    'Fire detected by on-site camera and confirmed by the YOLOv8 detection model. '
    'Fire department on scene; surrounding roads closed within a 300 m radius. '
    'No injuries reported; investigation into cause is ongoing.',
    43.221450, 76.889310, 'Municipal Emergency Services',
    9, 45, 20,
    '{"mobility": 30, "environment": 35, "resources": 50, "transparency": 68, "inclusivity": 55, "safety": 22}'::jsonb,
    '[{"title": "Active exclusion perimeter", "category": "safety", "days_open": 1, "severity": 5}]'::jsonb,
    '[]'::jsonb
  ),
  (
    'place_market_fire', v_user_id, 'Kitchen Fire — Green Bazaar Annex', 'incident', 'fire',
    'https://images.unsplash.com/photo-1587293852726-70cdb56c2866?w=1200&q=80',
    'YOLOv8 Fire Detection', 'https://images.unsplash.com/photo-1587293852726-70cdb56c2866?w=1200&q=80',
    'Green Bazaar Annex, Zhibek Zholy St',
    'Small kitchen fire in a food-court stall, contained before spreading to '
    'neighboring stalls. Market briefly evacuated as a precaution and reopened '
    'within two hours.',
    43.260130, 76.953280, 'Municipal Emergency Services',
    4, 20, 42,
    '{"mobility": 55, "environment": 48, "resources": 56, "transparency": 70, "inclusivity": 60, "safety": 45}'::jsonb,
    '[{"title": "Brief market evacuation", "category": "safety", "days_open": 0, "severity": 2}]'::jsonb,
    '[]'::jsonb
  ),
  (
    'place_intersection_collision', v_user_id, 'Multi-Vehicle Collision — Satpayev/Dostyk', 'incident', 'car_accident',
    'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=1200&q=80',
    'YOLOv8 Traffic Accident Detection', 'https://images.unsplash.com/photo-1600880292203-757bb62b4baf?w=1200&q=80',
    'Satpayev St & Dostyk Ave intersection',
    'Three-vehicle collision detected automatically from traffic camera footage. '
    'Minor injuries reported, ambulance dispatched. Two lanes blocked while the '
    'scene is cleared; safe-route planning automatically reroutes around this area.',
    43.236980, 76.950120, 'Traffic Police Department',
    8, 10, 30,
    '{"mobility": 35, "environment": 60, "resources": 58, "transparency": 72, "inclusivity": 60, "safety": 32}'::jsonb,
    '[{"title": "Two lanes blocked for cleanup", "category": "mobility", "days_open": 1, "severity": 4}]'::jsonb,
    '[]'::jsonb
  ),
  (
    'place_ring_road_rollover', v_user_id, 'Truck Rollover — Big Almaty Ring Road', 'incident', 'car_accident',
    'https://images.unsplash.com/photo-1587582423116-ec07293f0395?w=1200&q=80',
    'YOLOv8 Traffic Accident Detection', 'https://images.unsplash.com/photo-1587582423116-ec07293f0395?w=1200&q=80',
    'BAKAD Ring Road, km 14',
    'Cargo truck rollover blocking the outer lane of the ring road. Driver treated '
    'for minor injuries on-site. Cleanup crew estimates the lane will reopen '
    'within 3 hours; traffic is being diverted to the inner lane.',
    43.179540, 76.820450, 'Traffic Police Department',
    7, 18, 25,
    '{"mobility": 38, "environment": 50, "resources": 54, "transparency": 68, "inclusivity": 55, "safety": 40}'::jsonb,
    '[{"title": "Outer lane blocked", "category": "mobility", "days_open": 0, "severity": 3}]'::jsonb,
    '[]'::jsonb
  ),
  (
    'place_gas_leak_response', v_user_id, 'Gas Leak Response', 'incident', 'other',
    'https://images.unsplash.com/photo-1542401886-65d6c61db217?w=1200&q=80',
    'Manual Incident Report', 'https://images.unsplash.com/photo-1542401886-65d6c61db217?w=1200&q=80',
    'Corner of Dostyk Ave & Kabanbay Batyr St',
    'Residents reported a gas odor near a utility junction box. Emergency services '
    'deployed with an active exclusion perimeter while the leak is traced and sealed.',
    43.235100, 76.951200, 'Municipal Emergency Services',
    8, 5, 40,
    '{"mobility": 40, "environment": 55, "resources": 60, "transparency": 70, "inclusivity": 65, "safety": 30}'::jsonb,
    '[{"title": "Active exclusion perimeter", "category": "safety", "days_open": 1, "severity": 5}]'::jsonb,
    '[]'::jsonb
  ),
  (
    'place_flash_flood', v_user_id, 'Flash Flooding — Esentai Riverbank', 'incident', 'other',
    'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=1200&q=80',
    'Manual Incident Report', 'https://images.unsplash.com/photo-1621905251189-08b45d6a269e?w=1200&q=80',
    'Esentai River embankment, near Al-Farabi Ave',
    'Heavy rainfall overwhelmed a storm drain, flooding the riverside walking path '
    'and one traffic lane. Pumping crews on site; path expected to reopen once '
    'water recedes.',
    43.204870, 76.915630, 'Municipal Water Utility',
    5, 8, 58,
    '{"mobility": 48, "environment": 52, "resources": 55, "transparency": 66, "inclusivity": 60, "safety": 50}'::jsonb,
    '[{"title": "One lane flooded, path closed", "category": "safety", "days_open": 1, "severity": 3}]'::jsonb,
    '[]'::jsonb
  );

  -- ── Reviews ──────────────────────────────────────────────────────────
  insert into public.urban_place_reviews (
    id, place_id, author_id, author_name, message, category,
    sentiment, verified_inclusivity, score_impact, created_at
  ) values
  (
    'review_riverside_1', 'place_riverside_residences', v_user_id, 'Aidana K.',
    'Moved in three months ago — the solar rooftop noticeably lowers our common '
    'charges, and the ground-floor shops make the block feel alive again.',
    'environment', 2, true, '{"environment": 5, "inclusivity": 2}'::jsonb,
    timezone('utc', now()) - interval '14 days'
  ),
  (
    'review_riverside_2', 'place_riverside_residences', v_user_id, 'Marat T.',
    'Underground parking is well organized, but visitor spots fill up fast on weekends.',
    'mobility', 1, false, '{"mobility": 1}'::jsonb,
    timezone('utc', now()) - interval '6 days'
  ),
  (
    'review_almaly_1', 'place_almaly_tower', v_user_id, 'Yerlan M.',
    'The public plaza out front is genuinely usable — benches, shade, and it''s '
    'not fenced off like most office towers nearby.',
    'inclusivity', 2, true, '{"inclusivity": 3}'::jsonb,
    timezone('utc', now()) - interval '10 days'
  ),
  (
    'review_medeu_1', 'place_medeu_apartments', v_user_id, 'Zarina N.',
    'Quiet, green, and the playground is always maintained. Only downside is the '
    'bus to the city center runs just once an hour.',
    'mobility', -1, false, '{"mobility": -1, "environment": 2}'::jsonb,
    timezone('utc', now()) - interval '5 days'
  ),
  (
    'review_district7_1', 'place_district7_construction', v_user_id, 'Serik B.',
    'Noise is kept within the posted hours as promised, but dust on windy days is '
    'rough for the ground-floor units across the street.',
    'environment', -1, false, '{"environment": -2}'::jsonb,
    timezone('utc', now()) - interval '9 days'
  ),
  (
    'review_district7_2', 'place_district7_construction', v_user_id, 'Dana R.',
    'Appreciate that the permit documents are posted on-site and match what''s on '
    'the city portal — good transparency from this builder.',
    'transparency', 2, false, '{"transparency": 3}'::jsonb,
    timezone('utc', now()) - interval '3 days'
  ),
  (
    'review_nauryzbay_1', 'place_nauryzbay_mall', v_user_id, 'Bauyrzhan K.',
    'Attended the community session last month — they actually changed the bus '
    'platform layout based on feedback. Good to see.',
    'transparency', 2, false, '{"transparency": 3}'::jsonb,
    timezone('utc', now()) - interval '20 days'
  ),
  (
    'review_road_1', 'place_dostyk_road_works', v_user_id, 'Nurlan A.',
    'Commute time roughly doubled during rush hour this week because of the lane '
    'closure. Detour signage could be clearer at the Satpayev junction.',
    'mobility', -2, false, '{"mobility": -3}'::jsonb,
    timezone('utc', now()) - interval '4 days'
  ),
  (
    'review_bridge_1', 'place_al_farabi_bridge', v_user_id, 'Olzhas D.',
    'Good call doing this overnight only — barely noticed any disruption during '
    'the day.',
    'mobility', 1, false, '{"mobility": 1}'::jsonb,
    timezone('utc', now()) - interval '2 days'
  ),
  (
    'review_fire_1', 'place_warehouse_fire', v_user_id, 'Almas Zh.',
    'Saw the smoke from two blocks away — emergency crews arrived within minutes '
    'and the perimeter was well marked. Glad no one was hurt.',
    'safety', 1, false, '{"safety": -2}'::jsonb,
    timezone('utc', now()) - interval '1 days'
  ),
  (
    'review_market_fire_1', 'place_market_fire', v_user_id, 'Raushan I.',
    'Staff evacuated calmly and the fire crew was fast. Market was back open '
    'the same afternoon.',
    'safety', 1, false, '{"safety": -1}'::jsonb,
    timezone('utc', now()) - interval '8 hours'
  ),
  (
    'review_collision_1', 'place_intersection_collision', v_user_id, 'Gulnara S.',
    'This intersection needs a proper left-turn signal — this is the third '
    'accident here this year.',
    'safety', -2, false, '{"safety": -3}'::jsonb,
    timezone('utc', now()) - interval '12 hours'
  ),
  (
    'review_rollover_1', 'place_ring_road_rollover', v_user_id, 'Timur Y.',
    'Diversion to the inner lane was clearly signed, traffic kept moving despite '
    'the blockage.',
    'mobility', 1, false, '{"mobility": 1}'::jsonb,
    timezone('utc', now()) - interval '3 hours'
  ),
  (
    'review_gasleak_1', 'place_gas_leak_response', v_user_id, 'Madina O.',
    'Appreciated the text alert sent to residents within the perimeter — knew to '
    'avoid the block before I even left home.',
    'transparency', 2, false, '{"transparency": 2}'::jsonb,
    timezone('utc', now()) - interval '2 days'
  ),
  (
    'review_flood_1', 'place_flash_flood', v_user_id, 'Askar P.',
    'Storm drains in this area back up every time it rains hard — this isn''t '
    'the first flood here this year.',
    'resources', -2, false, '{"resources": -2}'::jsonb,
    timezone('utc', now()) - interval '5 hours'
  );
end $$;
