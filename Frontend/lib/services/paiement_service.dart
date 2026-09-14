import '../config/api_config.dart';
import 'api_service.dart';

class PaiementService {
  final ApiService _api = ApiService();

  /// Déclenche le prompt Mobile Money (MTN/Orange) sur le téléphone du
  /// client. La confirmation réelle arrive plus tard via le webhook
  /// NotchPay côté backend — cette réponse dit seulement "c'est parti".
  Future<void> payer({
    required int paiementId,
    required String operateur, // 'mtn' ou 'orange'
    required String phone, // format +237XXXXXXXXX
  }) async {
    await _api.post(
      ApiConfig.payerPaiementUrl(paiementId),
      body: {'operateur': operateur, 'phone': phone},
      requiresAuth: true,
    );
  }
}
