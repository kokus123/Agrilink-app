import 'package:flutter/material.dart';
import '../models/livraison_model.dart';
import '../services/api_service.dart';
import '../services/livraison_service.dart';

class LivraisonProvider extends ChangeNotifier {
  final LivraisonService _service = LivraisonService();

  List<LivraisonModel> _propositions = [];
  List<LivraisonModel> _disponibles = [];
  List<LivraisonModel> _mesLivraisons = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<LivraisonModel> get propositions => _propositions;
  List<LivraisonModel> get disponibles => _disponibles;
  List<LivraisonModel> get mesLivraisons => _mesLivraisons;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> chargerPropositions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _propositions = await _service.getPropositions();
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
    } catch (e) {
      _errorMessage = 'Erreur inattendue : $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> chargerDisponibles() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _disponibles = await _service.getDisponibles();
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
    } catch (e) {
      _errorMessage = 'Erreur inattendue : $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> chargerMesLivraisons() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _mesLivraisons = await _service.getMesLivraisons();
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
    } catch (e) {
      _errorMessage = 'Erreur inattendue : $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> accepter(int id) async {
    _errorMessage = null;
    try {
      await _service.accepter(id);
      await chargerPropositions();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> refuser(int id) async {
    _errorMessage = null;
    try {
      await _service.refuser(id);
      await chargerPropositions();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> prendreEnCharge(int id) async {
    _errorMessage = null;
    try {
      await _service.prendreEnCharge(id);
      await chargerDisponibles();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> marquerLivree(int id) async {
    _errorMessage = null;
    try {
      await _service.updateStatut(id, 'livree');
      await chargerMesLivraisons();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> annuler(int id) async {
    _errorMessage = null;
    try {
      await _service.updateStatut(id, 'annulee');
      await chargerMesLivraisons();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    }
  }
}
