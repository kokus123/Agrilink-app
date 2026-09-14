import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/commande_model.dart';
import '../../providers/acheteur_commande_provider.dart';
import '../../providers/notation_provider.dart';
import '../../providers/position_share_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/modifier_commande_sheet.dart';
import '../../widgets/rating_dialog.dart';
import '../../widgets/transporteur_detail_dialog.dart';
import 'chat_detail_screen.dart';

class MesCommandesAcheteurScreen extends StatelessWidget {
  const MesCommandesAcheteurScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotationProvider(),
      child: const _MesCommandesAcheteurBody(),
    );
  }
}

class _MesCommandesAcheteurBody extends StatefulWidget {
  const _MesCommandesAcheteurBody();

  @override
  State<_MesCommandesAcheteurBody> createState() => _MesCommandesAcheteurBodyState();
}

class _MesCommandesAcheteurBodyState extends State<_MesCommandesAcheteurBody> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcheteurCommandeProvider>().charger();
    });
  }

  Future<void> _noter(BuildContext context, int commandeId, AgriculteurACommandeNoter agriculteur) async {
    final resultat = await showRatingDialog(context, agriculteurNom: agriculteur.nom);
    if (resultat == null || !context.mounted) return;

    final ok = await context.read<NotationProvider>().noter(
          commandeId: commandeId,
          agriculteurId: agriculteur.id,
          note: resultat['note'] as int,
          commentaire: resultat['commentaire'] as String?,
        );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Merci pour ton avis !' : "Échec de l'envoi de la note."),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _modifier(BuildContext context, CommandeModel commande) async {
    final lignes = await showModifierCommandeSheet(context, commande: commande);
    if (lignes == null || !context.mounted) return;

    final ok = await context.read<AcheteurCommandeProvider>().modifierCommande(commande.id, lignes);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Commande mise à jour.' : 'Échec de la modification.'),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _annuler(BuildContext context, CommandeModel commande) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Annuler la commande', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Annuler la commande #${commande.id} ? Cette action est irréversible.'),
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

    if (confirme != true || !context.mounted) return;

    final ok = await context.read<AcheteurCommandeProvider>().annulerCommande(commande.id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Commande annulée.' : "Échec de l'annulation."),
          backgroundColor: ok ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcheteurCommandeProvider>();
    final notationProvider = context.watch<NotationProvider>();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<AcheteurCommandeProvider>().charger(),
        child: provider.isLoading && provider.commandes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Mes commandes',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 16),
                  if (provider.errorMessage != null) ErrorBanner(message: provider.errorMessage!),
                  if (notationProvider.errorMessage != null) ErrorBanner(message: notationProvider.errorMessage!),
                  if (provider.commandes.isEmpty && !provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          "Aucune commande pour l'instant.\nParcours le catalogue pour commencer.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  for (final commande in provider.commandes)
                    _CommandeCard(
                      commande: commande,
                      notationProvider: notationProvider,
                      onNoter: (agriculteur) => _noter(context, commande.id, agriculteur),
                      onModifier: () => _modifier(context, commande),
                      onAnnuler: () => _annuler(context, commande),
                    ),
                ],
              ),
      ),
    );
  }
}

class _CommandeCard extends StatelessWidget {
  final CommandeModel commande;
  final NotationProvider notationProvider;
  final void Function(AgriculteurACommandeNoter) onNoter;
  final VoidCallback onModifier;
  final VoidCallback onAnnuler;

  const _CommandeCard({
    required this.commande,
    required this.notationProvider,
    required this.onNoter,
    required this.onModifier,
    required this.onAnnuler,
  });

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
    final livraison = commande.livraison;
    final estLivree = commande.statut == 'livree';

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
              const Text('Total', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              Text(
                '${commande.montantTotal.toStringAsFixed(0)} FCFA',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),

          // Modifier / Annuler — tant que la commande est en_attente
          if (commande.peutEtreModifiee) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onModifier,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Modifier', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onAnnuler,
                    icon: const Icon(Icons.close_rounded, size: 16),
                    label: const Text('Annuler', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Position : optionnel, disponible dès que la commande est active —
          // aide un transporteur disponible à proximité à la repérer, pas
          // besoin d'attendre qu'un transporteur soit déjà assigné.
          if (commande.statut != 'annulee' && commande.statut != 'livree') ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.inputBorder),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.textMuted),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Optionnel : partage ta position pour aider un transporteur proche à te repérer.',
                    style: TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            _PartagerPositionChip(),
          ],

          // Transporteur assigné : discuter / consulter
          if (livraison != null && livraison.transporteurNom != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.inputBorder),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    livraison.transporteurNom!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatDetailScreen(livraisonId: livraison.id, titre: livraison.transporteurNom!),
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
                OutlinedButton.icon(
                  onPressed: () => showTransporteurDialog(
                    context,
                    nom: livraison.transporteurNom!,
                    telephone: livraison.transporteurTelephone,
                  ),
                  icon: const Icon(Icons.info_outline_rounded, size: 15),
                  label: const Text('Consulter transporteur', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.inputBorder),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ],

          if (estLivree && commande.agriculteursDistincts.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.inputBorder),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final agriculteur in commande.agriculteursDistincts)
                  if (notationProvider.dejaNote(commande.id, agriculteur.id))
                    Chip(
                      avatar: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                      label: Text('${agriculteur.nom} noté', style: const TextStyle(fontSize: 12)),
                      backgroundColor: AppColors.successBg,
                      side: BorderSide.none,
                    )
                  else
                    OutlinedButton.icon(
                      onPressed: () => onNoter(agriculteur),
                      icon: const Icon(Icons.star_outline_rounded, size: 16),
                      label: Text('Noter ${agriculteur.nom}', style: const TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.warning,
                        side: const BorderSide(color: AppColors.warning),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

/// Bouton "Partager ma position" autonome — pas besoin du package provider,
/// il porte directement son propre PositionShareProvider.
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
      label: Text(actif ? 'Position partagée' : 'Partager position', style: const TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: actif ? AppColors.success : AppColors.textSecondary,
        side: BorderSide(color: actif ? AppColors.success : AppColors.inputBorder),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
