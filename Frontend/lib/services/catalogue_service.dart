import '../config/api_config.dart';
import '../models/produit_model.dart';
import 'api_service.dart';

class CatalogueService {
  final ApiService _api = ApiService();

  Future<List<ProduitModel>> rechercher({
    String? search,
    String? categorie,
    double? prixMax,
  }) async {
    final params = <String, String>{};
    if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
    if (categorie != null && categorie.isNotEmpty) params['categorie'] = categorie;
    if (prixMax != null) params['prix_max'] = prixMax.toString();

    final uri = Uri.parse(ApiConfig.produitsUrl)
        .replace(queryParameters: params.isEmpty ? null : params);

    final response = await _api.get(uri.toString());
    final list = (response['data'] as List?) ?? [];
    return list
        .map((e) => ProduitModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
