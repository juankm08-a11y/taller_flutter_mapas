class Place {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final String category;
  final String imageUrl;
  final DateTime createdAt;

  Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.category,
    required this.imageUrl,
    required this.createdAt,
  });

  factory Place.fromMap(Map<String, dynamic> m) {
    return Place(
      id: m['id'] as String,
      name: m['name'] as String,
      latitude: (m['latitude'] as num).toDouble(),
      longitude: (m['longitude'] as num).toDouble(),
      category: m['category'] as String? ?? '',
      imageUrl: m['image_url'] as String? ?? '',
      createdAt: DateTime.parse(m['creando_en'] as String),
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'latitude': latitude,
    'longitude': longitude,
    'category': category,
    'image_url': imageUrl,
    'creando_en': createdAt.toIso8601String(),
  };
}
