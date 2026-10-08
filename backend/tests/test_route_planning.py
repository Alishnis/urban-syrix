"""Safe-route planning: the backend must ask OpenRouteService to avoid accident zones."""
import math

import pytest

import route_router
from conftest import FakeResponse

ORIGIN = {"latitude": 43.2389, "longitude": 76.8897}
DESTINATION = {"latitude": 43.2567, "longitude": 76.9286}
ACCIDENT_A = {"latitude": 43.245, "longitude": 76.90}
ACCIDENT_B = {"latitude": 43.250, "longitude": 76.915}

ORS_OK = {
    "features": [
        {
            "geometry": {"coordinates": [[76.8897, 43.2389], [76.90, 43.24], [76.9286, 43.2567]]},
            "properties": {"summary": {"distance": 4321.5, "duration": 612.0}},
        }
    ]
}


def haversine_m(lat1, lon1, lat2, lon2):
    r = 6371000.0
    p1, p2 = math.radians(lat1), math.radians(lat2)
    dphi, dlmb = p2 - p1, math.radians(lon2 - lon1)
    a = math.sin(dphi / 2) ** 2 + math.cos(p1) * math.cos(p2) * math.sin(dlmb / 2) ** 2
    return 2 * r * math.asin(math.sqrt(a))


def post_route(client, **overrides):
    body = {"origin": ORIGIN, "destination": DESTINATION, **overrides}
    return client.post("/api/route/safe-route", json=body)


def test_route_without_accidents_sends_no_avoid_polygons(client, fake_http, ors_key):
    fake_http.response = FakeResponse(200, ORS_OK)

    resp = post_route(client)

    assert resp.status_code == 200
    assert resp.json() == {
        "coordinates": ORS_OK["features"][0]["geometry"]["coordinates"],
        "distance_m": 4321.5,
        "duration_s": 612.0,
        "avoided_points": 0,
    }
    sent = fake_http.calls[0]["json"]
    assert "options" not in sent
    # ORS expects [longitude, latitude]
    assert sent["coordinates"] == [[76.8897, 43.2389], [76.9286, 43.2567]]


def test_route_avoids_each_accident_zone_with_a_circular_polygon(client, fake_http, ors_key):
    fake_http.response = FakeResponse(200, ORS_OK)

    resp = post_route(client, avoid_points=[ACCIDENT_A, ACCIDENT_B], avoid_radius_m=80)

    assert resp.status_code == 200
    assert resp.json()["avoided_points"] == 2

    call = fake_http.calls[0]
    assert call["url"] == route_router.ORS_URL
    multipolygon = call["json"]["options"]["avoid_polygons"]
    assert multipolygon["type"] == "MultiPolygon"
    assert len(multipolygon["coordinates"]) == 2

    for polygon, zone in zip(multipolygon["coordinates"], [ACCIDENT_A, ACCIDENT_B]):
        (ring,) = polygon
        assert ring[0] == ring[-1], "polygon ring must be closed"
        assert len(ring) == 17  # 16 segments + closing point
        for lon, lat in ring:
            distance = haversine_m(zone["latitude"], zone["longitude"], lat, lon)
            assert distance == pytest.approx(80, abs=0.5)


def test_api_key_is_sent_to_ors_but_never_returned(client, fake_http, ors_key):
    fake_http.response = FakeResponse(200, ORS_OK)

    resp = post_route(client)

    assert fake_http.calls[0]["headers"]["Authorization"] == "test-ors-key"
    assert "test-ors-key" not in resp.text


@pytest.mark.parametrize(
    "requested, expected",
    [
        (None, route_router.DEFAULT_AVOID_RADIUS_M),  # default
        (1, 10),  # clamped up to the 10 m minimum
        (5000, 200),  # clamped down to the 200 m maximum
    ],
)
def test_avoid_radius_is_clamped(client, fake_http, ors_key, requested, expected):
    fake_http.response = FakeResponse(200, ORS_OK)
    extra = {} if requested is None else {"avoid_radius_m": requested}

    post_route(client, avoid_points=[ACCIDENT_A], **extra)

    (ring,) = fake_http.calls[0]["json"]["options"]["avoid_polygons"]["coordinates"][0]
    lon, lat = ring[0]
    distance = haversine_m(ACCIDENT_A["latitude"], ACCIDENT_A["longitude"], lat, lon)
    assert distance == pytest.approx(expected, abs=0.5)


def test_ors_error_is_reported_as_400_with_upstream_message(client, fake_http, ors_key):
    fake_http.response = FakeResponse(
        404, {"error": {"code": 2010, "message": "Could not find routable point"}}
    )

    resp = post_route(client)

    assert resp.status_code == 400
    assert resp.json()["detail"] == "Could not find routable point"


def test_empty_route_geometry_is_reported_as_400(client, fake_http, ors_key):
    fake_http.response = FakeResponse(200, {"features": []})

    resp = post_route(client)

    assert resp.status_code == 400
    assert "geometry is unavailable" in resp.json()["detail"]


def test_missing_ors_key_returns_500_and_makes_no_upstream_call(client, fake_http, monkeypatch):
    monkeypatch.delenv("OPENROUTESERVICE_API_KEY", raising=False)
    monkeypatch.delenv("ORS_API_KEY", raising=False)

    resp = post_route(client)

    assert resp.status_code == 500
    assert "not configured" in resp.json()["detail"]
    assert fake_http.calls == []


def test_ors_api_key_alias_is_accepted(client, fake_http, monkeypatch):
    monkeypatch.delenv("OPENROUTESERVICE_API_KEY", raising=False)
    monkeypatch.setenv("ORS_API_KEY", "alias-key")
    fake_http.response = FakeResponse(200, ORS_OK)

    assert post_route(client).status_code == 200
    assert fake_http.calls[0]["headers"]["Authorization"] == "alias-key"


def test_offset_point_moves_the_requested_distance_and_heading():
    lat, lon = route_router._offset_point(43.0, 76.0, 1000, 0)  # due north
    assert lon == pytest.approx(76.0, abs=1e-9)
    assert haversine_m(43.0, 76.0, lat, lon) == pytest.approx(1000, abs=0.5)
    assert lat > 43.0


def point_in_ring(lon, lat, ring):
    """Ray-casting point-in-polygon test; ring is a closed list of [lon, lat]."""
    inside = False
    for (x1, y1), (x2, y2) in zip(ring, ring[1:]):
        if (y1 > lat) != (y2 > lat) and lon < (x2 - x1) * (lat - y1) / (y2 - y1) + x1:
            inside = not inside
    return inside


def test_each_avoid_polygon_encloses_its_accident_and_not_the_endpoints(client, fake_http, ors_key):
    fake_http.response = FakeResponse(200, ORS_OK)

    post_route(client, avoid_points=[ACCIDENT_A, ACCIDENT_B], avoid_radius_m=100)

    polygons = fake_http.calls[0]["json"]["options"]["avoid_polygons"]["coordinates"]
    for polygon, zone in zip(polygons, [ACCIDENT_A, ACCIDENT_B]):
        (ring,) = polygon
        assert point_in_ring(zone["longitude"], zone["latitude"], ring)
        for endpoint in (ORIGIN, DESTINATION):  # the trip must still be able to start and end
            assert not point_in_ring(endpoint["longitude"], endpoint["latitude"], ring)


def test_many_accidents_all_become_avoid_polygons_in_order(client, fake_http, ors_key):
    fake_http.response = FakeResponse(200, ORS_OK)
    zones = [{"latitude": 43.24 + i * 0.001, "longitude": 76.90} for i in range(5)]

    resp = post_route(client, avoid_points=zones)

    assert resp.json()["avoided_points"] == 5
    polygons = fake_http.calls[0]["json"]["options"]["avoid_polygons"]["coordinates"]
    assert len(polygons) == 5
    centres = [sum(lat for _, lat in p[0][:-1]) / 16 for p in polygons]
    assert centres == pytest.approx([z["latitude"] for z in zones], abs=1e-6)


def test_route_returned_by_ors_is_passed_through_unchanged(client, fake_http, ors_key):
    detour = [[76.8897, 43.2389], [76.895, 43.2500], [76.920, 43.2550], [76.9286, 43.2567]]
    fake_http.response = FakeResponse(
        200, {"features": [{"geometry": {"coordinates": detour}, "properties": {"summary": {"distance": 5200, "duration": 700}}}]}
    )

    resp = post_route(client, avoid_points=[ACCIDENT_A])

    assert resp.json()["coordinates"] == detour
    assert resp.json()["distance_m"] == 5200


def test_out_of_range_coordinates_are_not_checked_locally_the_upstream_error_is_returned(client, fake_http, ors_key):
    fake_http.response = FakeResponse(
        400, {"error": {"code": 2010, "message": "Coordinate out of range: latitude must be within -90..90"}}
    )

    resp = post_route(client, origin={"latitude": 999, "longitude": 76.9})

    assert resp.status_code == 400
    assert "out of range" in resp.json()["detail"]
    assert fake_http.calls[0]["json"]["coordinates"][0] == [76.9, 999]
