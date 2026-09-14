import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/commande_model.dart';
import '../services/api_service.dart';
import '../services/commande_service.dart';

class AcheteurCommandeProvider extends ChangeNotifier {
  final CommandeService _service = CommandeService();

  List<CommandeModel> _commandes = [];
  CommandeModel? _derniereCommande;
  bool _isLoading = false;
  String? _errorMessage;

  List<CommandeModel> get commandes => _commandes;
  CommandeModel? get derniereCommande => _derniereCommande;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> charger() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _commandes = await _service.getCommandesAcheteur();
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
    } catch (e) {
      _errorMessage = 'Erreur inattendue : $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> passerCommande(List<CartItem> items) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final commande = await _service.creerCommande(items);
      _derniereCommande = commande;
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Modifie une commande existante (tant qu'elle est en_attente) puis
  /// recharge la liste pour refléter le nouveau montant/lignes.
  /// [lignes] : une entrée par produit, ex. [{'id': 4, 'quantite': 2}, ...]
  Future<bool> modifierCommande(int commandeId, List<Map<String, int>> lignes) async {
    _errorMessage = null;
    try {
      await _service.modifierCommande(commandeId, lignes);
      await charger();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    }
  }

  /// Annule une commande (tant qu'elle est en_attente) puis recharge la liste.
  Future<bool> annulerCommande(int commandeId) async {
    _errorMessage = null;
    try {
      await _service.annulerCommande(commandeId);
      await charger();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    }
  }

  void reinitialiserConfirmation() {
    _derniereCommande = null;
    notifyListeners();
  }
}
