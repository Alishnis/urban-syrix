import 'package:hackathon_net/domain/models/urban_models.dart';

class MockUrbanRepository {
  List<UrbanPlace> getPlaces() {
    return [
      UrbanPlace(
        id: 'alem_riverside',
        name: 'Alem Riverside',
        type: UrbanPlaceType.building,
        address: 'Satpayev Ave 8',
        description: 'Transit-oriented mixed-use district near riverline.',
        location: const GeoPoint(latitude: 43.2389, longitude: 76.8897),
        developer: 'Nova Development',
        trafficRisk: 28,
        co2Footprint: 54,
        greenCoverage: 61,
        baseScores: const {
          UrbanCategory.mobility: 82,
          UrbanCategory.environment: 76,
          UrbanCategory.resources: 70,
          UrbanCategory.transparency: 68,
          UrbanCategory.inclusivity: 59,
          UrbanCategory.safety: 73,
        },
        issues: const [
          UrbanIssue(
            title: 'No tactile guidance near tram stop',
            category: UrbanCategory.inclusivity,
            daysOpen: 25,
            severity: 4,
          ),
          UrbanIssue(
            title: 'Night construction noise',
            category: UrbanCategory.transparency,
            daysOpen: 12,
            severity: 3,
          ),
        ],
        reviews: const [
          UrbanReview(
            author: 'Aruzhan',
            message: 'Bike lane is smooth, but crossings still feel unsafe.',
            category: UrbanCategory.mobility,
            sentiment: 1,
            daysAgo: 2,
          ),
          UrbanReview(
            author: 'Dias',
            message:
                'Ramp exists, but navigation is poor for wheelchair users.',
            category: UrbanCategory.inclusivity,
            sentiment: -1,
            daysAgo: 1,
            verifiedInclusivity: true,
          ),
        ],
      ),
      UrbanPlace(
        id: 'technopark_hub',
        name: 'TechnoPark Hub',
        type: UrbanPlaceType.building,
        address: 'Abay Ave 52',
        description: 'Startup and office quarter around BRT corridor.',
        location: const GeoPoint(latitude: 43.2433, longitude: 76.9147),
        developer: 'Qala Urban Lab',
        trafficRisk: 36,
        co2Footprint: 62,
        greenCoverage: 44,
        baseScores: const {
          UrbanCategory.mobility: 67,
          UrbanCategory.environment: 58,
          UrbanCategory.resources: 75,
          UrbanCategory.transparency: 80,
          UrbanCategory.inclusivity: 64,
          UrbanCategory.safety: 71,
        },
        issues: const [
          UrbanIssue(
            title: 'Heat island around parking deck',
            category: UrbanCategory.environment,
            daysOpen: 18,
            severity: 3,
          ),
        ],
        reviews: const [
          UrbanReview(
            author: 'Sanzhar',
            message: 'Great bus access, but lunchtime traffic gets worse.',
            category: UrbanCategory.mobility,
            sentiment: -1,
            daysAgo: 3,
          ),
        ],
      ),
      UrbanPlace(
        id: 'old_town_gateway',
        name: 'Old Town Gateway',
        type: UrbanPlaceType.road,
        address: 'Panfilov St 23',
        description: 'Historic pedestrian zone with public services.',
        location: const GeoPoint(latitude: 43.2587, longitude: 76.9456),
        developer: 'Municipal District',
        trafficRisk: 22,
        co2Footprint: 48,
        greenCoverage: 68,
        baseScores: const {
          UrbanCategory.mobility: 74,
          UrbanCategory.environment: 81,
          UrbanCategory.resources: 66,
          UrbanCategory.transparency: 72,
          UrbanCategory.inclusivity: 47,
          UrbanCategory.safety: 62,
        },
        issues: const [
          UrbanIssue(
            title: 'Steep entrances without ramp',
            category: UrbanCategory.inclusivity,
            daysOpen: 32,
            severity: 5,
          ),
          UrbanIssue(
            title: 'Low lighting on pedestrian street',
            category: UrbanCategory.safety,
            daysOpen: 16,
            severity: 3,
          ),
        ],
        reviews: const [
          UrbanReview(
            author: 'Mira',
            message: 'Beautiful and green, but evening route feels dark.',
            category: UrbanCategory.safety,
            sentiment: -1,
            daysAgo: 2,
          ),
        ],
      ),
      UrbanPlace(
        id: 'south_construction_belt',
        name: 'South Construction Belt',
        type: UrbanPlaceType.construction,
        address: 'Al-Farabi Ave 141',
        description: 'Three residential towers under phased delivery.',
        location: const GeoPoint(latitude: 43.2051, longitude: 76.9382),
        developer: 'Skyline Build Co.',
        trafficRisk: 41,
        co2Footprint: 71,
        greenCoverage: 31,
        baseScores: const {
          UrbanCategory.mobility: 52,
          UrbanCategory.environment: 43,
          UrbanCategory.resources: 57,
          UrbanCategory.transparency: 38,
          UrbanCategory.inclusivity: 55,
          UrbanCategory.safety: 49,
        },
        issues: const [
          UrbanIssue(
            title: 'Construction complaints unresolved',
            category: UrbanCategory.transparency,
            daysOpen: 29,
            severity: 5,
          ),
          UrbanIssue(
            title: 'Dust levels rising near school',
            category: UrbanCategory.environment,
            daysOpen: 9,
            severity: 4,
          ),
        ],
        reviews: const [
          UrbanReview(
            author: 'Timur',
            message:
                'Traffic will explode if all towers open without shuttles.',
            category: UrbanCategory.mobility,
            sentiment: -1,
            daysAgo: 1,
          ),
          UrbanReview(
            author: 'Alina',
            message: 'Noise after 10 PM keeps happening.',
            category: UrbanCategory.transparency,
            sentiment: -1,
            daysAgo: 1,
          ),
        ],
      ),
      UrbanPlace(
        id: 'school_crossroad_alert',
        name: 'School Crossroad Alert',
        type: UrbanPlaceType.incident,
        address: 'Tole Bi St 102',
        description: 'Temporary crossing near school with safety reports.',
        location: const GeoPoint(latitude: 43.2513, longitude: 76.8952),
        developer: 'City Mobility Unit',
        trafficRisk: 34,
        co2Footprint: 40,
        greenCoverage: 22,
        baseScores: const {
          UrbanCategory.mobility: 61,
          UrbanCategory.environment: 65,
          UrbanCategory.resources: 69,
          UrbanCategory.transparency: 58,
          UrbanCategory.inclusivity: 52,
          UrbanCategory.safety: 37,
        },
        issues: const [
          UrbanIssue(
            title: 'Flashing warning light not working',
            category: UrbanCategory.safety,
            daysOpen: 21,
            severity: 4,
          ),
        ],
        reviews: const [
          UrbanReview(
            author: 'Nargiz',
            message: 'Cars do not slow down enough at morning peak.',
            category: UrbanCategory.safety,
            sentiment: -1,
            daysAgo: 1,
          ),
        ],
      ),
    ];
  }
}
