import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place.dart';

class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  /// Obtiene todos los lugares desde la tabla `places`.
  Future<List<Place>> getPlaces() async {
    final res =
        await client
                .from('places')
                .select()
                .order('creando_en', ascending: false)
            as List<dynamic>;
    return res
        .map(
          (e) => Place.fromMap(
            Map<String, dynamic>.from(e as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  /// Inserta un nuevo lugar. `payload` debe coincidir con los campos de la tabla.
  Future<Place> addPlace(Map<String, dynamic> payload) async {
    final res =
        await client.from('places').insert(payload).select() as List<dynamic>;
    if (res.isNotEmpty)
      return Place.fromMap(
        Map<String, dynamic>.from(res.first as Map<String, dynamic>),
      );
    throw Exception('Unexpected response from Supabase: $res');
  }

  /// Busca lugares por una lista de keywords (OR sobre name y category)
  Future<List<Place>> searchPlacesByKeywords(List<String> keywords) async {
    if (keywords.isEmpty) return [];
    // Construimos condición ilike para cada keyword
    final query = keywords
        .map(
          (k) =>
              "(name.ilike.*${k.replaceAll('%', '')}* OR category.ilike.*${k.replaceAll('%', '')}*)",
        )
        .join(',');
    // Usamos raw filter concatenando con or
    final res = await client.from('places').select().or(query) as List<dynamic>;
    return res
        .map(
          (e) => Place.fromMap(
            Map<String, dynamic>.from(e as Map<String, dynamic>),
          ),
        )
        .toList();
  }
}
