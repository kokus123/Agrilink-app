import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/produit_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/catalogue_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/premium_star_badge.dart';
import 'panier_screen.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Le backend ne fournit pas de liste fixe de catégories (categorie est un
  // champ texte libre côté produit) — ce sont des filtres usuels, à ajuster
  // si les agriculteurs utilisent d'autres libellés.
  static const List<String> _categories = ['Tous', 'Légumes', 'Fruits', 'Céréales', 'Tubercules'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CatalogueProvider>().charger();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueProvider>();
    final panier = context.watch<CartProvider>();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'AgriLink',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary),
                  ),
                ),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PanierScreen()),
                      ),
                    ),
                    if (panier.nombreArticles > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
                          constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                          child: Text(
                            '${panier.nombreArticles}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                border: Border.all(color: AppColors.inputBorder),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search_rounded, size: 18, color: AppColors.textSecondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onSubmitted: (v) => context.read<CatalogueProvider>().rechercher(v),
                      decoration: const InputDecoration(
                        hintText: 'Rechercher un produit...',
                        hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          SizedBox(
            height: 36,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final categorie = _categories[index];
                final active = categorie == catalogue.categorieActive;
                return GestureDetector(
                  onTap: () => context.read<CatalogueProvider>().changerCategorie(categorie),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: active ? AppColors.accent : Colors.white,
                      border: active ? null : Border.all(color: AppColors.inputBorder),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      categorie,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: active ? AppColors.primary : AppColors.textSecondary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          if (catalogue.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: ErrorBanner(message: catalogue.errorMessage!),
            ),

          Expanded(
            child: RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<CatalogueProvider>().charger(),
              child: catalogue.isLoading && catalogue.produits.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : catalogue.produits.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: const [
                            Padding(
                              padding: EdgeInsets.symmetric(vertical: 80),
                              child: Center(
                                child: Text(
                                  'Aucun produit ne correspond à ta recherche.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ],
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                          physics: const AlwaysScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: catalogue.produits.length,
                          itemBuilder: (context, index) => _ProduitCard(produit: catalogue.produits[index]),
                        ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProduitCard extends StatelessWidget {
  final ProduitModel produit;
  const _ProduitCard({required this.produit});

  Widget _placeholderImage({bool loading = false}) {
    return Container(
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: loading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.photo_outlined, color: AppColors.textMuted, size: 26),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.inputBorder),
        borderRadius: BorderRadius.circular(16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1.3,
            child: produit.image != null
                ? Image.network(
                    produit.image!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => _placeholderImage(),
                    loadingBuilder: (context, child, progress) =>
                        progress == null ? child : _placeholderImage(loading: true),
                  )
                : _placeholderImage(),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  produit.nom,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.storefront_outlined, size: 11, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Expanded(
                      child: Text(
                        produit.agriculteurName ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ),
                    if (produit.agriculteurEstPremium) ...[
                      const SizedBox(width: 3),
                      const PremiumStarBadge(size: 11),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${produit.prix.toStringAsFixed(0)} FCFA',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.read<CartProvider>().ajouter(produit);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${produit.nom} ajouté au panier'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppColors.primary,
                          ),
                        );
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                        child: const Icon(Icons.shopping_cart_outlined, size: 13, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
