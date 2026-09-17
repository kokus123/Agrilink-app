import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Calcule un itinéraire routier réel entre deux points (pas une ligne
/// droite) — via le serveur de démonstration public d'OSRM (Open Source
/// Routing Machine).
///
/// Gratuit, sans clé API — mais c'est un serveur "usage raisonnable" mis
/// à disposition par le projet OSRM, pas un service garanti pour de la
/// production à fort trafic. Suffisant pour une démo/un prototype, mais
/// à savoir si le trajet ne se charge pas lors d'un usage très intensif.
class RouteService {
  static const _baseUrl = 'https://router.project-osrm.org/route/v1/driving';

  Future<List<LatLng>?> getRoute(LatLng origine, LatLng destination) async {
    final url = Uri.parse(
      '$_baseUrl/${origine.longitude},${origine.latitude};'
      '${destination.longitude},${destination.latitude}'
      '?overview=full&geometries=geojson',
    );

    try {
      final response = await http.get(url).timeout(const Duration(seconds: 8));
      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final routes = data['routes'] as List?;
      if (routes == null || routes.isEmpty) return null;

      final coords = (routes[0]['geometry']['coordinates'] as List);
      // GeoJSON donne [longitude, latitude] — on inverse pour LatLng.
      return coords
          .map((c) => LatLng((c[1] as num).toDouble(), (c[0] as num).toDouble()))
          .toList();
    } catch (_) {
      return null;
    }
  }
}
