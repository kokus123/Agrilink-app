import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/livraison_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';

class DisponiblesScreen extends StatefulWidget {
  const DisponiblesScreen({super.key});

  @override
  State<DisponiblesScreen> createState() => _DisponiblesScreenState();
}

class _DisponiblesScreenState extends State<DisponiblesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LivraisonProvider>().chargerDisponibles();
    });
  }

  Future<void> _prendreEnCharge(int id) async {
    final ok = await context.read<LivraisonProvider>().prendreEnCharge(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Livraison prise en charge !' : 'Échec — déjà prise par un autre transporteur ?'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LivraisonProvider>();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<LivraisonProvider>().chargerDisponibles(),
        child: provider.isLoading && provider.disponibles.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Disponibles',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Livraisons sans transporteur proposé pour l'instant — à prendre librement",
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (provider.errorMessage != null) ErrorBanner(message: provider.errorMessage!),
                  if (provider.disponibles.isEmpty && !provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          'Aucune livraison disponible pour le moment.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  for (final livraison in provider.disponibles)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  livraison.commande.acheteur.name,
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                                ),
                              ),
                              Text(
                                '${livraison.commande.montantTotal.toStringAsFixed(0)} FCFA',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
                              ),
                            ],
                          ),
                          const Divider(height: 18, color: AppColors.inputBorder),
                          for (final ligne in livraison.commande.produits)
                            Text('${ligne.quantite} × ${ligne.nom}', style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _prendreEnCharge(livraison.id),
                              icon: const Icon(Icons.local_shipping_outlined, size: 18),
                              label: const Text('Prendre en charge'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primary,
                                side: const BorderSide(color: AppColors.primary),
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
