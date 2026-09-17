import '../config/api_config.dart';
import '../models/livraison_model.dart';
import 'api_service.dart';

/// Convertit une valeur JSON en double, qu'elle arrive en nombre ou en
/// texte (colonnes MySQL DECIMAL sérialisées en chaîne par Eloquent).
double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

class LivraisonService {
  final ApiService _api = ApiService();

  Future<List<LivraisonModel>> getDisponibles() async {
    final response = await _api.get(ApiConfig.livraisonsDisponiblesUrl, requiresAuth: true);
    return _parseListe(response);
  }

  Future<List<LivraisonModel>> getPropositions() async {
    final response = await _api.get(ApiConfig.livraisonsPropositionsUrl, requiresAuth: true);
    return _parseListe(response);
  }

  Future<List<LivraisonModel>> getMesLivraisons() async {
    final response = await _api.get(ApiConfig.livraisonsUrl, requiresAuth: true);
    return _parseListe(response);
  }

  Future<void> prendreEnCharge(int id) async {
    await _api.patch(ApiConfig.livraisonPrendreEnChargeUrl(id), requiresAuth: true);
  }

  Future<void> accepter(int id) async {
    await _api.patch(ApiConfig.livraisonAccepterUrl(id), requiresAuth: true);
  }

  Future<void> refuser(int id) async {
    await _api.patch(ApiConfig.livraisonRefuserUrl(id), requiresAuth: true);
  }

  Future<void> updateStatut(int id, String statut) async {
    await _api.patch(
      ApiConfig.livraisonStatutUrl(id),
      body: {'statut': statut},
      requiresAuth: true,
    );
  }

  /// Côté Transporteur : lit la position que l'acheteur a partagée.
  Future<Map<String, dynamic>?> getPositionAcheteur(int livraisonId) async {
    final response = await _api.get(ApiConfig.livraisonPositionAcheteurUrl(livraisonId), requiresAuth: true);
    return _parsePosition(response);
  }

  /// Côté Acheteur : lit la position actuelle du transporteur (carte temps réel).
  Future<Map<String, dynamic>?> getPositionTransporteur(int livraisonId) async {
    final response = await _api.get(ApiConfig.livraisonPositionTransporteurUrl(livraisonId), requiresAuth: true);
    return _parsePosition(response);
  }

  Map<String, dynamic>? _parsePosition(Map<String, dynamic> response) {
    final lat = _toDouble(response['latitude']);
    final lng = _toDouble(response['longitude']);
    if (lat == null || lng == null) return null;
    return {
      'latitude': lat,
      'longitude': lng,
      'transporteur_nom': response['transporteur_nom'] as String?,
      'position_updated_at': response['position_updated_at'] as String?,
    };
  }

  List<LivraisonModel> _parseListe(Map<String, dynamic> response) {
    final list = (response['data'] as List?) ?? [];
    return list.map((e) => LivraisonModel.fromJson(e as Map<String, dynamic>)).toList();
  }
}
