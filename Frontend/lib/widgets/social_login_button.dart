import 'package:flutter/material.dart';

/// Bouton social — actuellement décoratif : le backend Laravel n'a pas
/// encore de package OAuth (Socialite) installé, donc onTap affiche un
/// message "bientôt disponible" plutôt que de tenter une vraie
/// authentification.
class SocialLoginButton extends StatelessWidget {
  final String label;
  final Widget leading;
  final Color background;
  final Color textColor;
  final Color? border;
  final VoidCallback onTap;

  const SocialLoginButton({
    super.key,
    required this.label,
    required this.leading,
    required this.background,
    required this.textColor,
    required this.onTap,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(27),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(27),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(27),
              border: border != null ? Border.all(color: border!, width: 1.2) : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading,
                const SizedBox(width: 10),
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Petit badge "G" coloré — approximation du logo Google sans en reproduire
/// l'asset exact (que je n'ai pas le droit d'incorporer directement).
class GoogleBadge extends StatelessWidget {
  const GoogleBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xFFEA4335),
        borderRadius: BorderRadius.circular(7),
      ),
      alignment: Alignment.center,
      child: const Text(
        'G',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 13,
        ),
      ),
    );
  }
}
