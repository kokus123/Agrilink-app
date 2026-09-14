import '../config/api_config.dart';
import 'api_service.dart';

class AbonnementStatut {
  final bool isSubscribed;
  final DateTime? subscriptionExpiresAt;

  const AbonnementStatut({
    required this.isSubscribed,
    this.subscriptionExpiresAt,
  });

  factory AbonnementStatut.fromJson(Map<String, dynamic> json) {
    return AbonnementStatut(
      isSubscribed: json['is_subscribed'] is bool
          ? json['is_subscribed'] as bool
          : (json['is_subscribed'] == 1 || json['is_subscribed'] == '1'),
      subscriptionExpiresAt: json['subscription_expires_at'] != null
          ? DateTime.tryParse(json['subscription_expires_at'].toString())
          : null,
    );
  }
}

class AbonnementService {
  final ApiService _api = ApiService();

  Future<AbonnementStatut> statut() async {
    final response = await _api.get(ApiConfig.abonnementStatutUrl, requiresAuth: true);
    return AbonnementStatut.fromJson(response);
  }

  /// Crée le paiement 'en_attente' côté backend et retourne son id —
  /// à transmettre ensuite à PaiementService.payer() pour déclencher le
  /// Mobile Money. Le champ `methode` est requis par l'API mais sera de
  /// toute façon écrasé par l'opérateur choisi à l'étape de paiement.
  Future<int> souscrire({required int dureeMois, required String methode}) async {
    final response = await _api.post(
      ApiConfig.abonnementSouscrireUrl,
      body: {'duree_mois': dureeMois, 'methode': methode},
      requiresAuth: true,
    );
    final id = response['paiement_id'];
    return id is int ? id : int.parse(id.toString());
  }
}
