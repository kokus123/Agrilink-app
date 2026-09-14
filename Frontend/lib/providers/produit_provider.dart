import 'dart:io';
import 'package:flutter/material.dart';
import '../models/produit_model.dart';
import '../services/api_service.dart';
import '../services/produit_service.dart';

class ProduitProvider extends ChangeNotifier {
  final ProduitService _service = ProduitService();

  List<ProduitModel> _produits = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProduitModel> get produits => _produits;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

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
    File? image,
  }) async {
    _errorMessage = null;
    try {
      final produit = await _service.creer(
        nom: nom,
        description: description,
        categorie: categorie,
        prix: prix,
        quantiteDisponible: quantiteDisponible,
        image: image,
      );
      _produits.insert(0, produit);
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
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
    required String statut,
    File? image,
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
