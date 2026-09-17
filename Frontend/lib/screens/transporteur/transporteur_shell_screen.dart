import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/livraison_provider.dart';
import '../../theme/app_theme.dart';
import '../home_screen.dart';
import 'disponibles_screen.dart';
import 'mes_livraisons_screen.dart';
import 'propositions_screen.dart';

class TransporteurShellScreen extends StatefulWidget {
  const TransporteurShellScreen({super.key});

  @override
  State<TransporteurShellScreen> createState() => _TransporteurShellScreenState();
}

class _TransporteurShellScreenState extends State<TransporteurShellScreen> {
  int _index = 0;

  static const List<Widget> _screens = [
    PropositionsScreen(),
    DisponiblesScreen(),
    MesLivraisonsScreen(),
    GenericProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // Provider local — LivraisonProvider est partagé entre les 3 premiers
    // onglets (même IndexedStack), pas besoin de l'ajouter au
    // MultiProvider global de main.dart.
    return ChangeNotifierProvider(
      create: (_) => LivraisonProvider(),
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.notifications_outlined),
            selectedIcon: Icon(Icons.notifications_rounded),
            label: 'Propositions',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Disponibles',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_shipping_outlined),
            selectedIcon: Icon(Icons.local_shipping),
            label: 'Livraisons',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    ),
    );
  }
}
