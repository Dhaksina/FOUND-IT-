class GeminiConfig {
  // Replace with your actual Gemini API Key from Google AI Studio
  // You can get a free key at https://aistudio.google.com/
  static const String apiKey = 'AQ.Ab8RN6L_aPx8KANVuh9RGVuhkpPzibHQAPauibiZQFZcOuAyZg';

  static bool get isConfigured {
    return apiKey.isNotEmpty && 
           apiKey != 'YOUR_GEMINI_API_KEY';
  }
}
