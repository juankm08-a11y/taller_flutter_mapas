import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final GenerativeModel _model;

  GeminiService()
    : _model = GenerativeModel(
        model: 'gemini-2.5-pro',
        apiKey: dotenv.env['GEMINI_API_KEY'] ?? '',
      );

  Future<String> generateDescription(String prompt) async {
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'No description generated';
  }

  Future<List<String>> interpretMoodToKeywords(String mood) async {
    final prompt =
        'Given the mood "$mood", suggest 3 keywords related to places that could improve that mood.';
    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';
    return text.split(RegExp(r'[,.\n]')).map((e) => e.trim()).toList();
  }

  Future<String> generatePersonalizedDescription(
    Map<String, dynamic> place,
    String mood,
  ) async {
    final prompt =
        'Based on the mood "$mood", describe why visiting "${place['name']}" could be a good idea.';
    final response = await _model.generateContent([Content.text(prompt)]);
    return response.text ?? 'No personalized description available.';
  }
}
