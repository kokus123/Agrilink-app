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
  static const Map<int, int> _tarifs = {1: 2000, 3: 5500, 6: 10000, 12: 18000};

  int _dureeChoisie = 1;
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

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (provider.errorMessage != null) ErrorBanner(message: provider.errorMessage!),
          _StatutCard(isSubscribed: provider.isSubscribed, expiresAt: provider.subscriptionExpiresAt),
          const SizedBox(height: 24),
          if (provider.paiementEnAttenteId == null) ...[
            const Text(
              'Choisir une durée',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            for (final entry in _tarifs.entries)
              RadioListTile<int>(
                value: entry.key,
                groupValue: _dureeChoisie,
                onChanged: (v) => setState(() => _dureeChoisie = v!),
                activeColor: AppColors.primary,
                title: Text('${entry.key} mois'),
                subtitle: Text('${entry.value} FCFA'),
                contentPadding: EdgeInsets.zero,
              ),
            const SizedBox(height: 12),
            ModernButton(
              text: 'Souscrire (${_tarifs[_dureeChoisie]} FCFA)',
              icon: Icons.card_membership_rounded,
              isLoading: provider.isLoading,
              onPressed: () => context.read<AbonnementProvider>().souscrire(
                    dureeMois: _dureeChoisie,
                    methode: 'mobile_money',
                  ),
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
        gradient: isSubscribed ? AppColors.brandGradient : null,
        color: isSubscribed ? null : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(
            isSubscribed ? Icons.workspace_premium_rounded : Icons.card_membership_outlined,
            color: isSubscribed ? Colors.white : AppColors.textSecondary,
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
                    color: isSubscribed ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                if (isSubscribed && expiresAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Expire le ${expiresAt!.day.toString().padLeft(2, '0')}/${expiresAt!.month.toString().padLeft(2, '0')}/${expiresAt!.year}',
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
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
