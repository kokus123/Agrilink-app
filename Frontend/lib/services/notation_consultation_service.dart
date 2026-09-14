import '../config/api_config.dart';
import '../models/notation_recue_model.dart';
import 'api_service.dart';

class NotationConsultationService {
  final ApiService _api = ApiService();

  Future<List<NotationRecue>> getNotationsDe(int agriculteurId) async {
    final response = await _api.get(
      ApiConfig.agriculteurNotationsUrl(agriculteurId),
      requiresAuth: false,
    );
    // Réponse de pagination Laravel brute (pas une Resource) : la liste est
    // directement sous "data".
    final list = (response['data'] as List?) ?? [];
    return list
        .map((e) => NotationRecue.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
