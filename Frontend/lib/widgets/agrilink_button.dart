import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bouton principal AGRILINK — fond vert plein (ou dégradé), texte blanc,
/// coins arrondis, état de chargement intégré.
///
/// Utilisation :
/// ```dart
/// AgrilinkButton(
///   label: 'Publier un produit',
///   onPressed: _publier,
///   isLoading: _envoiEnCours,
///   icon: Icons.add,
/// )
/// ```
class AgrilinkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool useGradient;
  final double height;

  const AgrilinkButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.useGradient = false,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onPressed == null || isLoading;

    final child = isLoading
        ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20, color: Colors.white),
                const SizedBox(width: AppSpacing.sm),
              ],
              Text(label, style: AppTextStyles.buttonLabel),
            ],
          );

    if (!useGradient) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: disabled ? null : onPressed,
          child: child,
        ),
      );
    }

    // Variante dégradé — réservée aux CTA importants (section 4 du brief).
    return Opacity(
      opacity: disabled ? 0.6 : 1,
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.buttonGradient,
            borderRadius: AppRadius.largeRadius,
            boxShadow: disabled ? null : AppShadows.button,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: AppRadius.largeRadius,
              onTap: disabled ? null : onPressed,
              child: Center(child: child),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bouton secondaire — fond transparent, bordure fine, texte vert foncé.
/// Même hauteur que [AgrilinkButton] pour rester aligné visuellement.
class AgrilinkOutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final double height;

  const AgrilinkOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.primary),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(label),
          ],
        ),
      ),
    );
  }
}
