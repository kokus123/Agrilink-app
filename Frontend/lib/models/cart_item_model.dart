import 'produit_model.dart';

/// Un article du panier — purement local. Le backend ne connaît le panier
/// qu'au moment où POST /commandes est appelé avec la liste finale.
class CartItem {
  final ProduitModel produit;
  int quantite;

  CartItem({required this.produit, this.quantite = 1});

  double get sousTotal => produit.prix * quantite;
}
