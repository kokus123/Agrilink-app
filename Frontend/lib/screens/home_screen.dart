import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_star_badge.dart';
import 'acheteur/acheteur_shell_screen.dart';
import 'agriculteur/agriculteur_shell_screen.dart';
import 'agriculteur/mes_notations_screen.dart';
import 'transporteur/transporteur_shell_screen.dart';
import 'login_screen.dart';
import 'shared/edit_profile_screen.dart';

/// Point d'entrée post-connexion : redirige vers l'espace dédié au rôle.
/// Agriculteur et Acheteur ont leur propre espace — les autres rôles
/// (transporteur, admin) retombent sur l'écran de profil générique en
/// attendant leur propre bloc.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    if (user != null && user.isAgriculteur) {
      return const AgriculteurShellScreen();
    }

    if (user != null && user.isAcheteur) {
      return const AcheteurShellScreen();
    }

    if (user != null && user.isTransporteur) {
      return const TransporteurShellScreen();
    }

    return const GenericProfileScreen();
  }
}

/// Écran de profil générique — utilisé comme repli pour les rôles sans
/// espace dédié, et réutilisé tel quel comme onglet "Profil" de
/// AcheteurShellScreen et AgriculteurShellScreen (public pour être
/// importable ailleurs).
class GenericProfileScreen extends StatefulWidget {
  const GenericProfileScreen({super.key});

  @override
  State<GenericProfileScreen> createState() => _GenericProfileScreenState();
}

class _GenericProfileScreenState extends State<GenericProfileScreen> {
  final ProfileService _profileService = ProfileService();
  bool _isUploadingPhoto = false;

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.error),
            SizedBox(width: 8),
            Text('Déconnexion', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Voulez-vous vraiment vous déconnecter de votre compte AgriLink ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _changerPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
              title: const Text('Choisir depuis la galerie'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined, color: AppColors.primary),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;

    final picked = await ImagePicker().pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final bytes = await picked.readAsBytes();
      await _profileService.uploaderPhoto(bytes, fileName: picked.name);
      if (mounted) await context.read<AuthProvider>().checkAuth();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.userFriendlyMessage), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mon profil', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.error),
            tooltip: 'Déconnexion',
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => authProvider.checkAuth(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Carte utilisateur — mise en page centrée
                    Container(
                      padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
                      decoration: BoxDecoration(
                        gradient: AppColors.brandGradient,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned(
                            top: 0,
                            right: 0,
                            child: IconButton(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                              ),
                              icon: const Icon(Icons.edit_outlined, color: Colors.white),
                              tooltip: 'Modifier le profil',
                            ),
                          ),
                          Column(
                            children: [
                              GestureDetector(
                                onTap: _isUploadingPhoto ? null : _changerPhoto,
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    Container(
                                      width: 88,
                                      height: 88,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withValues(alpha: 0.1),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: ClipOval(
                                        child: _isUploadingPhoto
                                            ? const Center(
                                                child: CircularProgressIndicator(
                                                  color: AppColors.primary,
                                                  strokeWidth: 2.5,
                                                ),
                                              )
                                            : (user.photo != null
                                                ? Image.network(
                                                    user.photo!,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, _, _) => _AvatarIcon(user: user),
                                                  )
                                                : _AvatarIcon(user: user)),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: -2,
                                      right: -2,
                                      child: Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.accent,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.white, width: 2),
                                        ),
                                        child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: Text(
                                      user.name,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 19,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  if (user.isSubscribed) ...[
                                    const SizedBox(width: 5),
                                    const PremiumStarBadge(size: 16),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                user.email,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.85),
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _StatusChip(
                                    label: user.roleLabel.toUpperCase(),
                                    icon: Icons.badge_outlined,
                                    isHighlight: true,
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusChip(
                                    label: user.isActive ? 'COMPTE ACTIF' : 'SUSPENDU',
                                    icon: user.isActive ? Icons.check_circle_outline : Icons.block,
                                    isHighlight: false,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Carte d'informations
                    Container(
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.inputBorder),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informations du profil',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const Divider(height: 24, color: AppColors.inputBorder),
                          _DetailRow(
                            icon: Icons.phone_outlined,
                            label: 'Téléphone',
                            value: user.phone?.isNotEmpty == true ? user.phone! : 'Non renseigné',
                          ),
                          const SizedBox(height: 14),
                          _DetailRow(
                            icon: Icons.card_membership_outlined,
                            label: 'Abonnement',
                            value: user.isSubscribed ? 'Membre Premium' : 'Compte Standard',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                      ),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier le profil'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 1,
                      ),
                    ),

                    // "Mes notations" — uniquement pour l'agriculteur, la
                    // notation ne concerne que ce rôle sur le diagramme.
                    if (user.isAgriculteur) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const MesNotationsScreen()),
                        ),
                        icon: const Icon(Icons.star_outline_rounded, color: AppColors.warning),
                        label: const Text(
                          'Mes notations',
                          style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.warning, width: 1.2),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _handleLogout(context),
                      icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                      label: const Text(
                        'Se déconnecter',
                        style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.error, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AvatarIcon extends StatelessWidget {
  final UserModel user;
  const _AvatarIcon({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        user.isAgriculteur
            ? Icons.agriculture_rounded
            : (user.isAdmin ? Icons.admin_panel_settings_rounded : Icons.shopping_basket_rounded),
        size: 40,
        color: AppColors.primary,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isHighlight;

  const _StatusChip({
    required this.label,
    required this.icon,
    required this.isHighlight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.white : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: isHighlight ? AppColors.primary : Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: isHighlight ? AppColors.primary : Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 19, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
