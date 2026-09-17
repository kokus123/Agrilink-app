import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/premium_badge_button.dart';
import '../../widgets/premium_star_badge.dart';
import '../home_screen.dart';
import 'accueil_screen.dart';
import 'mes_commandes_screen.dart';
import 'mes_produits_screen.dart';

class AgriculteurShellScreen extends StatefulWidget {
  const AgriculteurShellScreen({super.key});

  @override
  State<AgriculteurShellScreen> createState() => _AgriculteurShellScreenState();
}

class _AgriculteurShellScreenState extends State<AgriculteurShellScreen> {
  int _index = 0;

  static const List<Widget> _screens = [
    AgriculteurAccueilScreen(),
    MesProduitsScreen(),
    MesCommandesScreen(),
    GenericProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final estAbonne = user?.isSubscribed ?? false;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 12,
        leading: null,
        leadingWidth: 0,
        title: GestureDetector(
          onTap: () => setState(() => _index = 3), // ouvre l'onglet Profil
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.successBg,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.inputBorder),
                    ),
                    child: ClipOval(
                      child: user?.photo != null
                          ? Image.network(
                              user!.photo!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(Icons.agriculture_rounded, size: 18, color: AppColors.primary),
                            )
                          : const Icon(Icons.agriculture_rounded, size: 18, color: AppColors.primary),
                    ),
                  ),
                  if (estAbonne)
                    const Positioned(
                      bottom: -2,
                      right: -2,
                      child: PremiumStarBadge(size: 14),
                    ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  user?.name ?? 'Agriculteur',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PremiumBadgeButton(estAbonne: estAbonne),
          ),
        ],
      ),
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Accueil',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2),
            label: 'Produits',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
