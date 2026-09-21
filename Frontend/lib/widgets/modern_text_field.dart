import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModernTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hintText;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final String? Function(String?)? validator;
  final String? errorText;
  final bool autofocus;

  const ModernTextField({
    super.key,
    required this.controller,
    required this.label,
    this.hintText,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.validator,
    this.errorText,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.fieldLabel),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          validator: validator,
          autofocus: autofocus,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              fontSize: 14,
              color: AppColors.textMuted.withValues(alpha: 0.8),
              fontWeight: FontWeight.normal,
            ),
            errorText: errorText,
            errorMaxLines: 2,
            errorStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.error,
            ),
            filled: true,
            fillColor: AppColors.inputBg,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.base,
              vertical: AppSpacing.base,
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: AppSpacing.sm),
              child: Icon(
                prefixIcon,
                color: AppColors.textSecondary,
                size: 22,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 46,
              minHeight: 24,
            ),
            suffixIcon: suffixIcon,
            border: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: const BorderSide(color: AppColors.inputBorder, width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: const BorderSide(color: AppColors.error, width: 1.2),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.mediumRadius,
              borderSide: const BorderSide(color: AppColors.error, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}