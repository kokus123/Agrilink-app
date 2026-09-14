import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Illustration en tête des écrans login/register.
///
/// Si [imagePath] est fourni et que le fichier existe dans les assets,
/// l'image est affichée directement. Sinon (asset absent), l'écran retombe
/// silencieusement sur une composition plate statique construite en
/// Flutter pur — rien ne casse.
class AuthIllustration extends StatelessWidget {
  final IconData centerIcon;
  final String? imagePath;
  final double size;

  const AuthIllustration({
    super.key,
    required this.centerIcon,
    this.imagePath,
    this.size = 190,
  });

  @override
  Widget build(BuildContext context) {
    if (imagePath != null) {
      return Center(
        child: SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            imagePath!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => _StaticIllustration(
              centerIcon: centerIcon,
              size: size,
            ),
          ),
        ),
      );
    }

    return _StaticIllustration(centerIcon: centerIcon, size: size);
  }
}

/// Composition plate originale (disque doux + carte inclinée + badge
/// flottant) — utilisée tant qu'aucune image n'est fournie.
class _StaticIllustration extends StatelessWidget {
  final IconData centerIcon;
  final double size;

  const _StaticIllustration({required this.centerIcon, required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          children: [
            Container(
              width: size,
              height: size,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.successBg,
              ),
            ),
            Positioned(
              left: size * 0.185,
              top: size * 0.105,
              child: Transform.rotate(
                angle: -0.08,
                child: Container(
                  width: size * 0.63,
                  height: size * 0.79,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.16),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(centerIcon, color: AppColors.accent, size: 36),
                      const SizedBox(height: 14),
                      for (final w in [1.0, 0.7, 0.85])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: FractionallySizedBox(
                            widthFactor: w,
                            child: Container(
                              height: 7,
                              decoration: BoxDecoration(
                                color: AppColors.inputBorder,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: size * 0.03,
              right: size * 0.05,
              child: Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 26),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
