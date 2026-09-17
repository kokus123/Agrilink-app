import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/abonnement_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/modern_text_field.dart';

class AbonnementScreen extends StatefulWidget {
  const AbonnementScreen({super.key});

  @override
  State<AbonnementScreen> createState() => _AbonnementScreenState();
}

class _AbonnementScreenState extends State<AbonnementScreen> {
  static const int _tarifMensuel = 5000;

  String _operateur = 'mtn';
  final TextEditingController _phoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AbonnementProvider>().chargerStatut();
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AbonnementProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Abonnement Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (provider.errorMessage != null) ErrorBanner(message: provider.errorMessage!),
            _StatutCard(isSubscribed: provider.isSubscribed, expiresAt: provider.subscriptionExpiresAt),
            const SizedBox(height: 24),

            if (provider.isSubscribed) ...[
              const _AvantagesList(),
            ] else if (provider.paiementEnAttenteId == null) ...[
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: AppColors.brandGradient,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 26),
                        const SizedBox(width: 8),
                        const Text(
                          'Forfait Premium',
                          style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          '$_tarifMensuel FCFA',
                          style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(width: 4),
                        const Text('/ mois', style: TextStyle(color: Colors.white70, fontSize: 13)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const _AvantagesList(clair: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ModernButton(
                text: 'Souscrire ($_tarifMensuel FCFA)',
                icon: Icons.workspace_premium_rounded,
                isLoading: provider.isLoading,
                onPressed: () => context.read<AbonnementProvider>().souscrire(),
              ),
            ] else ...[
              const Text(
                'Paiement Mobile Money',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 12),
              if (provider.infoMessage != null)
                Container(
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: AppColors.successBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    provider.infoMessage!,
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'mtn',
                      groupValue: _operateur,
                      onChanged: (v) => setState(() => _operateur = v!),
                      activeColor: AppColors.primary,
                      title: const Text('MTN'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  Expanded(
                    child: RadioListTile<String>(
                      value: 'orange',
                      groupValue: _operateur,
                      onChanged: (v) => setState(() => _operateur = v!),
                      activeColor: AppColors.primary,
                      title: const Text('Orange'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
              ModernTextField(
                controller: _phoneController,
                label: 'Numéro Mobile Money',
                hintText: '+237670000000',
                prefixIcon: Icons.phone_iphone_rounded,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              ModernButton(
                text: 'Payer maintenant',
                icon: Icons.payment_rounded,
                isLoading: provider.isLoading,
                onPressed: () => context.read<AbonnementProvider>().payer(
                      operateur: _operateur,
                      phone: _phoneController.text.trim(),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AvantagesList extends StatelessWidget {
  final bool clair;
  const _AvantagesList({this.clair = false});

  @override
  Widget build(BuildContext context) {
    final couleurTexte = clair ? Colors.white : AppColors.textPrimary;
    final couleurIcone = clair ? Colors.white : AppColors.success;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Avantage(
          icone: Icons.trending_up_rounded,
          texte: 'Booster le profil — tes produits apparaissent en priorité dans le catalogue',
          couleurTexte: couleurTexte,
          couleurIcone: couleurIcone,
        ),
        const SizedBox(height: 10),
        _Avantage(
          icone: Icons.inventory_2_rounded,
          texte: 'Booster publications — plus de limite de 2 produits publiés',
          couleurTexte: couleurTexte,
          couleurIcone: couleurIcone,
        ),
        const SizedBox(height: 10),
        _Avantage(
          icone: Icons.groups_rounded,
          texte: 'Participer à une vente groupée — bientôt disponible',
          couleurTexte: clair ? Colors.white70 : AppColors.textMuted,
          couleurIcone: clair ? Colors.white70 : AppColors.textMuted,
        ),
      ],
    );
  }
}

class _Avantage extends StatelessWidget {
  final IconData icone;
  final String texte;
  final Color couleurTexte;
  final Color couleurIcone;

  const _Avantage({
    required this.icone,
    required this.texte,
    required this.couleurTexte,
    required this.couleurIcone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icone, size: 18, color: couleurIcone),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            texte,
            style: TextStyle(fontSize: 13, color: couleurTexte, height: 1.3),
          ),
        ),
      ],
    );
  }
}

class _StatutCard extends StatelessWidget {
  final bool isSubscribed;
  final DateTime? expiresAt;

  const _StatutCard({required this.isSubscribed, this.expiresAt});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isSubscribed ? AppColors.successBg : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            isSubscribed ? Icons.workspace_premium_rounded : Icons.card_membership_outlined,
            color: isSubscribed ? AppColors.success : AppColors.textSecondary,
            size: 32,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isSubscribed ? 'Compte Premium actif' : 'Compte Standard',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: isSubscribed ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
                if (isSubscribed && expiresAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Renouvellement le ${expiresAt!.day.toString().padLeft(2, '0')}/${expiresAt!.month.toString().padLeft(2, '0')}/${expiresAt!.year}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
