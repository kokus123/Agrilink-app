import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/produit_model.dart';

class CartProvider extends ChangeNotifier {
  final Map<int, CartItem> _items = {};

  List<CartItem> get items => _items.values.toList();
  int get nombreArticles => _items.values.fold(0, (somme, i) => somme + i.quantite);
  double get total => _items.values.fold(0.0, (somme, i) => somme + i.sousTotal);
  bool get estVide => _items.isEmpty;

  void ajouter(ProduitModel produit, {int quantite = 1}) {
    if (_items.containsKey(produit.id)) {
      _items[produit.id]!.quantite += quantite;
    } else {
      _items[produit.id] = CartItem(produit: produit, quantite: quantite);
    }
    notifyListeners();
  }

  void retirer(int produitId) {
    _items.remove(produitId);
    notifyListeners();
  }

  void modifierQuantite(int produitId, int quantite) {
    if (quantite <= 0) {
      retirer(produitId);
      return;
    }
    final item = _items[produitId];
    if (item != null) {
      item.quantite = quantite;
      notifyListeners();
    }
  }

  void vider() {
    _items.clear();
    notifyListeners();
  }
}
