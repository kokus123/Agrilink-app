import '../config/api_config.dart';
import '../models/message_model.dart';
import 'api_service.dart';

class ChatService {
  final ApiService _api = ApiService();

  Future<List<MessageModel>> getMessages(int livraisonId) async {
    final response = await _api.get(
      ApiConfig.livraisonMessagesUrl(livraisonId),
      requiresAuth: true,
    );
    final list = (response['data'] as List?) ?? [];
    return list
        .map((e) => MessageModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<MessageModel> envoyer(int livraisonId, String contenu) async {
    final response = await _api.post(
      ApiConfig.livraisonMessagesUrl(livraisonId),
      body: {'contenu': contenu},
      requiresAuth: true,
    );
    final data = (response['data'] as Map<String, dynamic>?) ?? response;
    return MessageModel.fromJson(data);
  }
}
