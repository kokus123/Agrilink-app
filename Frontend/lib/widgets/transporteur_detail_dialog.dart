import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

void showTransporteurDialog(
  BuildContext context, {
  required String nom,
  String? telephone,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Transporteur', style: TextStyle(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(nom, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (telephone != null && telephone.isNotEmpty)
            Row(
              children: [
                const Icon(Icons.phone_outlined, size: 18, color: AppColors.textSecondary),
                const SizedBox(width: 8),
                SelectableText(telephone, style: const TextStyle(fontSize: 14)),
              ],
            )
          else
            const Text(
              'Numéro non renseigné.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Fermer'),
        ),
      ],
    ),
  );
}
