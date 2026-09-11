import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final String? subtitle;

  const BrandLogo({
    super.key,
    this.size = 90,
    this.showText = true,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Conteneur du logo avec ombre douce et reflet subtil
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.12),
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.15),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.25),
              width: 2,
            ),
          ),
          child: Image.asset(
            'assets/images/agrilink_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              // Fallback si l'asset ne charge pas
              return Icon(
                Icons.eco_rounded,
                size: size * 0.55,
                color: AppColors.primary,
              );
            },
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 14),
          RichText(
            textAlign: TextAlign.center,
            text: const TextSpan(
              style: TextStyle(
                fontSize: 28,
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
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ],
    );
  }
}
