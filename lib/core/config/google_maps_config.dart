class GoogleMapsConfig {
  const GoogleMapsConfig._();

  static const apiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: 'AIzaSyA1I9NaQcg6zbj2iVXsmqjKK0E4bYYpNuY',
  );
}
