import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Container de base pour toutes les cartes AGRILINK — fond blanc,
/// bordure fine, ombre presque invisible, padding généreux (brief section 7).
class AgrilinkCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AgrilinkCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.base),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.largeRadius,
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.soft,
      ),
      child: child,
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: AppRadius.largeRadius,
      child: InkWell(
        borderRadius: AppRadius.largeRadius,
        onTap: onTap,
        child: content,
      ),
    );
  }
}

/// Petite carte de statistique pour les dashboards (produits publiés,
/// commandes, revenus...) — brief section 14/15.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackground;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor,
    this.iconBackground,
  });

  @override
  Widget build(BuildContext context) {
    return AgrilinkCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackground ?? AppColors.accentSurface,
              borderRadius: AppRadius.mediumRadius,
            ),
            child: Icon(icon, size: 18, color: iconColor ?? AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.sectionTitle),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

/// Badge pastel pour les statuts (commande, livraison, paiement...).
/// Passe une couleur sémantique (ex: AppColors.success / .warning / .error)
/// et StatusChip calcule automatiquement un fond pastel assorti — brief
/// section 20 ("badges/chips pastel, éviter les couleurs trop fortes").
class StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const StatusChip({super.key, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pill,
      ),
      child: Text(
        label,
        style: AppTextStyles.caption.copyWith(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// En-tête de section réutilisable — titre + action optionnelle ("Voir tout").
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.sectionTitle),
        if (actionLabel != null)
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel!, style: const TextStyle(color: AppColors.accentDark)),
          ),
      ],
    );
  }
}
