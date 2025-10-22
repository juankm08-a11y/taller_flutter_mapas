import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;
  GeminiService(this.apiKey);

  /// Genera una descripción para un lugar dado coordenadas o texto.
  Future<String> generateDescription(String prompt) async {
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final body = {
      'model': 'gpt-4o-mini',
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
      'max_tokens': 300,
    };
    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode(body),
    );
    if (res.statusCode >= 400) throw Exception('Gemini API error: ${res.body}');
    final data = jsonDecode(res.body) as Map<String, dynamic>;
    // Adaptar según la respuesta real de Gemini/OpenAI
    final content =
        (data['choices'] as List).first['message']['content'] as String;
    return content;
  }

  /// Interpreta un estado emocional y devuelve una lista de keywords (ej: 'parque, naturaleza, tranquilo')
  Future<List<String>> interpretMoodToKeywords(String mood) async {
    final prompt = 'Usuario dice: "$mood". Devuelve 5 keywords separadas por comas que describan tipos de lugares recomendables para ese estado (una sola línea, sin explicaciones).';
    final raw = await generateDescription(prompt);
    // intentar parsear por comas
    final parts = raw.split(RegExp(r'[\n,]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    return parts.take(5).toList();
  }

  /// Genera una descripción personalizada para un lugar dado el estado emocional.
  Future<String> generatePersonalizedDescription(Map<String, dynamic> place, String mood) async {
    final name = place['name'] ?? 'Este lugar';
    final category = place['category'] ?? '';
    final prompt = 'Eres un asistente que sugiere lugares para bienestar. Usuario está: "$mood". Genera una descripción corta (1-2 frases) para el lugar "$name" (categoria: $category) que motive al usuario a visitarlo y explique por qué encaja con su estado emocional.';
    final desc = await generateDescription(prompt);
    return desc.trim();
  }
}
