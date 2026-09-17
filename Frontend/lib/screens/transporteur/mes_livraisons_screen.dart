import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/livraison_model.dart';
import '../../providers/livraison_provider.dart';
import '../../providers/position_share_provider.dart';
import '../../services/livraison_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../acheteur/chat_detail_screen.dart';
import '../live_map_screen.dart';

class MesLivraisonsScreen extends StatefulWidget {
  const MesLivraisonsScreen({super.key});

  @override
  State<MesLivraisonsScreen> createState() => _MesLivraisonsScreenState();
}

class _MesLivraisonsScreenState extends State<MesLivraisonsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<LivraisonProvider>().chargerMesLivraisons();
    });
  }

  Future<void> _marquerLivree(int id) async {
    final ok = await context.read<LivraisonProvider>().marquerLivree(id);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Livraison marquée comme livrée !' : 'Échec.'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _annuler(int id) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Annuler cette livraison ?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Non', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirme == true && mounted) {
      final ok = await context.read<LivraisonProvider>().annuler(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(ok ? 'Livraison annulée.' : "Échec de l'annulation."),
            backgroundColor: ok ? AppColors.success : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<LivraisonProvider>();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<LivraisonProvider>().chargerMesLivraisons(),
        child: provider.isLoading && provider.mesLivraisons.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Mes livraisons',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  if (provider.errorMessage != null) ErrorBanner(message: provider.errorMessage!),
                  if (provider.mesLivraisons.isEmpty && !provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          "Aucune livraison acceptée pour l'instant.",
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  for (final livraison in provider.mesLivraisons)
                    _LivraisonCard(
                      livraison: livraison,
                      onMarquerLivree: () => _marquerLivree(livraison.id),
                      onAnnuler: () => _annuler(livraison.id),
                    ),
                ],
              ),
      ),
    );
  }
}

class _LivraisonCard extends StatelessWidget {
  final LivraisonModel livraison;
  final VoidCallback onMarquerLivree;
  final VoidCallback onAnnuler;

  const _LivraisonCard({
    required this.livraison,
    required this.onMarquerLivree,
    required this.onAnnuler,
  });

  Color get _statutColor {
    switch (livraison.statut) {
      case 'livree':
        return AppColors.success;
      case 'annulee':
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final commande = livraison.commande;
    final enCours = livraison.statut == 'en_cours';

    return Container(
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
                  commande.acheteur.name,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statutColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  livraison.statutLabel,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _statutColor),
                ),
              ),
            ],
          ),
          const Divider(height: 18, color: AppColors.inputBorder),
          for (final ligne in commande.produits)
            Text('${ligne.quantite} × ${ligne.nom}', style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            '${commande.montantTotal.toStringAsFixed(0)} FCFA',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          if (enCours) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(livraisonId: livraison.id, titre: commande.acheteur.name),
                    ),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 15),
                  label: const Text('Discuter', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
                if (commande.acheteur.aPartagePosition)
                  OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LiveMapScreen(
                          titre: 'Position de ${commande.acheteur.name}',
                          labelMarqueur: commande.acheteur.name,
                          fetchPosition: () => LivraisonService().getPositionAcheteur(livraison.id),
                        ),
                      ),
                    ),
                    icon: const Icon(Icons.map_outlined, size: 15),
                    label: const Text('Sa position', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      side: const BorderSide(color: AppColors.inputBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                  ),
                _PartagerPositionChip(),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onAnnuler,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Annuler', style: TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onMarquerLivree,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Marquer livrée', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Bouton "Partager ma position" autonome (même principe que côté Acheteur)
/// — utile pendant une livraison en_cours pour que l'acheteur puisse suivre
/// le transporteur en temps réel sur sa carte.
class _PartagerPositionChip extends StatefulWidget {
  @override
  State<_PartagerPositionChip> createState() => _PartagerPositionChipState();
}

class _PartagerPositionChipState extends State<_PartagerPositionChip> {
  final PositionShareProvider _position = PositionShareProvider();

  @override
  void initState() {
    super.initState();
    _position.addListener(_onChange);
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  Future<void> _basculer() async {
    if (_position.isActive) {
      _position.arreter();
    } else {
      await _position.demarrer();
      if (_position.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_position.errorMessage!), backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  void dispose() {
    _position.removeListener(_onChange);
    _position.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final actif = _position.isActive;
    return OutlinedButton.icon(
      onPressed: _position.isLoading ? null : _basculer,
      icon: _position.isLoading
          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(actif ? Icons.location_on_rounded : Icons.location_off_outlined, size: 15),
      label: Text(actif ? 'Position partagée' : 'Partager ma position', style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: actif ? AppColors.success : AppColors.textSecondary,
        side: BorderSide(color: actif ? AppColors.success : AppColors.inputBorder),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
