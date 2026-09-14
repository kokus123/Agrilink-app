import 'package:flutter/material.dart';
import '../services/abonnement_service.dart';
import '../services/api_service.dart';
import '../services/paiement_service.dart';

class AbonnementProvider extends ChangeNotifier {
  final AbonnementService _abonnementService = AbonnementService();
  final PaiementService _paiementService = PaiementService();

  bool _isSubscribed = false;
  DateTime? _subscriptionExpiresAt;
  bool _isLoading = false;
  String? _errorMessage;
  String? _infoMessage;
  int? _paiementEnAttenteId;

  bool get isSubscribed => _isSubscribed;
  DateTime? get subscriptionExpiresAt => _subscriptionExpiresAt;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  int? get paiementEnAttenteId => _paiementEnAttenteId;

  Future<void> chargerStatut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final statut = await _abonnementService.statut();
      _isSubscribed = statut.isSubscribed;
      _subscriptionExpiresAt = statut.subscriptionExpiresAt;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
    } catch (e) {
      _errorMessage = 'Erreur inattendue : $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> souscrire({required int dureeMois, required String methode}) async {
    _isLoading = true;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();

    try {
      final paiementId = await _abonnementService.souscrire(
        dureeMois: dureeMois,
        methode: methode,
      );
      _paiementEnAttenteId = paiementId;
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

  Future<bool> payer({required String operateur, required String phone}) async {
    if (_paiementEnAttenteId == null) {
      _errorMessage = 'Aucune souscription en attente.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _paiementService.payer(
        paiementId: _paiementEnAttenteId!,
        operateur: operateur,
        phone: phone,
      );
      _infoMessage = 'Paiement initié — vérifie ton téléphone pour confirmer.';
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
}
