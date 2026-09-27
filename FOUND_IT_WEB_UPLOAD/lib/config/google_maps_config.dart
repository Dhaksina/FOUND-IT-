class GoogleMapsConfig {
  // Set this to your actual Google Maps API key once you have one.
  // By default, it detects if the default placeholder is still active.
  static const String apiKey = 'AIzaSyCJUdIX_elB-85wFvBlRVJ6ITA3TrkRuyI';

  static bool get isConfigured => apiKey != 'YOUR_GOOGLE_MAPS_API_KEY';
}
