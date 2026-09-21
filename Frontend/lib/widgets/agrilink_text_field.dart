import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Champ de saisie AGRILINK — label au-dessus, fond doux, coins arrondis,
/// bascule visible/masqué intégrée pour les mots de passe.
///
/// Utilisation :
/// ```dart
/// AgrilinkTextField(
///   label: 'Mot de passe',
///   controller: _passwordController,
///   icon: Icons.lock_outline,
///   obscureText: true,
///   validator: (v) => (v == null || v.isEmpty) ? 'Champ requis' : null,
/// )
/// ```
class AgrilinkTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;

  const AgrilinkTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
  });

  @override
  State<AgrilinkTextField> createState() => _AgrilinkTextFieldState();
}

class _AgrilinkTextFieldState extends State<AgrilinkTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: AppTextStyles.cardTitle),
        const SizedBox(height: AppSpacing.xs),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          validator: widget.validator,
          onChanged: widget.onChanged,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          style: AppTextStyles.body,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: 20, color: AppColors.textMuted),
            suffixIcon: widget.obscureText
                ? IconButton(
                    icon: Icon(
                      _obscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      size: 20,
                      color: AppColors.textMuted,
                    ),
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
          ),
        ),
      ],
    );
  }
}
