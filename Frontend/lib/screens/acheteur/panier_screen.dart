import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item_model.dart';
import '../../providers/acheteur_commande_provider.dart';
import '../../providers/cart_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/modern_button.dart';

class PanierScreen extends StatefulWidget {
  const PanierScreen({super.key});

  @override
  State<PanierScreen> createState() => _PanierScreenState();
}

class _PanierScreenState extends State<PanierScreen> {
  Future<void> _passerCommande() async {
    final panier = context.read<CartProvider>();
    final commandeProvider = context.read<AcheteurCommandeProvider>();

    final ok = await commandeProvider.passerCommande(panier.items);
    if (ok && mounted) {
      panier.vider();
    }
  }

  @override
  Widget build(BuildContext context) {
    final panier = context.watch<CartProvider>();
    final commandeProvider = context.watch<AcheteurCommandeProvider>();
    final commandeCreee = commandeProvider.derniereCommande;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon panier')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (commandeProvider.errorMessage != null)
              ErrorBanner(message: commandeProvider.errorMessage!),

            if (commandeCreee == null) ...[
              if (panier.estVide)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text('Ton panier est vide.', style: TextStyle(color: AppColors.textSecondary)),
                  ),
                )
              else ...[
                for (final item in panier.items) _LigneArticle(item: item),
                const Divider(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(
                      '${panier.total.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ModernButton(
                  text: 'Passer la commande',
                  icon: Icons.check_circle_outline_rounded,
                  isLoading: commandeProvider.isLoading,
                  onPressed: _passerCommande,
                ),
              ],
            ] else ...[
              // Confirmation — le règlement se fait hors de l'application,
              // directement entre l'acheteur et l'agriculteur/transporteur.
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: AppColors.successBg, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 26),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Commande #${commandeCreee.id} enregistrée',
                            style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w800, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Total : ${commandeCreee.montantTotal.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Le règlement se fait directement avec l'agriculteur ou à la livraison. Suis ton statut dans l'onglet \"Commandes\".",
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ModernButton(
                text: 'Retour au catalogue',
                icon: Icons.storefront_outlined,
                onPressed: () {
                  commandeProvider.reinitialiserConfirmation();
                  Navigator.pop(context);
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LigneArticle extends StatelessWidget {
  final CartItem item;
  const _LigneArticle({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.produit.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  '${item.produit.prix.toStringAsFixed(0)} FCFA / unité',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline, size: 20),
            onPressed: () => context.read<CartProvider>().modifierQuantite(item.produit.id, item.quantite - 1),
          ),
          Text('${item.quantite}', style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.add_circle_outline, size: 20),
            onPressed: () => context.read<CartProvider>().modifierQuantite(item.produit.id, item.quantite + 1),
          ),
        ],
      ),
    );
  }
}
