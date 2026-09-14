import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/commande_model.dart';
import '../../providers/commande_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';

class MesCommandesScreen extends StatefulWidget {
  const MesCommandesScreen({super.key});

  @override
  State<MesCommandesScreen> createState() => _MesCommandesScreenState();
}

class _MesCommandesScreenState extends State<MesCommandesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CommandeProvider>().charger();
    });
  }

  Future<void> _notifier(BuildContext context, int commandeId) async {
    final ok = await context.read<CommandeProvider>().notifierTransporteur(commandeId);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Transporteur notifié.' : 'Échec de la notification.'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CommandeProvider>();

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () => context.read<CommandeProvider>().charger(),
      child: provider.isLoading && provider.commandes.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                if (provider.errorMessage != null) ErrorBanner(message: provider.errorMessage!),
                if (provider.commandes.isEmpty && !provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 60),
                    child: Center(
                      child: Text(
                        'Aucune commande reçue pour l\'instant.',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                for (final commande in provider.commandes)
                  _CommandeCard(
                    commande: commande,
                    onNotifier: () => _notifier(context, commande.id),
                  ),
              ],
            ),
    );
  }
}

class _CommandeCard extends StatelessWidget {
  final CommandeModel commande;
  final VoidCallback onNotifier;

  const _CommandeCard({required this.commande, required this.onNotifier});

  Color get _statutColor {
    switch (commande.statut) {
      case 'livree':
        return AppColors.success;
      case 'annulee':
        return AppColors.error;
      case 'en_attente':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Commande #${commande.id}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statutColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  commande.statutLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statutColor),
                ),
              ),
            ],
          ),
          if (commande.acheteur != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.person_outline_rounded, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(commande.acheteur!.name, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                if (commande.acheteur!.phone != null) ...[
                  const SizedBox(width: 10),
                  const Icon(Icons.phone_outlined, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text(commande.acheteur!.phone!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ],
            ),
          ],
          const Divider(height: 20, color: AppColors.inputBorder),
          for (final ligne in commande.produits)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Expanded(child: Text('${ligne.quantite} × ${ligne.nom}', style: const TextStyle(fontSize: 13))),
                  Text('${ligne.sousTotal.toStringAsFixed(0)} FCFA', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total (mes produits)', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(
                '${commande.totalProduitsListes.toStringAsFixed(0)} FCFA',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          if (commande.livraison != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  commande.livraison!.transporteurNom != null
                      ? 'Livraison : ${commande.livraison!.transporteurNom}'
                      : 'Livraison en attente de prise en charge',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
          if (commande.peutNotifierTransporteur) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onNotifier,
                icon: const Icon(Icons.local_shipping_outlined, size: 18),
                label: const Text('Notifier un transporteur'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
