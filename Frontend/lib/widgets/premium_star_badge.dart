import 'package:flutter/material.dart';

/// Petite étoile dorée signalant un compte premium — à placer juste après
/// un nom (ex: "Miguel ⭐"). Réutilisable partout où un nom d'agriculteur
/// est affiché : Profil, cartes produit du catalogue, future liste
/// d'utilisateurs côté Administrateur.
class PremiumStarBadge extends StatelessWidget {
  final double size;
  const PremiumStarBadge({super.key, this.size = 14});

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.star_rounded, size: size, color: const Color(0xFFFFC107));
  }
}
