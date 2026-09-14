import 'dart:async';
import 'package:flutter/material.dart';
import '../models/message_model.dart';
import '../services/api_service.dart';
import '../services/chat_service.dart';

/// Gère les messages d'une livraison donnée. Instancié localement par écran
/// (pas dans le MultiProvider global de main.dart) puisqu'il a besoin du
/// livraisonId — voir ChatDetailScreen.
///
/// Pas de WebSocket ici : on rafraîchit par sondage (polling) toutes les
/// 4 secondes tant que l'écran est ouvert. C'est moins "instantané" qu'un
/// vrai flux Reverb, mais ça marche sans dépendance native supplémentaire à
/// configurer — upgradable vers pusher_channels_flutter plus tard si besoin.
class ChatProvider extends ChangeNotifier {
  final ChatService _service = ChatService();
  final int livraisonId;
  Timer? _timer;

  List<MessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;
  String? _errorMessage;

  ChatProvider(this.livraisonId);

  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  String? get errorMessage => _errorMessage;

  Future<void> chargerInitial() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await _rafraichir();
    _isLoading = false;
    notifyListeners();

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _rafraichir());
  }

  Future<void> _rafraichir() async {
    try {
      final messages = await _service.getMessages(livraisonId);
      _messages = messages;
      _errorMessage = null;
      notifyListeners();
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      notifyListeners();
    } catch (_) {
      // Erreur de sondage silencieuse — on ne veut pas spammer l'utilisateur
      // toutes les 4 secondes en cas de coupure réseau passagère.
    }
  }

  Future<bool> envoyer(String contenu) async {
    if (contenu.trim().isEmpty) return false;

    _isSending = true;
    notifyListeners();

    try {
      final message = await _service.envoyer(livraisonId, contenu.trim());
      _messages = [..._messages, message];
      _isSending = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _isSending = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
