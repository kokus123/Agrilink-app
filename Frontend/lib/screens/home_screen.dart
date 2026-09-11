import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../config/api_config.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/server_config_dialog.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter de votre compte AgriLink ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/agrilink_logo.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.eco_rounded,
                color: AppColors.accent,
              ),
            ),
            const SizedBox(width: 10),
            RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
                children: [
                  TextSpan(
                    text: 'Agri',
                    style: TextStyle(color: AppColors.primary),
                  ),
                  TextSpan(
                    text: 'Link',
                    style: TextStyle(color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded, color: AppColors.primary),
            tooltip: 'Configuration API',
            onPressed: () => ServerConfigDialog.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Déconnexion',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => authProvider.checkAuth(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Carte Utilisateur moderne avec dégradé
                    Container(
                      padding: const EdgeInsets.all(22.0),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 62,
                                height: 62,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Icon(
                                    user.isAgriculteur
                                        ? Icons.agriculture_rounded
                                        : (user.isAdmin
                                            ? Icons.admin_panel_settings_rounded
                                            : Icons.shopping_basket_rounded),
                                    size: 34,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      user.email,
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          // Badges d'état
                          Row(
                            children: [
                              _StatusChip(
                                label: user.roleLabel.toUpperCase(),
                                icon: Icons.badge_outlined,
                                isHighlight: true,
                              ),
                              const SizedBox(width: 8),
                              _StatusChip(
                                label: user.isActive ? 'COMPTE ACTIF' : 'SUSPENDU',
                                icon: user.isActive
                                    ? Icons.check_circle_outline
                                    : Icons.block,
                                isHighlight: false,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Carte d'informations détaillées
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.inputBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations du profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Divider(height: 24, color: AppColors.inputBorder),
                          _DetailRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Identifiant (ID)',
                            value: '#${user.id}',
                          ),
                          const SizedBox(height: 14),
                          _DetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Téléphone',
                            value: user.phone?.isNotEmpty == true
                                ? user.phone!
                                : 'Non renseigné',
                          ),
                          const SizedBox(height: 14),
                          _DetailRow(
                            icon: Icons.card_membership_outlined,
                            label: 'Abonnement',
                            value: user.isSubscribed
                                ? 'Membre Premium'
                                : 'Compte Standard',
                          ),
                          const SizedBox(height: 14),
                          _DetailRow(
                            icon: Icons.dns_outlined,
                            label: 'Serveur API',
                            value: ApiConfig.baseUrl,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Actions
                    ElevatedButton.icon(
                      onPressed: () async {
                        await authProvider.checkAuth();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Profil mis à jour depuis l\'API Laravel !'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.sync_rounded),
                      label: const Text('Actualiser les informations (/api/me)'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 1,
                      ),
                    ),
                    const SizedBox(height: 12),

                    OutlinedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isHighlight;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.isHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlight
            ? Colors.white
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isHighlight ? AppColors.primary : Colors.white,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isHighlight ? AppColors.primary : Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
