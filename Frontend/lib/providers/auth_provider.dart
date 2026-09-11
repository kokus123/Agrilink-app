import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _token;
  String? _errorMessage;
  Map<String, List<String>>? _validationErrors;

  // Getters
  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get token => _token;
  String? get errorMessage => _errorMessage;
  Map<String, List<String>>? get validationErrors => _validationErrors;

  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isLoading => _status == AuthStatus.loading;

  String? getFieldError(String field) {
    if (_validationErrors == null) return null;
    final list = _validationErrors![field];
    if (list != null && list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  void clearErrors() {
    _errorMessage = null;
    _validationErrors = null;
    notifyListeners();
  }

  /// Initialisation et vérification de la session au démarrage
  Future<void> checkAuth() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      // Charger l'URL d'API personnalisée si l'utilisateur l'avait modifiée
      final customUrl = await _storageService.getCustomBaseUrl();
      if (customUrl != null && customUrl.isNotEmpty) {
        ApiConfig.setBaseUrl(customUrl);
      }

      final savedToken = await _storageService.getToken();
      if (savedToken == null || savedToken.isEmpty) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        _token = null;
        notifyListeners();
        return;
      }

      _token = savedToken;

      try {
        // Tenter de rafraîchir les données depuis Laravel
        _user = await _authService.getMe();
        _status = AuthStatus.authenticated;
      } on ApiException catch (e) {
        if (e.statusCode == 401) {
          // Token expiré ou invalide
          await _storageService.clearAuth();
          _status = AuthStatus.unauthenticated;
          _user = null;
          _token = null;
        } else {
          // Hors-ligne ou serveur indisponible temporairement : utiliser le cache
          final cachedUser = await _storageService.getUser();
          if (cachedUser != null) {
            _user = cachedUser;
            _status = AuthStatus.authenticated;
          } else {
            _status = AuthStatus.unauthenticated;
          }
        }
      }
    } catch (_) {
      _status = AuthStatus.unauthenticated;
      _user = null;
      _token = null;
    }

    notifyListeners();
  }

  /// Connexion
  Future<bool> login({
    required String email,
    required String password,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _validationErrors = null;
    notifyListeners();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      _user = response.user;
      _token = response.token;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _validationErrors = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.userFriendlyMessage;
      _validationErrors = e.validationErrors;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erreur inattendue : $e';
      notifyListeners();
      return false;
    }
  }

  /// Inscription
  Future<bool> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
    required String role,
  }) async {
    _status = AuthStatus.loading;
    _errorMessage = null;
    _validationErrors = null;
    notifyListeners();

    try {
      final response = await _authService.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        role: role,
      );

      _user = response.user;
      _token = response.token;
      _status = AuthStatus.authenticated;
      _errorMessage = null;
      _validationErrors = null;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AuthStatus.error;
      _errorMessage = e.userFriendlyMessage;
      _validationErrors = e.validationErrors;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.error;
      _errorMessage = 'Erreur inattendue : $e';
      notifyListeners();
      return false;
    }
  }

  /// Déconnexion
  Future<void> logout() async {
    _status = AuthStatus.loading;
    notifyListeners();

    try {
      await _authService.logout();
    } catch (_) {}

    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;
    _errorMessage = null;
    _validationErrors = null;
    notifyListeners();
  }

  /// Configuration dynamique de l'URL du serveur (pratique pour tester émulateur vs smartphone réel)
  Future<void> updateBaseUrl(String newUrl) async {
    ApiConfig.setBaseUrl(newUrl);
    await _storageService.saveCustomBaseUrl(ApiConfig.baseUrl);
    notifyListeners();
  }

  Future<void> resetBaseUrl() async {
    await _storageService.resetCustomBaseUrl();
    ApiConfig.setBaseUrl(ApiConfig.defaultBaseUrl);
    notifyListeners();
  }
}
