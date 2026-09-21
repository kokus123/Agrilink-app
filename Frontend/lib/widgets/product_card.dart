import 'package:flutter/material.dart';
import '../models/produit_model.dart';
import '../theme/app_theme.dart';

/// Carte produit agricole — utilisée dans le catalogue, le dashboard,
/// les recherches (brief section 7/8).
class ProductCard extends StatelessWidget {
  final String? imageUrl;
  final String nom;
  final int prix;
  final String unite;
  final String? localisation;
  final int? quantiteDisponible;
  final String? producteurNom;
  final bool producteurEstPremium;
  final VoidCallback? onTap;

  const ProductCard({
    super.key,
    this.imageUrl,
    required this.nom,
    required this.prix,
    required this.unite,
    this.localisation,
    this.quantiteDisponible,
    this.producteurNom,
    this.producteurEstPremium = false,
    this.onTap,
  });

  /// Construit directement la carte à partir d'un [ProduitModel] — évite de
  /// ré-extraire les champs à chaque écran (catalogue, dashboard, recherche...).
  factory ProductCard.fromProduit(
      ProduitModel produit, {
        Key? key,
        VoidCallback? onTap,
      }) {
    return ProductCard(
      key: key,
      imageUrl: produit.image,
      nom: produit.nom,
      prix: produit.prix.round(),
      unite: (produit.unite != null && produit.unite!.isNotEmpty) ? produit.unite! : 'unité',
      quantiteDisponible: produit.quantiteDisponible,
      producteurNom: produit.agriculteurName,
      producteurEstPremium: produit.agriculteurEstPremium,
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.largeRadius,
      child: InkWell(
        borderRadius: AppRadius.largeRadius,
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.largeRadius,
            border: Border.all(color: AppColors.border, width: 1),
            boxShadow: AppShadows.soft,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 1.3,
                child: imageUrl == null
                    ? Container(
                  color: AppColors.surfaceMuted,
                  child: const Icon(Icons.eco_outlined, size: 32, color: AppColors.sage),
                )
                    : Image.network(
                  imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceMuted,
                    child: const Icon(Icons.eco_outlined, size: 32, color: AppColors.sage),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nom,
                      style: AppTextStyles.cardTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$prix FCFA / $unite',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (producteurNom != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.storefront_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              producteurNom!,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (producteurEstPremium) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                              decoration: BoxDecoration(
                                color: AppColors.premiumBg,
                                borderRadius: AppRadius.pill,
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star_rounded, size: 11, color: AppColors.premium),
                                  SizedBox(width: 2),
                                  Text(
                                    'Premium',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.premium,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    if (localisation != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              localisation!,
                              style: AppTextStyles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (quantiteDisponible != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        '$quantiteDisponible $unite disponible(s)',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}