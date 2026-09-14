import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/acheteur_commande_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';
import 'chat_detail_screen.dart';

/// Onglet "Chat" de l'espace Acheteur — une conversation par livraison en
/// cours (donc par commande ayant un transporteur assigné). Pas besoin de
/// provider dédié : on réutilise la liste déjà chargée par l'onglet
/// "Mes commandes".
class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AcheteurCommandeProvider>().charger();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcheteurCommandeProvider>();
    final conversations = provider.commandes
        .where((c) => c.livraison != null && c.livraison!.transporteurNom != null)
        .toList();

    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => context.read<AcheteurCommandeProvider>().charger(),
        child: provider.isLoading && provider.commandes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  const Text(
                    'Chat',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Un transporteur assigné à ta livraison apparaît ici.',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 16),
                  if (provider.errorMessage != null) ErrorBanner(message: provider.errorMessage!),
                  if (conversations.isEmpty && !provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 60),
                      child: Center(
                        child: Text(
                          'Aucune conversation pour le moment.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  for (final commande in conversations)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.inputBorder),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        leading: Container(
                          width: 42,
                          height: 42,
                          decoration: const BoxDecoration(color: AppColors.successBg, shape: BoxShape.circle),
                          child: const Icon(Icons.local_shipping_outlined, color: AppColors.primary),
                        ),
                        title: Text(
                          commande.livraison!.transporteurNom!,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        subtitle: Text(
                          'Commande #${commande.id} · ${commande.statutLabel}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatDetailScreen(
                              livraisonId: commande.livraison!.id,
                              titre: commande.livraison!.transporteurNom!,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
