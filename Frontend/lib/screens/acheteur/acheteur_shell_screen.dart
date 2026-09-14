import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';
import 'catalogue_screen.dart';
import 'conversations_screen.dart';
import 'mes_commandes_acheteur_screen.dart';

class AcheteurShellScreen extends StatefulWidget {
  const AcheteurShellScreen({super.key});

  @override
  State<AcheteurShellScreen> createState() => _AcheteurShellScreenState();
}

class _AcheteurShellScreenState extends State<AcheteurShellScreen> {
  int _index = 0;

  static const List<Widget> _screens = [
    CatalogueScreen(),
    MesCommandesAcheteurScreen(),
    ConversationsScreen(),
    GenericProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront),
            label: 'Catalogue',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Commandes',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_bubble_rounded),
            label: 'Chat',
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
