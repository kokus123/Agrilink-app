import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthResponse {
  final UserModel user;
  final String token;
  final String? message;

  AuthResponse({
    required this.user,
    required this.token,
    this.message,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>;
    return AuthResponse(
      user: UserModel.fromJson(userJson),
      token: json['token'] as String,
      message: json['message'] as String?,
    );
  }
}

class AuthService {
  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  /// Inscription (register)
  Future<AuthResponse> register({
    required String name,
    required String email,
    String? phone,
    required String password,
    required String passwordConfirmation,
    required String role,
    String? deviceName,
  }) async {
    final body = {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'phone': phone?.trim(),
      'password': password,
      'password_confirmation': passwordConfirmation,
      'role': role.toLowerCase(),
      'device_name': deviceName ?? 'Flutter-App',
    };

    final response = await _apiService.post(
      ApiConfig.registerUrl,
      body: body,
      requiresAuth: false,
    );

    final authResponse = AuthResponse.fromJson(response);

    // Sauvegarde persistante locale du token et du profil utilisateur
    await _storageService.saveToken(authResponse.token);
    await _storageService.saveUser(authResponse.user);

    return authResponse;
  }

  /// Connexion (login)
  Future<AuthResponse> login({
    required String email,
    required String password,
    String? deviceName,
  }) async {
    final body = {
      'email': email.trim().toLowerCase(),
      'password': password,
      'device_name': deviceName ?? 'Flutter-App',
    };

    final response = await _apiService.post(
      ApiConfig.loginUrl,
      body: body,
      requiresAuth: false,
    );

    final authResponse = AuthResponse.fromJson(response);

    // Sauvegarde persistante locale du token et du profil utilisateur
    await _storageService.saveToken(authResponse.token);
    await _storageService.saveUser(authResponse.user);

    return authResponse;
  }

  /// Déconnexion (logout)
  Future<void> logout() async {
    try {
      await _apiService.post(
        ApiConfig.logoutUrl,
        requiresAuth: true,
      );
    } catch (_) {
      // Même si le serveur renvoie une erreur ou est hors-ligne,
      // on nettoie toujours la session locale
    } finally {
      await _storageService.clearAuth();
    }
  }

  /// Récupération du profil actuel (/api/me)
  Future<UserModel> getMe() async {
    final response = await _apiService.get(
      ApiConfig.meUrl,
      requiresAuth: true,
    );

    final user = UserModel.fromJson(response);
    await _storageService.saveUser(user);
    return user;
  }
}
