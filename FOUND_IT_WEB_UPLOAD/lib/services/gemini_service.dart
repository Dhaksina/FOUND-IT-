import 'dart:convert';
import 'dart:io';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../config/gemini_config.dart';

class GeminiService {
  static final GeminiService instance = GeminiService._internal();
  GeminiService._internal();

  GenerativeModel? _model;
  bool _initialized = false;

  void initialize() {
    if (_initialized) return;
    
    if (GeminiConfig.isConfigured) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: GeminiConfig.apiKey,
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
        ),
      );
      _initialized = true;
      print('Gemini Service initialized successfully.');
    }
  }

  bool get isConfigured => GeminiConfig.isConfigured;

  Future<Map<String, String>?> analyzeImage(File file) async {
    if (!isConfigured) {
      print('Gemini API is not configured. Skipping live AI analysis.');
      return null;
    }

    try {
      initialize();
      if (_model == null) return null;

      final bytes = await file.readAsBytes();
      final String mimeType = file.path.toLowerCase().endsWith('.png') ? 'image/png' : 'image/jpeg';
      
      final imagePart = DataPart(mimeType, bytes);
      final prompt = TextPart(
        'Analyze this photo of a lost/found item. '
        'Respond in JSON format with exactly three string fields:\n'
        '1. "category": Choose the single closest category from this list: [\'Phone\', \'Wallet\', \'Keys\', \'Earbuds\', \'Bag\', \'Watch\', \'Document\', \'Other\']\n'
        '2. "title": A concise name of the item (e.g. "Black Metal Water Bottle", "iPhone 13 with Red Case", "Keys with Leather Fob")\n'
        '3. "description": A short 1-2 sentence description of the item in the photo.'
      );

      final response = await _model!.generateContent([
        Content.multi([prompt, imagePart])
      ]);

      final text = response.text;
      if (text == null || text.isEmpty) return null;

      print('Gemini Raw Response: $text');
      final Map<String, dynamic> data = json.decode(text);
      
      return {
        'title': data['title']?.toString() ?? 'Item',
        'category': data['category']?.toString() ?? 'Other',
        'description': data['description']?.toString() ?? '',
      };
    } catch (e) {
      print('Error in Gemini image analysis: $e');
      rethrow;
    }
  }
}
