import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/notation_service.dart';

/// Instancié localement dans MesCommandesAcheteurScreen (pas dans le
/// MultiProvider global) — pas besoin qu'il survive à l'écran.
class NotationProvider extends ChangeNotifier {
  final NotationService _service = NotationService();

  final Set<String> _dejaNotes = {};
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool dejaNote(int commandeId, int agriculteurId) =>
      _dejaNotes.contains('$commandeId-$agriculteurId');

  Future<bool> noter({
    required int commandeId,
    required int agriculteurId,
    required int note,
    String? commentaire,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.noter(
        commandeId: commandeId,
        agriculteurId: agriculteurId,
        note: note,
        commentaire: commentaire,
      );
      _dejaNotes.add('$commandeId-$agriculteurId');
      _isLoading = false;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
