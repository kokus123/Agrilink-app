import 'package:flutter/material.dart';
import '../models/produit_model.dart';
import '../services/api_service.dart';
import '../services/catalogue_service.dart';

class CatalogueProvider extends ChangeNotifier {
  final CatalogueService _service = CatalogueService();

  List<ProduitModel> _produits = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _categorieActive = 'Tous';
  String _recherche = '';

  List<ProduitModel> get produits => _produits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get categorieActive => _categorieActive;

  Future<void> charger() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _produits = await _service.rechercher(
        search: _recherche.isEmpty ? null : _recherche,
        categorie: _categorieActive == 'Tous' ? null : _categorieActive,
      );
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
    } catch (e) {
      _errorMessage = 'Erreur inattendue : $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  void changerCategorie(String categorie) {
    _categorieActive = categorie;
    charger();
  }

  void rechercher(String texte) {
    _recherche = texte;
    charger();
  }
}
