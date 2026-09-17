import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/produit_model.dart';
import '../../providers/produit_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import 'produit_form_screen.dart';

class MesProduitsScreen extends StatefulWidget {
  const MesProduitsScreen({super.key});

  @override
  State<MesProduitsScreen> createState() => _MesProduitsScreenState();
}

class _MesProduitsScreenState extends State<MesProduitsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProduitProvider>().charger();
    });
  }

  Future<void> _confirmerSuppression(BuildContext context, ProduitModel produit) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Supprimer le produit', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Supprimer définitivement "${produit.nom}" ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final ok = await context.read<ProduitProvider>().supprimer(produit.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Produit supprimé.' : 'Échec de la suppression.'),
            backgroundColor: ok ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProduitProvider>();

    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: AppColors.primary,
          icon: const Icon(Icons.add_rounded, color: Colors.white),
          label: const Text('Ajouter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProduitFormScreen()),
          ),
        ),
        body: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () => context.read<ProduitProvider>().charger(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mes produits',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (provider.errorMessage != null) ErrorBanner(message: provider.errorMessage!),
              if (provider.isLoading && provider.produits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.produits.isEmpty && !provider.isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: Text(
                      "Aucun produit pour l'instant.\nAjoute ton premier produit avec le bouton +.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                for (final produit in provider.produits)
                  _ProduitCard(
                    produit: produit,
                    onEdit: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ProduitFormScreen(produit: produit)),
                    ),
                    onDelete: () => _confirmerSuppression(context, produit),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProduitCard extends StatelessWidget {
  final ProduitModel produit;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProduitCard({required this.produit, required this.onEdit, required this.onDelete});

  Color get _statutColor {
    switch (produit.statut) {
      case 'disponible':
        return AppColors.success;
      case 'rupture':
        return AppColors.warning;
      default:
        return AppColors.textMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              bottomLeft: Radius.circular(18),
            ),
            child: SizedBox(
              width: 84,
              height: 118,
              child: produit.image != null
                  ? Image.network(
                      produit.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surfaceMuted,
                        child: const Icon(Icons.image_not_supported_outlined, color: AppColors.textMuted),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceMuted,
                      child: const Icon(Icons.photo_outlined, color: AppColors.textMuted, size: 28),
                    ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          produit.nom,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statutColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          produit.statutLabel,
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _statutColor),
                        ),
                      ),
                    ],
                  ),
                  if (produit.categorie != null) ...[
                    const SizedBox(height: 3),
                    Text(produit.categorie!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        '${produit.prix.toStringAsFixed(0)} FCFA',
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Stock : ${produit.quantiteDisponible}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded, size: 16),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
