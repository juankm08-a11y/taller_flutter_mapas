import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/supabase_service.dart';
import '../services/gemini_service.dart';
import '../models/place.dart';
import '../widgets/place_card.dart';

class MapScreen extends StatefulWidget {
  final GeminiService gemini;
  const MapScreen({Key? key, required this.gemini}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final SupabaseService supa = SupabaseService.instance;
  List<Place> places = [];
  Set<Marker> markers = {};
  Place? selected;
  final _moodCtrl = TextEditingController();
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    final res = await supa.getPlaces();
    setState(() {
      places = res;
      markers = res
          .map(
            (p) => Marker(
              markerId: MarkerId(p.id),
              position: LatLng(p.latitude, p.longitude),
              infoWindow: InfoWindow(title: p.name),
              onTap: () => setState(() => selected = p),
            ),
          )
          .toSet();
    });
  }

  Future<void> _searchByMood() async {
    final mood = _moodCtrl.text.trim();
    if (mood.isEmpty) return;
    setState(() => _searching = true);

    // 1) Gemini interpreta mood -> keywords
    final keywords = await widget.gemini.interpretMoodToKeywords(mood);

    // 2) Supabase busca lugares por keywords
    final found = await supa.searchPlacesByKeywords(keywords);

    // 3) Para cada lugar, generar descripción personalizada
    final placesWithDesc = <Place>[];
    for (final pmap in found) {
      // convertir a Map para pasarlo al servicio de Gemini
      final placeMap = pmap.toMap();
      final desc = await widget.gemini.generatePersonalizedDescription(
        placeMap,
        mood,
      );
      // Creamos una instancia copia con imageUrl y category ya existentes y guardamos descripción en name temporalmente? Mejor: usar un campo transitorio.
      final copy = Place(
        id: pmap.id,
        name: pmap.name,
        latitude: pmap.latitude,
        longitude: pmap.longitude,
        category: pmap.category,
        imageUrl: pmap.imageUrl,
        createdAt: pmap.createdAt,
      );
      // Usaremos un mapa de descripciones en el estado
      placesWithDesc.add(copy);
      // Guardar descripción en un Map local
      _descriptions[copy.id] = desc;
    }

    setState(() {
      places = placesWithDesc;
      markers = places
          .map(
            (p) => Marker(
              markerId: MarkerId(p.id),
              position: LatLng(p.latitude, p.longitude),
              infoWindow: InfoWindow(title: p.name),
              onTap: () => setState(() => selected = p),
            ),
          )
          .toSet();
      _searching = false;
    });
  }

  final Map<String, String> _descriptions = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bienestar: encuentra lugares')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _moodCtrl,
                    decoration: const InputDecoration(
                      hintText: '¿Cómo te sientes? (ej: estoy estresado)',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _searching ? null : _searchByMood,
                  child: _searching
                      ? const CircularProgressIndicator()
                      : const Text('Buscar'),
                ),
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(0, 0),
                    zoom: 2,
                  ),
                  markers: markers,
                  myLocationEnabled: true,
                ),
                if (selected != null)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlaceCard(place: selected!),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            _descriptions[selected!.id] ?? '',
                            style: const TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).pushNamed('/add');
          _loadPlaces();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
