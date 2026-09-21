import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Bouton plein et plat, sans dégradé ni ombre marquée — inspiré du style
/// "carte pastel minimaliste" demandé pour les écrans de connexion/inscription.
/// Volontairement séparé de [ModernButton] (utilisé ailleurs dans l'app avec
/// son propre style dégradé) pour ne pas modifier les écrans déjà en place.
class FlatActionButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color color;
  final double height;

  const FlatActionButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color = AppColors.accent,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onPressed != null && !isLoading;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isEnabled ? 1.0 : 0.6,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: AppRadius.pill,
          boxShadow: isEnabled ? AppShadows.glow(color) : [],
        ),
        child: Material(
          color: color,
          borderRadius: AppRadius.pill,
          child: InkWell(
            onTap: isEnabled ? onPressed : null,
            borderRadius: AppRadius.pill,
            child: Center(
              child: isLoading
                  ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 20),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(text, style: AppTextStyles.buttonLabel),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}