import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/route_service.dart';
import '../theme/app_theme.dart';

/// Carte temps réel réutilisable — façon Yango. Affiche :
/// - la position de la personne suivie ([fetchPosition]), avec une icône
///   voiture, rafraîchie toutes les 8 secondes
/// - la position de l'observateur lui-même (lue en direct sur son propre
///   appareil, via GPS — PAS la position partagée côté serveur, qui est
///   un concept différent)
/// - l'itinéraire réel entre les deux (routes suivies, pas une ligne
///   droite), recalculé moins souvent pour ménager le service gratuit
///   utilisé (OSRM, usage raisonnable).
class LiveMapScreen extends StatefulWidget {
  final String titre;
  final String labelMarqueur;
  final Future<Map<String, dynamic>?> Function() fetchPosition;

  const LiveMapScreen({
    super.key,
    required this.titre,
    required this.labelMarqueur,
    required this.fetchPosition,
  });

  @override
  State<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends State<LiveMapScreen> {
  final MapController _mapController = MapController();
  final RouteService _routeService = RouteService();
  Timer? _timer;
  int _tick = 0;

  LatLng? _positionSuivie;
  LatLng? _maPosition;
  List<LatLng>? _itineraire;
  bool _isLoading = true;
  bool _aDejaCadre = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _rafraichir();
    _timer = Timer.periodic(const Duration(seconds: 8), (_) => _rafraichir());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Position GPS de l'observateur lui-même (pas celle partagée côté
  /// serveur par l'autre personne) — sert de point de départ pour
  /// l'itinéraire. Échec silencieux : sans elle, on affiche quand même
  /// la position suivie, juste sans tracé de route.
  Future<LatLng?> _obtenirMaPosition() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final demande = await Geolocator.requestPermission();
        if (demande == LocationPermission.denied ||
            demande == LocationPermission.deniedForever) {
          return null;
        }
      }
      if (permission == LocationPermission.deniedForever) return null;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  Future<void> _rafraichir() async {
    _tick++;

    try {
      final data = await widget.fetchPosition();
      final maPosition = await _obtenirMaPosition();
      if (!mounted) return;

      if (data == null) {
        setState(() {
          _isLoading = false;
          _maPosition = maPosition;
          _errorMessage = null;
        });
        return;
      }

      final nouvellePosition = LatLng(
        data['latitude'] as double,
        data['longitude'] as double,
      );

      // Recalcule l'itinéraire seulement au premier chargement ou tous
      // les ~3 rafraîchissements (~24s) — ménage le service de routage
      // gratuit plutôt que de le solliciter toutes les 8 secondes.
      List<LatLng>? nouvelItineraire = _itineraire;
      if (maPosition != null && (_itineraire == null || _tick % 3 == 0)) {
        nouvelItineraire = await _routeService.getRoute(maPosition, nouvellePosition) ?? _itineraire;
      }

      if (!mounted) return;

      setState(() {
        _positionSuivie = nouvellePosition;
        _maPosition = maPosition;
        _itineraire = nouvelItineraire;
        _isLoading = false;
        _errorMessage = null;
      });

      _recadrer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Impossible de charger la position pour le moment.';
      });
    }
  }

  void _recadrer() {
    if (_positionSuivie == null) return;

    if (_maPosition == null) {
      // Pas de position perso connue — centre juste sur la personne suivie.
      if (!_aDejaCadre) {
        _aDejaCadre = true;
        _mapController.move(_positionSuivie!, 15);
      } else {
        _mapController.move(_positionSuivie!, _mapController.camera.zoom);
      }
      return;
    }

    // Les deux positions sont connues — cadre pour montrer les deux.
    final bounds = LatLngBounds(_positionSuivie!, _maPosition!);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(70)),
    );
    _aDejaCadre = true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.titre)),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _positionSuivie == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_off_outlined, size: 40, color: AppColors.textMuted),
                        const SizedBox(height: 12),
                        Text(
                          _errorMessage ?? "Aucune position partagée pour l'instant.",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                )
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _positionSuivie!,
                    initialZoom: 15,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.agrilink.app',
                    ),
                    if (_itineraire != null)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _itineraire!,
                            strokeWidth: 5,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    MarkerLayer(
                      markers: [
                        // La personne suivie — icône voiture.
                        Marker(
                          point: _positionSuivie!,
                          width: 140,
                          height: 64,
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  widget.labelMarqueur,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                                child: const Icon(Icons.directions_car_filled_rounded, color: Colors.white, size: 20),
                              ),
                            ],
                          ),
                        ),
                        // L'observateur lui-même — un simple repère de destination.
                        if (_maPosition != null)
                          Marker(
                            point: _maPosition!,
                            width: 34,
                            height: 34,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.accent, width: 2),
                                boxShadow: [
                                  BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4),
                                ],
                              ),
                              child: const Icon(Icons.person_pin_circle_rounded, color: AppColors.accent, size: 22),
                            ),
                          ),
                      ],
                    ),
                    RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution('OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
    );
  }
}
