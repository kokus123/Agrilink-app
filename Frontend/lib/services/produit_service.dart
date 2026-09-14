import 'dart:io';
import '../config/api_config.dart';
import '../models/produit_model.dart';
import 'api_service.dart';

class ProduitService {
  final ApiService _api = ApiService();

  Future<List<ProduitModel>> getMesProduits() async {
    final response = await _api.get(ApiConfig.mesProduitsUrl, requiresAuth: true);
    final list = (response['data'] as List?) ?? [];
    return list
        .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ProduitModel> creer({
    required String nom,
    String? description,
    String? categorie,
    required double prix,
    required int quantiteDisponible,
    File? image,
  }) async {
    final response = await _api.multipart(
      ApiConfig.mesProduitsUrl,
      method: 'POST',
      fields: {
        'nom': nom,
        if (description != null) 'description': description,
        if (categorie != null) 'categorie': categorie,
        'prix': prix.toString(),
        'quantite_disponible': quantiteDisponible.toString(),
      },
      file: image,
      requiresAuth: true,
    );
    return ProduitModel.fromJson(_unwrap(response));
  }

  Future<ProduitModel> modifier({
    required int id,
    required String nom,
    String? description,
    String? categorie,
    required double prix,
    required int quantiteDisponible,
    required String statut,
    File? image,
  }) async {
    final response = await _api.multipart(
      '${ApiConfig.mesProduitsUrl}/$id',
      method: 'PATCH',
      fields: {
        'nom': nom,
        if (description != null) 'description': description,
        if (categorie != null) 'categorie': categorie,
        'prix': prix.toString(),
        'quantite_disponible': quantiteDisponible.toString(),
        'statut': statut,
      },
      file: image, // null => le backend garde l'image existante (voir contrôleur)
      requiresAuth: true,
    );
    return ProduitModel.fromJson(_unwrap(response));
  }

  Future<void> supprimer(int id) async {
    await _api.delete('${ApiConfig.mesProduitsUrl}/$id', requiresAuth: true);
  }

  /// Une JsonResource simple (non paginée) enveloppe sa réponse dans une clé
  /// "data" — contrairement aux collections, dont on lit directement la
  /// liste sous "data" (voir getMesProduits ci-dessus).
  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    return (response['data'] as Map<String, dynamic>?) ?? response;
  }
}
