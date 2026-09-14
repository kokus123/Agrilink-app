import '../config/api_config.dart';
import 'api_service.dart';

class PositionService {
  final ApiService _api = ApiService();

  /// NB : je pars de l'hypothèse que l'endpoint attend `latitude`/`longitude`
  /// (cohérent avec les colonnes users.latitude/longitude vues côté backend).
  /// Si l'API renvoie une erreur 422 listant d'autres noms de champs,
  /// dis-le moi et j'ajuste cette seule ligne.
  Future<void> envoyerPosition(double latitude, double longitude) async {
    await _api.post(
      ApiConfig.positionUrl,
      body: {'latitude': latitude, 'longitude': longitude},
      requiresAuth: true,
    );
  }
}
