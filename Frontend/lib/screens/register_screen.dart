import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/auth_illustration.dart';
import '../widgets/error_banner.dart';
import '../widgets/flat_action_button.dart';
import '../widgets/modern_text_field.dart';
import '../widgets/role_selector_card.dart';
import '../widgets/social_login_button.dart';
import 'home_screen.dart';

/// Vert tiré de l'illustration register_screen.png — même teinte que
/// login_screen.dart (même illustration), pour que le bouton reste
/// cohérent avec l'image au-dessus.
const _kCouleurIllustration = Color(0xFF4CBB6C);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();

  String _selectedRole = 'agriculteur'; // 'agriculteur' ou 'acheteur'
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature — bientôt disponible.'),
        backgroundColor: AppColors.textSecondary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.register(
      name: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      password: _passwordController.text,
      passwordConfirmation: _passwordConfirmController.text,
      role: _selectedRole,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Compte créé avec succès ! Bienvenue, ${authProvider.user?.name ?? ''}.',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary, size: 20),
                        onPressed: () {
                          authProvider.clearErrors();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                const AuthIllustration(
                  centerIcon: Icons.person_add_alt_1_rounded,
                  imagePath: 'assets/images/register_screen.png',
                ),
                const SizedBox(height: 22),

                const Text(
                  'Créer un compte',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Rejoignez AgriLink dès maintenant',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 26),

                const Text(
                  'Vous êtes',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    RoleSelectorCard(
                      title: 'Agriculteur',
                      badgeText: 'Vendeur',
                      description: 'Je propose et vends mes récoltes',
                      icon: Icons.agriculture_rounded,
                      isSelected: _selectedRole == 'agriculteur',
                      fillColor: AppColors.successBg,
                      accentColor: AppColors.success,
                      onTap: () {
                        setState(() {
                          _selectedRole = 'agriculteur';
                        });
                      },
                    ),
                    const SizedBox(width: 12),
                    RoleSelectorCard(
                      title: 'Acheteur',
                      badgeText: 'Client',
                      description: "J'achète des produits locaux",
                      icon: Icons.shopping_bag_rounded,
                      isSelected: _selectedRole == 'acheteur',
                      fillColor: AppColors.warningBg,
                      accentColor: AppColors.warning,
                      onTap: () {
                        setState(() {
                          _selectedRole = 'acheteur';
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                if (authProvider.errorMessage != null)
                  ErrorBanner(
                    message: authProvider.errorMessage!,
                    onDismiss: () => authProvider.clearErrors(),
                  ),

                ModernTextField(
                  controller: _nameController,
                  label: 'Nom complet',
                  hintText: 'Entrez votre nom complet',
                  prefixIcon: Icons.person_outline_rounded,
                  textInputAction: TextInputAction.next,
                  errorText: authProvider.getFieldError('name'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir votre nom';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                ModernTextField(
                  controller: _emailController,
                  label: 'Adresse email',
                  hintText: 'exemple@gmail.com',
                  prefixIcon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  errorText: authProvider.getFieldError('email'),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Veuillez saisir votre email';
                    }
                    if (!value.contains('@') || !value.contains('.')) {
                      return 'Adresse email invalide';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                ModernTextField(
                  controller: _phoneController,
                  label: 'Numéro de téléphone (optionnel)',
                  hintText: '+237 6 12 34 56 78',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  errorText: authProvider.getFieldError('phone'),
                ),
                const SizedBox(height: 14),

                ModernTextField(
                  controller: _passwordController,
                  label: 'Mot de passe',
                  hintText: '8 caractères minimum',
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  errorText: authProvider.getFieldError('password'),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez définir un mot de passe';
                    }
                    if (value.length < 8) {
                      return 'Au moins 8 caractères requis';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 14),

                ModernTextField(
                  controller: _passwordConfirmController,
                  label: 'Confirmer le mot de passe',
                  hintText: 'Répétez votre mot de passe',
                  prefixIcon: Icons.lock_clock_outlined,
                  obscureText: _obscureConfirmPassword,
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _handleRegister(),
                  errorText: authProvider.getFieldError('password_confirmation'),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: AppColors.textSecondary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Veuillez confirmer votre mot de passe';
                    }
                    if (value != _passwordController.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                FlatActionButton(
                  text: 'Créer mon compte',
                  isLoading: authProvider.isLoading,
                  onPressed: _handleRegister,
                  color: _kCouleurIllustration,
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.inputBorder)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OU',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.inputBorder)),
                  ],
                ),
                const SizedBox(height: 20),

                SocialLoginButton(
                  label: "S'inscrire avec Google",
                  leading: const GoogleBadge(),
                  background: Colors.white,
                  textColor: AppColors.textPrimary,
                  border: AppColors.inputBorder,
                  onTap: () => _showComingSoon("L'inscription avec Google"),
                ),
                const SizedBox(height: 22),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Vous avez déjà un compte ? ',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        authProvider.clearErrors();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Se connecter',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
