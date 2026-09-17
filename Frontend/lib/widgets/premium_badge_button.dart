import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/agriculteur/abonnement_screen.dart';

/// Badge "PRO" façon Canva — clique dessus pour aller vers la page
/// d'abonnement premium. Style différent selon que l'agriculteur est déjà
/// abonné ou non. Utilisé dans l'AppBar de l'espace Agriculteur.
class PremiumBadgeButton extends StatelessWidget {
  final bool estAbonne;
  const PremiumBadgeButton({super.key, required this.estAbonne});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const AbonnementScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          gradient: estAbonne
              ? null
              : const LinearGradient(
                  colors: [Color(0xFFFFC107), Color(0xFFFF8F00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: estAbonne ? AppColors.successBg : null,
          borderRadius: BorderRadius.circular(20),
          boxShadow: estAbonne
              ? null
              : [
                  BoxShadow(
                    color: const Color(0xFFFF8F00).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              estAbonne ? Icons.workspace_premium_rounded : Icons.bolt_rounded,
              size: 14,
              color: estAbonne ? AppColors.success : Colors.white,
            ),
            const SizedBox(width: 4),
            Text(
              estAbonne ? 'PREMIUM' : 'PRO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
                color: estAbonne ? AppColors.success : Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
