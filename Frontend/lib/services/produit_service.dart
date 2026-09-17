import 'package:image_picker/image_picker.dart';
import '../config/api_config.dart';
import '../models/produit_model.dart';
import 'api_service.dart';

class ProduitService {
  final ApiService _api = ApiService();

  Future<List<ProduitModel>> getMesProduits() async {
    final response = await _api.get(ApiConfig.mesProduitsUrl, requiresAuth: true);
    final list = (response['data'] as List?) ?? [];
    return list.map((e) => ProduitModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ProduitModel> creer({
    required String nom,
    String? description,
    String? categorie,
    required double prix,
    required int quantiteDisponible,
    required String unite,
    XFile? image,
  }) async {
    final fields = <String, String>{
      'nom': nom,
      // Prix entier strict (FCFA n'utilise pas de centimes) — toStringAsFixed(0)
      // pour ne jamais envoyer "2000.0" que le backend rejetterait.
      'prix': prix.toStringAsFixed(0),
      'quantite_disponible': quantiteDisponible.toString(),
      'unite': unite,
      if (description != null) 'description': description,
      if (categorie != null) 'categorie': categorie,
    };

    final response = await _api.multipart(
      ApiConfig.mesProduitsUrl,
      method: 'POST',
      fields: fields,
      fileBytes: image != null ? await image.readAsBytes() : null,
      fileName: image?.name ?? 'produit.jpg',
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
    required String unite,
    required String statut,
    XFile? image,
  }) async {
    final fields = <String, String>{
      'nom': nom,
      'prix': prix.toStringAsFixed(0),
      'quantite_disponible': quantiteDisponible.toString(),
      'unite': unite,
      'statut': statut,
      if (description != null) 'description': description,
      if (categorie != null) 'categorie': categorie,
    };

    final response = await _api.multipart(
      ApiConfig.mesProduitDetailUrl(id),
      method: 'PATCH',
      fields: fields,
      fileBytes: image != null ? await image.readAsBytes() : null,
      fileName: image?.name ?? 'produit.jpg',
      requiresAuth: true,
    );

    return ProduitModel.fromJson(_unwrap(response));
  }

  Future<void> supprimer(int id) async {
    await _api.delete(ApiConfig.mesProduitDetailUrl(id), requiresAuth: true);
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    return (response['data'] as Map<String, dynamic>?) ?? response;
  }
}
