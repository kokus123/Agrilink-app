import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/api_service.dart';
import '../services/position_service.dart';

/// Instancié localement (pas dans le MultiProvider global) — le partage de
/// position n'a de sens que pendant qu'un écran de livraison est ouvert.
class PositionShareProvider extends ChangeNotifier {
  final PositionService _service = PositionService();
  Timer? _timer;

  bool _isActive = false;
  bool _isLoading = false;
  String? _errorMessage;

  bool get isActive => _isActive;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> demarrer() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final autorise = await _verifierPermission();
    if (!autorise) {
      _isLoading = false;
      notifyListeners();
      return;
    }

    _isActive = true;
    _isLoading = false;
    notifyListeners();

    await _envoyerPositionActuelle();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _envoyerPositionActuelle());
  }

  void arreter() {
    _timer?.cancel();
    _isActive = false;
    notifyListeners();
  }

  Future<bool> _verifierPermission() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      _errorMessage = 'La localisation est désactivée sur ton téléphone.';
      return false;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      _errorMessage = "Autorisation de localisation refusée. Active-la dans les réglages de l'app.";
      return false;
    }

    return true;
  }

  Future<void> _envoyerPositionActuelle() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      await _service.envoyerPosition(position.latitude, position.longitude);
      _errorMessage = null;
    } on ApiException catch (e) {
      _errorMessage = e.userFriendlyMessage;
    } catch (_) {
      // Erreur GPS passagère — on retentera au prochain cycle, pas la peine
      // d'interrompre le partage pour un raté ponctuel.
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
