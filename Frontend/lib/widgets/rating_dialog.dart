import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Retourne {'note': int, 'commentaire': String?} ou null si annulé.
Future<Map<String, dynamic>?> showRatingDialog(BuildContext context, {required String agriculteurNom}) {
  return showDialog<Map<String, dynamic>>(
    context: context,
    builder: (context) => _RatingDialog(agriculteurNom: agriculteurNom),
  );
}

class _RatingDialog extends StatefulWidget {
  final String agriculteurNom;
  const _RatingDialog({required this.agriculteurNom});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _note = 0;
  final TextEditingController _commentaireController = TextEditingController();

  @override
  void dispose() {
    _commentaireController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Noter ${widget.agriculteurNom}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final valeur = i + 1;
              return IconButton(
                onPressed: () => setState(() => _note = valeur),
                icon: Icon(
                  valeur <= _note ? Icons.star_rounded : Icons.star_border_rounded,
                  color: AppColors.warning,
                  size: 32,
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _commentaireController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Un commentaire (optionnel)',
              filled: true,
              fillColor: AppColors.inputBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.inputBorder),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: _note == 0
              ? null
              : () => Navigator.pop(context, {
                    'note': _note,
                    'commentaire': _commentaireController.text,
                  }),
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
