import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../services/stats_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/modern_text_field.dart';

class AgriculteurDashboardScreen extends StatefulWidget {
  const AgriculteurDashboardScreen({super.key});

  @override
  State<AgriculteurDashboardScreen> createState() => _AgriculteurDashboardScreenState();
}

class _AgriculteurDashboardScreenState extends State<AgriculteurDashboardScreen> {
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
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _chargerRevenus,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Text(
                  'Simuler mes revenus',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
              const SizedBox(height: 12),
              _StatCard(
                icon: Icons.storefront_outlined,
                label: 'Produits actifs',
                value: '${_revenus!.nombreProduitsActifs}',
              ),
              if (_revenus!.explication.isNotEmpty) ...[
                const SizedBox(height: 12),
                _EncartExplicationIA(texte: _revenus!.explication),
              ],
            ],
            const SizedBox(height: 32),
            Row(
              children: [
                const Text(
                  'Prédiction de prix par catégorie',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
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
                    Text(
                      'Fourchette : ${_prediction!.prixMin.toStringAsFixed(0)} — ${_prediction!.prixMax.toStringAsFixed(0)} FCFA',
                    ),
                    Text('Échantillon : ${_prediction!.echantillon} produit(s) sur la plateforme'),
                    const SizedBox(height: 8),
                    if (_prediction!.note.isNotEmpty) _EncartExplicationIA(texte: _prediction!.note),
                  ],
                ),
              ),
          ],
        ),
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
