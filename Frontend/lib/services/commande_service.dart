import '../config/api_config.dart';
import '../models/cart_item_model.dart';
import '../models/commande_model.dart';
import 'api_service.dart';

class CommandeService {
  final ApiService _api = ApiService();

  // ---------------------------------------------------------------
  // Côté Agriculteur : commandes reçues (contenant ses produits)
  // ---------------------------------------------------------------

  Future<List<CommandeModel>> getMesCommandes() async {
    final response = await _api.get(ApiConfig.mesCommandesUrl, requiresAuth: true);
    final list = (response['data'] as List?) ?? [];
    return list
        .map((e) => CommandeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> notifierTransporteur(int commandeId) async {
    await _api.patch(
      ApiConfig.notifierTransporteurUrl(commandeId),
      requiresAuth: true,
    );
  }

  // ---------------------------------------------------------------
  // Côté Acheteur : ses propres commandes passées
  // ---------------------------------------------------------------

  Future<List<CommandeModel>> getCommandesAcheteur() async {
    final response = await _api.get(ApiConfig.commandesUrl, requiresAuth: true);
    final list = (response['data'] as List?) ?? [];
    return list
        .map((e) => CommandeModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<CommandeModel> creerCommande(List<CartItem> items) async {
    final response = await _api.post(
      ApiConfig.commandesUrl,
      body: {'produits': items.map((i) => {'id': i.produit.id, 'quantite': i.quantite}).toList()},
      requiresAuth: true,
    );
    return CommandeModel.fromJson(_unwrap(response));
  }

  /// Remplace entièrement les lignes d'une commande existante — uniquement
  /// possible côté serveur tant que son statut est encore 'en_attente'.
  /// [lignes] : une entrée par produit, ex. [{'id': 4, 'quantite': 2}, ...]
  Future<CommandeModel> modifierCommande(int commandeId, List<Map<String, int>> lignes) async {
    final response = await _api.patch(
      ApiConfig.commandeDetailUrl(commandeId),
      body: {'produits': lignes},
      requiresAuth: true,
    );
    return CommandeModel.fromJson(_unwrap(response));
  }

  /// Annule la commande (le serveur la marque 'annulee' et restitue le
  /// stock — pas une suppression physique).
  Future<void> annulerCommande(int commandeId) async {
    await _api.delete(ApiConfig.commandeDetailUrl(commandeId), requiresAuth: true);
  }

  Map<String, dynamic> _unwrap(Map<String, dynamic> response) {
    return (response['data'] as Map<String, dynamic>?) ?? response;
  }
}
