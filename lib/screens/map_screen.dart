import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
  Place? selected;
  final _moodCtrl = TextEditingController();
  bool _searching = false;
  final Map<String, String> _descriptions = {};

  @override
  void initState() {
    super.initState();
    _loadPlaces();
  }

  Future<void> _loadPlaces() async {
    final res = await supa.getPlaces();
    setState(() => places = res);
  }

  Future<void> _searchByMood() async {
    final mood = _moodCtrl.text.trim();
    if (mood.isEmpty) return;
    setState(() => _searching = true);
    final keywords = await widget.gemini.interpretMoodToKeywords(mood);
    final found = await supa.searchPlacesByKeywords(keywords);
    final placesWithDesc = <Place>[];
    for (final pmap in found) {
      final placeMap = pmap.toMap();
      final desc = await widget.gemini.generatePersonalizedDescription(
        placeMap,
        mood,
      );
      final copy = Place(
        id: pmap.id,
        name: pmap.name,
        latitude: pmap.latitude,
        longitude: pmap.longitude,
        category: pmap.category,
        imageUrl: pmap.imageUrl,
        createdAt: pmap.createdAt,
      );
      placesWithDesc.add(copy);
      _descriptions[copy.id] = desc;
    }
    setState(() {
      places = placesWithDesc;
      _searching = false;
    });
  }

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
                FlutterMap(
                  options: MapOptions(
                    initialCenter: places.isNotEmpty
                        ? LatLng(places.first.latitude, places.first.longitude)
                        : const LatLng(0, 0),
                    initialZoom: 12,
                    onTap: (_, __) => setState(() => selected = null),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.tumapa',
                    ),
                    MarkerLayer(
                      markers: places
                          .map(
                            (p) => Marker(
                              point: LatLng(p.latitude, p.longitude),
                              width: 40,
                              height: 40,
                              child: GestureDetector(
                                onTap: () => setState(() => selected = p),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.red,
                                  size: 36,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
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
