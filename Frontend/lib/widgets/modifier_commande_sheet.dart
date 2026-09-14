import 'package:flutter/material.dart';
import '../models/commande_model.dart';
import '../theme/app_theme.dart';
import 'modern_button.dart';

/// Retourne la liste de lignes [{'id': ..., 'quantite': ...}] si l'utilisateur
/// valide, ou null s'il annule. Une quantité ramenée à 0 retire la ligne.
Future<List<Map<String, int>>?> showModifierCommandeSheet(
  BuildContext context, {
  required CommandeModel commande,
}) {
  return showModalBottomSheet<List<Map<String, int>>>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => _ModifierCommandeSheet(commande: commande),
  );
}

class _ModifierCommandeSheet extends StatefulWidget {
  final CommandeModel commande;
  const _ModifierCommandeSheet({required this.commande});

  @override
  State<_ModifierCommandeSheet> createState() => _ModifierCommandeSheetState();
}

class _ModifierCommandeSheetState extends State<_ModifierCommandeSheet> {
  late Map<int, int> _quantites;

  @override
  void initState() {
    super.initState();
    _quantites = {for (final ligne in widget.commande.produits) ligne.id: ligne.quantite};
  }

  double get _total {
    var total = 0.0;
    for (final ligne in widget.commande.produits) {
      total += ligne.prixUnitaire * (_quantites[ligne.id] ?? 0);
    }
    return total;
  }

  void _valider() {
    final lignes = widget.commande.produits
        .where((l) => (_quantites[l.id] ?? 0) > 0)
        .map((l) => {'id': l.id, 'quantite': _quantites[l.id]!})
        .toList();

    if (lignes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('La commande ne peut pas être vide.')),
      );
      return;
    }

    Navigator.pop(context, lignes);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Modifier la commande #${widget.commande.id}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          for (final ligne in widget.commande.produits)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ligne.nom, style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          '${ligne.prixUnitaire.toStringAsFixed(0)} FCFA / unité',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, size: 20),
                    onPressed: () => setState(() {
                      final actuel = _quantites[ligne.id] ?? 0;
                      if (actuel > 0) _quantites[ligne.id] = actuel - 1;
                    }),
                  ),
                  Text('${_quantites[ligne.id] ?? 0}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline, size: 20),
                    onPressed: () => setState(() {
                      _quantites[ligne.id] = (_quantites[ligne.id] ?? 0) + 1;
                    }),
                  ),
                ],
              ),
            ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Nouveau total', style: TextStyle(fontWeight: FontWeight.w700)),
              Text(
                '${_total.toStringAsFixed(0)} FCFA',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ModernButton(text: 'Enregistrer les modifications', onPressed: _valider),
        ],
      ),
    );
  }
}
