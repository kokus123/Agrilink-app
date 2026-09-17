import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/livraison_model.dart';
import '../../providers/livraison_provider.dart';
import '../../services/livraison_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../live_map_screen.dart';

class PropositionsScreen extends StatefulWidget {
  const PropositionsScreen({super.key});

  @override
  State<PropositionsScreen> createState() => _PropositionsScreenState();
}

class _PropositionsScreenState extends State<PropositionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LivraisonProvider>().chargerPropositions();
    });
  }

  Future<void> _accepter(int id) async {
    final ok = await context.read<LivraisonProvider>().accepter(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Livraison acceptée !' : "Échec de l'acceptation."),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _refuser(int id) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Refuser cette livraison ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Elle sera proposée à un autre transporteur disponible.'),
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
            child: const Text('Refuser'),
          ),
        ],
      ),
    );

    if (confirme == true && mounted) {
      final ok = await context.read<LivraisonProvider>().refuser(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Livraison refusée.' : "Échec du refus."),
            backgroundColor: ok ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _voirPositionAcheteur(LivraisonModel livraison) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveMapScreen(
          titre: 'Position de ${livraison.commande.acheteur.name}',
          labelMarqueur: livraison.commande.acheteur.name,
          fetchPosition: () => LivraisonService().getPositionAcheteur(livraison.id),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LivraisonProvider>();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<LivraisonProvider>().chargerPropositions(),
        child: provider.isLoading && provider.propositions.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Propositions',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Livraisons proposées selon ta position',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (provider.errorMessage != null) ErrorBanner(message: provider.errorMessage!),
                  if (provider.propositions.isEmpty && !provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          'Aucune proposition pour le moment.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  for (final livraison in provider.propositions)
                    _PropositionCard(
                      livraison: livraison,
                      onAccepter: () => _accepter(livraison.id),
                      onRefuser: () => _refuser(livraison.id),
                      onVoirPosition: () => _voirPositionAcheteur(livraison),
                    ),
                ],
              ),
      ),
    );
  }
}

class _PropositionCard extends StatelessWidget {
  final LivraisonModel livraison;
  final VoidCallback onAccepter;
  final VoidCallback onRefuser;
  final VoidCallback onVoirPosition;

  const _PropositionCard({
    required this.livraison,
    required this.onAccepter,
    required this.onRefuser,
    required this.onVoirPosition,
  });

  @override
  Widget build(BuildContext context) {
    final commande = livraison.commande;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  commande.acheteur.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
              Text(
                '${commande.montantTotal.toStringAsFixed(0)} FCFA',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const Divider(height: 20, color: AppColors.inputBorder),
          for (final ligne in commande.produits)
            Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Text('${ligne.quantite} × ${ligne.nom}', style: const TextStyle(fontSize: 13)),
            ),
          const SizedBox(height: 12),
          if (commande.acheteur.aPartagePosition)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: OutlinedButton.icon(
                onPressed: onVoirPosition,
                icon: const Icon(Icons.map_outlined, size: 16),
                label: const Text('Voir sur la carte', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.inputBorder),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRefuser,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Refuser'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccepter,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Accepter'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
