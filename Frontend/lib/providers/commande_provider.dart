import 'package:flutter/material.dart';
import '../models/commande_model.dart';
import '../services/api_service.dart';
import '../services/commande_service.dart';

class CommandeProvider extends ChangeNotifier {
  final CommandeService _service = CommandeService();

  List<CommandeModel> _commandes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CommandeModel> get commandes => _commandes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> charger() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _commandes = await _service.getMesCommandes();
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
    } catch (e) {
      _errorMessage = 'Erreur inattendue : $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> notifierTransporteur(int commandeId) async {
    _errorMessage = null;
    try {
      await _service.notifierTransporteur(commandeId);
      await charger(); // recharge pour refléter le nouveau statut
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    }
  }
}
