import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/produit_model.dart';
import '../../providers/produit_provider.dart';
import '../../services/api_service.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/modern_text_field.dart';

class AgriculteurAccueilScreen extends StatefulWidget {
  const AgriculteurAccueilScreen({super.key});

  @override
  State<AgriculteurAccueilScreen> createState() => _AgriculteurAccueilScreenState();
}

class _AgriculteurAccueilScreenState extends State<AgriculteurAccueilScreen> {
  final StatsService _statsService = StatsService();
  final TextEditingController _categorieController = TextEditingController();

  RevenusSimules? _revenus;
  PredictionPrix? _prediction;
  bool _isLoadingRevenus = true;
  bool _isLoadingPrediction = false;
  String? _errorRevenus;
  String? _errorPrediction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProduitProvider>().charger();
    });
    _chargerRevenus();
  }

  @override
  void dispose() {
    _categorieController.dispose();
    super.dispose();
  }

  Future<void> _chargerRevenus() async {
    setState(() {
      _isLoadingRevenus = true;
      _errorRevenus = null;
    });
    try {
      final revenus = await _statsService.simulerRevenus();
      if (mounted) setState(() => _revenus = revenus);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorRevenus = e.userFriendlyMessage);
    } catch (e) {
      if (mounted) setState(() => _errorRevenus = 'Erreur inattendue : $e');
    } finally {
      if (mounted) setState(() => _isLoadingRevenus = false);
    }
  }

  Future<void> _chercherPrediction() async {
    final categorie = _categorieController.text.trim();
    if (categorie.isEmpty) return;

    setState(() {
      _isLoadingPrediction = true;
      _errorPrediction = null;
    });
    try {
      final prediction = await _statsService.predictionPrix(categorie);
      if (mounted) setState(() => _prediction = prediction);
    } on ApiException catch (e) {
      if (mounted) setState(() => _errorPrediction = e.userFriendlyMessage);
    } catch (e) {
      if (mounted) setState(() => _errorPrediction = 'Erreur inattendue : $e');
    } finally {
      if (mounted) setState(() => _isLoadingPrediction = false);
    }
  }

  Color _couleurTendance(String tendance) {
    switch (tendance.toLowerCase()) {
      case 'hausse':
        return AppColors.success;
      case 'baisse':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  IconData _iconeTendance(String tendance) {
    switch (tendance.toLowerCase()) {
      case 'hausse':
        return Icons.trending_up_rounded;
      case 'baisse':
        return Icons.trending_down_rounded;
      default:
        return Icons.trending_flat_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final produitProvider = context.watch<ProduitProvider>();
    final produitsDisponibles = produitProvider.produits.where((p) => p.estDisponible).toList();
    final produitsEnRupture = produitProvider.produits.where((p) => p.statut == 'rupture').toList();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          await context.read<ProduitProvider>().charger();
          await _chargerRevenus();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Accueil',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),

              // --- Aperçu du stock ---
              const Text(
                'Mon stock',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 10),
              if (produitsEnRupture.isNotEmpty)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warningBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 16, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${produitsEnRupture.length} produit(s) en rupture de stock',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              if (produitProvider.isLoading && produitProvider.produits.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (produitsDisponibles.isEmpty)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: const Text(
                    "Aucun produit disponible pour l'instant.",
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.inputBorder),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < produitsDisponibles.length; i++)
                        _LigneStock(
                          produit: produitsDisponibles[i],
                          dernier: i == produitsDisponibles.length - 1,
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 32),

              // --- Insights IA ---
              Row(
                children: [
                  const Text(
                    'Simuler mes revenus',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  const _BadgeIA(),
                ],
              ),
              const SizedBox(height: 12),
              if (_errorRevenus != null) ErrorBanner(message: _errorRevenus!),
              if (_isLoadingRevenus)
                const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()))
              else if (_revenus != null) ...[
                _StatCard(
                  icon: Icons.inventory_2_outlined,
                  label: 'Revenu potentiel (stock actuel)',
                  value: '${_revenus!.revenuPotentielStockActuel.toStringAsFixed(0)} FCFA',
                ),
                const SizedBox(height: 12),
                _StatCard(
                  icon: Icons.trending_up_rounded,
                  label: 'Revenu réaliste estimé',
                  value: '${_revenus!.revenuReelEstime.toStringAsFixed(0)} FCFA',
                ),
                if (_revenus!.explication.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _EncartExplicationIA(texte: _revenus!.explication),
                ],
              ],
              const SizedBox(height: 28),

              Row(
                children: [
                  const Text(
                    'Prédiction de prix',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(width: 8),
                  const _BadgeIA(),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Estimation pour la semaine à venir',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 12),
              ModernTextField(
                controller: _categorieController,
                label: 'Catégorie',
                hintText: 'Ex : Légumes',
                prefixIcon: Icons.category_outlined,
                onFieldSubmitted: (_) => _chercherPrediction(),
              ),
              const SizedBox(height: 12),
              ModernButton(
                text: 'Voir les prix du marché',
                icon: Icons.search_rounded,
                isLoading: _isLoadingPrediction,
                onPressed: _chercherPrediction,
              ),
              const SizedBox(height: 16),
              if (_errorPrediction != null) ErrorBanner(message: _errorPrediction!),
              if (_prediction != null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceMuted,
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
                              _prediction!.categorie,
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _couleurTendance(_prediction!.tendance).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_iconeTendance(_prediction!.tendance), size: 13, color: _couleurTendance(_prediction!.tendance)),
                                const SizedBox(width: 4),
                                Text(
                                  _prediction!.tendance,
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: _couleurTendance(_prediction!.tendance)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Prix moyen : ${_prediction!.prixMoyenMarche.toStringAsFixed(0)} FCFA'),
                      Text('Fourchette : ${_prediction!.prixMin.toStringAsFixed(0)} — ${_prediction!.prixMax.toStringAsFixed(0)} FCFA'),
                      Text('Échantillon : ${_prediction!.echantillon} produit(s) sur la plateforme'),
                      const SizedBox(height: 8),
                      if (_prediction!.note.isNotEmpty) _EncartExplicationIA(texte: _prediction!.note),
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

class _LigneStock extends StatelessWidget {
  final ProduitModel produit;
  final bool dernier;
  const _LigneStock({required this.produit, required this.dernier});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: dernier ? null : const Border(bottom: BorderSide(color: AppColors.inputBorder)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 40,
              height: 40,
              child: produit.image != null
                  ? Image.network(
                      produit.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        color: AppColors.surfaceMuted,
                        child: const Icon(Icons.photo_outlined, size: 18, color: AppColors.textMuted),
                      ),
                    )
                  : Container(
                      color: AppColors.surfaceMuted,
                      child: const Icon(Icons.photo_outlined, size: 18, color: AppColors.textMuted),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              produit.nom,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
          Text(
            '${produit.quantiteDisponible}',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
          const SizedBox(width: 4),
          const Text('en stock', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _BadgeIA extends StatelessWidget {
  const _BadgeIA();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome_rounded, size: 11, color: Colors.white),
          SizedBox(width: 3),
          Text('IA', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white)),
        ],
      ),
    );
  }
}

class _EncartExplicationIA extends StatelessWidget {
  final String texte;
  const _EncartExplicationIA({required this.texte});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.successBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_rounded, size: 16, color: AppColors.success),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texte,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.inputBorder),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surfaceMuted, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
