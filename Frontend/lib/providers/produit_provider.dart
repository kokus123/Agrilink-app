import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../models/produit_model.dart';
import '../services/api_service.dart';
import '../services/produit_service.dart';

class ProduitProvider extends ChangeNotifier {
  final ProduitService _service = ProduitService();

  List<ProduitModel> _produits = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _limitePremiumAtteinte = false;

  List<ProduitModel> get produits => _produits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  /// True quand la dernière tentative de création a échoué parce que le
  /// forfait gratuit (2 produits max) est atteint — l'écran doit alors
  /// proposer un lien vers l'abonnement plutôt qu'une simple erreur.
  bool get limitePremiumAtteinte => _limitePremiumAtteinte;

  Future<void> charger() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _produits = await _service.getMesProduits();
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
    } catch (e) {
      _errorMessage = 'Erreur inattendue : $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> creer({
    required String nom,
    String? description,
    String? categorie,
    required double prix,
    required int quantiteDisponible,
    required String unite,
    XFile? image,
  }) async {
    _errorMessage = null;
    _limitePremiumAtteinte = false;
    try {
      final produit = await _service.creer(
        nom: nom,
        description: description,
        categorie: categorie,
        prix: prix,
        quantiteDisponible: quantiteDisponible,
        unite: unite,
        image: image,
      );
      _produits.insert(0, produit);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _limitePremiumAtteinte = e.statusCode == 403 && e.body?['limite_atteinte'] == true;
      notifyListeners();
      return false;
    }
  }

  Future<bool> modifier({
    required int id,
    required String nom,
    String? description,
    String? categorie,
    required double prix,
    required int quantiteDisponible,
    required String unite,
    required String statut,
    XFile? image,
  }) async {
    _errorMessage = null;
    try {
      final produit = await _service.modifier(
        id: id,
        nom: nom,
        description: description,
        categorie: categorie,
        prix: prix,
        quantiteDisponible: quantiteDisponible,
        unite: unite,
        statut: statut,
        image: image,
      );
      final index = _produits.indexWhere((p) => p.id == id);
      if (index != -1) {
        _produits[index] = produit;
      }
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    }
  }

  Future<bool> supprimer(int id) async {
    _errorMessage = null;
    try {
      await _service.supprimer(id);
      _produits.removeWhere((p) => p.id == id);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
      return false;
    }
  }
}
