import '../config/api_config.dart';
import 'api_service.dart';

class NotationService {
  final ApiService _api = ApiService();

  Future<void> noter({
    required int commandeId,
    required int agriculteurId,
    required int note,
    String? commentaire,
  }) async {
    await _api.post(
      ApiConfig.notationsUrl,
      body: {
        'commande_id': commandeId,
        'agriculteur_id': agriculteurId,
        'note': note,
        if (commentaire != null && commentaire.trim().isNotEmpty) 'commentaire': commentaire.trim(),
      },
      requiresAuth: true,
    );
  }
}
