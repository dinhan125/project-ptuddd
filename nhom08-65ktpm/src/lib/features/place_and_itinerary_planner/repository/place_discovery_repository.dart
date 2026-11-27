import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_plan.dart';
import '../models/place_suggestion.dart';

class PlaceDiscoveryRepository {
  Future<List<PlaceSuggestion>> search({
    String query = '',
    PlaceCategory? category,
    double latitude = 10.7769,
    double longitude = 106.7009,
  }) async {
    try {
      final tags = category == PlaceCategory.food
          ? ['amenity=restaurant', 'amenity=cafe']
          : category == PlaceCategory.hotel
          ? ['tourism=hotel']
          : ['tourism=attraction', 'tourism=museum', 'historic=monument'];
      final clauses = tags
          .map((tag) => 'nwr["$tag"](around:12000,$latitude,$longitude);')
          .join();
      final response = await http
          .post(
            Uri.parse('https://overpass-api.de/api/interpreter'),
            body: {
              'data': '[out:json][timeout:15];($clauses);out center tags;',
            },
          )
          .timeout(const Duration(seconds: 18));
      if (response.statusCode == 200) {
        final elements =
            (jsonDecode(response.body)['elements'] as List<dynamic>);
        final result = elements
            .map(_fromOverpass)
            .whereType<PlaceSuggestion>()
            .where((item) {
              return query.trim().isEmpty ||
                  item.name.toLowerCase().contains(query.toLowerCase());
            })
            .take(50)
            .toList();
        if (result.isNotEmpty) return result;
      }
    } catch (_) {}
    return fallback(category, query);
  }

  PlaceSuggestion? _fromOverpass(dynamic raw) {
    final tags = Map<String, dynamic>.from(raw['tags'] as Map? ?? {});
    final name = tags['name'] as String?;
    final center = raw['center'] as Map?;
    final lat = (raw['lat'] ?? center?['lat']) as num?;
    final lon = (raw['lon'] ?? center?['lon']) as num?;
    if (name == null || lat == null || lon == null) return null;
    final category = tags['amenity'] != null
        ? PlaceCategory.food
        : tags['tourism'] == 'hotel'
        ? PlaceCategory.hotel
        : PlaceCategory.attraction;
    return PlaceSuggestion(
      id: '${raw['type']}_${raw['id']}',
      name: name,
      category: category,
      address: tags['addr:street'] as String? ?? '',
      latitude: lat.toDouble(),
      longitude: lon.toDouble(),
      defaultDurationMinutes: category == PlaceCategory.hotel ? 30 : 90,
    );
  }

  List<PlaceSuggestion> fallback(PlaceCategory? category, String query) {
    const items = [
      PlaceSuggestion(
        id: 'fallback-1',
        name: 'Bảo tàng Chứng tích Chiến tranh',
        category: PlaceCategory.attraction,
        address: '28 Võ Văn Tần, Quận 3',
        latitude: 10.7794,
        longitude: 106.6922,
        defaultDurationMinutes: 90,
        rating: 4.5,
      ),
      PlaceSuggestion(
        id: 'fallback-2',
        name: 'Chợ Bến Thành',
        category: PlaceCategory.food,
        address: 'Lê Lợi, Quận 1',
        latitude: 10.7725,
        longitude: 106.6980,
        defaultDurationMinutes: 90,
        estimatedFoodCost: 120000,
        rating: 4.2,
      ),
      PlaceSuggestion(
        id: 'fallback-3',
        name: 'Khách sạn trung tâm',
        category: PlaceCategory.hotel,
        address: 'Quận 1, TP. Hồ Chí Minh',
        latitude: 10.7750,
        longitude: 106.7000,
        defaultDurationMinutes: 30,
        estimatedFoodCost: 0,
        rating: 4.0,
      ),
    ];
    return items
        .where(
          (item) =>
              (category == null || item.category == category) &&
              (query.isEmpty ||
                  item.name.toLowerCase().contains(query.toLowerCase())),
        )
        .toList();
  }
}
