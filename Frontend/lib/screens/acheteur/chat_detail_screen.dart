import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/message_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/chat_provider.dart';
import '../../providers/position_share_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_banner.dart';

class ChatDetailScreen extends StatelessWidget {
  final int livraisonId;
  final String titre;

  const ChatDetailScreen({super.key, required this.livraisonId, required this.titre});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider(livraisonId)..chargerInitial()),
        ChangeNotifierProvider(create: (_) => PositionShareProvider()),
      ],
      child: _ChatDetailBody(titre: titre),
    );
  }
}

class _ChatDetailBody extends StatefulWidget {
  final String titre;
  const _ChatDetailBody({required this.titre});

  @override
  State<_ChatDetailBody> createState() => _ChatDetailBodyState();
}

class _ChatDetailBodyState extends State<_ChatDetailBody> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  int _dernierNombreMessages = 0;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    // Le partage de position s'arrête automatiquement en quittant l'écran
    // (le provider est détruit avec lui — pas besoin d'appel explicite ici,
    // son propre dispose() coupe déjà le timer).
    super.dispose();
  }

  void _scrollEnBas() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _envoyer(ChatProvider chat) async {
    final texte = _controller.text;
    if (texte.trim().isEmpty) return;
    _controller.clear();
    final ok = await chat.envoyer(texte);
    if (ok) _scrollEnBas();
  }

  Future<void> _basculerPartagePosition(PositionShareProvider position) async {
    if (position.isActive) {
      position.arreter();
    } else {
      await position.demarrer();
      if (position.errorMessage != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(position.errorMessage!),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final position = context.watch<PositionShareProvider>();
    final monId = context.read<AuthProvider>().user?.id;

    if (chat.messages.length != _dernierNombreMessages) {
      _dernierNombreMessages = chat.messages.length;
      _scrollEnBas();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.titre),
        actions: [
          IconButton(
            tooltip: position.isActive ? 'Arrêter le partage de position' : 'Partager ma position',
            onPressed: position.isLoading ? null : () => _basculerPartagePosition(position),
            icon: position.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  )
                : Icon(
                    position.isActive ? Icons.location_on_rounded : Icons.location_off_outlined,
                    color: position.isActive ? AppColors.success : AppColors.textSecondary,
                  ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (position.isActive)
            Container(
              width: double.infinity,
              color: AppColors.successBg,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.location_on_rounded, size: 15, color: AppColors.success),
                  SizedBox(width: 6),
                  Text(
                    'Ta position est partagée avec le transporteur',
                    style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          if (chat.errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: ErrorBanner(message: chat.errorMessage!),
            ),
          Expanded(
            child: chat.isLoading && chat.messages.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : chat.messages.isEmpty
                    ? const Center(
                        child: Text(
                          'Aucun message pour l\'instant.\nDis bonjour 👋',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: chat.messages.length,
                        itemBuilder: (context, index) {
                          final message = chat.messages[index];
                          final estMoi = message.expediteurId == monId;
                          return _MessageBubble(message: message, estMoi: estMoi);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        border: Border.all(color: AppColors.inputBorder),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Écrire un message...',
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _envoyer(chat),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: chat.isSending ? null : () => _envoyer(chat),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: chat.isSending
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool estMoi;

  const _MessageBubble({required this.message, required this.estMoi});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: estMoi ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: estMoi ? AppColors.primary : Colors.white,
          border: estMoi ? null : Border.all(color: AppColors.inputBorder),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(estMoi ? 16 : 4),
            bottomRight: Radius.circular(estMoi ? 4 : 16),
          ),
        ),
        child: Text(
          message.contenu,
          style: TextStyle(
            fontSize: 14,
            color: estMoi ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
