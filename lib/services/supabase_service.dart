import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/place.dart';

class SupabaseService {
  static final SupabaseService instance = SupabaseService._internal();
  SupabaseService._internal();

  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");

    final url = dotenv.env['SUPABASE_URL'];
    final key = dotenv.env['SUPABASE_ANON_KEY'];

    if (url == null || key == null) {
      throw Exception("Supabase variables not found in .env");
    }

    await Supabase.initialize(url: url, anonKey: key);
  }

  final client = Supabase.instance.client;

  Future<void> addPlace(Map<String, dynamic> data) async {
    await client.from('places').insert(data);
  }

  Future<List<Place>> getPlaces() async {
    final res = await client.from('places').select();
    return (res as List)
        .map((e) => Place.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Place>> searchPlacesByKeywords(List<String> keywords) async {
    final query = client
        .from('places')
        .select()
        .ilike('category', '%${keywords.join('%')}%');
    final res = await query;
    return (res as List)
        .map((e) => Place.fromMap(e as Map<String, dynamic>))
        .toList();
  }
}
