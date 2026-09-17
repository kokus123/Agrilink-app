import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../services/profile_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import '../../widgets/modern_button.dart';
import '../../widgets/modern_text_field.dart';

/// Écran de modification de profil, commun aux 4 rôles (Agriculteur,
/// Acheteur, Transporteur, Administrateur) — "Gérer son profil" hérité de
/// l'acteur abstrait Utilisateur sur le diagramme.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final ProfileService _service = ProfileService();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _newPasswordConfirmController = TextEditingController();

  bool _changerMotDePasse = false;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _newPasswordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _enregistrer() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      await _service.mettreAJour(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        currentPassword: _changerMotDePasse ? _currentPasswordController.text : null,
        newPassword: _changerMotDePasse ? _newPasswordController.text : null,
        newPasswordConfirmation: _changerMotDePasse ? _newPasswordConfirmController.text : null,
      );

      // Rafraîchit les infos partout dans l'app (déjà exposé par AuthProvider,
      // utilisé par le bouton "Actualiser" de l'écran de profil).
      if (mounted) {
        await context.read<AuthProvider>().checkAuth();
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil mis à jour.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      setState(() => _errorMessage = e.userFriendlyMessage);
    } catch (e) {
      setState(() => _errorMessage = 'Erreur inattendue : $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Mon profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_errorMessage != null) ErrorBanner(message: _errorMessage!),

              ModernTextField(
                controller: _nameController,
                label: 'Nom complet',
                prefixIcon: Icons.person_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Le nom est requis.' : null,
              ),
              const SizedBox(height: 16),
              ModernTextField(
                controller: _emailController,
                label: 'Adresse email',
                prefixIcon: Icons.alternate_email_rounded,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return "L'email est requis.";
                  if (!v.contains('@') || !v.contains('.')) return 'Email invalide.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ModernTextField(
                controller: _phoneController,
                label: 'Téléphone',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 24),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _changerMotDePasse,
                onChanged: (v) => setState(() => _changerMotDePasse = v),
                activeThumbColor: AppColors.primary,
                title: const Text('Changer le mot de passe', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),

              if (_changerMotDePasse) ...[
                const SizedBox(height: 8),
                ModernTextField(
                  controller: _currentPasswordController,
                  label: 'Mot de passe actuel',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: true,
                  validator: (v) => _changerMotDePasse && (v == null || v.isEmpty)
                      ? 'Requis pour changer le mot de passe.'
                      : null,
                ),
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _newPasswordController,
                  label: 'Nouveau mot de passe',
                  hintText: '8 caractères minimum',
                  prefixIcon: Icons.lock_reset_rounded,
                  obscureText: true,
                  validator: (v) {
                    if (!_changerMotDePasse) return null;
                    if (v == null || v.isEmpty) return 'Requis.';
                    if (v.length < 8) return 'Au moins 8 caractères.';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ModernTextField(
                  controller: _newPasswordConfirmController,
                  label: 'Confirmer le nouveau mot de passe',
                  prefixIcon: Icons.lock_clock_outlined,
                  obscureText: true,
                  validator: (v) {
                    if (!_changerMotDePasse) return null;
                    if (v != _newPasswordController.text) return 'Les mots de passe ne correspondent pas.';
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 28),
              ModernButton(
                text: 'Enregistrer',
                icon: Icons.check_rounded,
                isLoading: _isSaving,
                onPressed: _enregistrer,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
