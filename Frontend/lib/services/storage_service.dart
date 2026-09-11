import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class StorageService {
  static const String _keyToken = 'agrilink_auth_token';
  static const String _keyUser = 'agrilink_user_data';
  static const String _keyBaseUrl = 'agrilink_custom_base_url';

  // Singleton
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  SharedPreferences? _prefs;

  Future<SharedPreferences> get _preferences async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Sauvegarder le token Sanctum
  Future<bool> saveToken(String token) async {
    final prefs = await _preferences;
    return prefs.setString(_keyToken, token);
  }

  /// Récupérer le token Sanctum
  Future<String?> getToken() async {
    final prefs = await _preferences;
    return prefs.getString(_keyToken);
  }

  /// Supprimer le token
  Future<bool> removeToken() async {
    final prefs = await _preferences;
    return prefs.remove(_keyToken);
  }

  /// Sauvegarder les informations de l'utilisateur
  Future<bool> saveUser(UserModel user) async {
    final prefs = await _preferences;
    final jsonString = jsonEncode(user.toJson());
    return prefs.setString(_keyUser, jsonString);
  }

  /// Récupérer les informations utilisateur stockées en cache
  Future<UserModel?> getUser() async {
    final prefs = await _preferences;
    final jsonString = prefs.getString(_keyUser);
    if (jsonString == null) return null;
    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return UserModel.fromJson(jsonMap);
    } catch (_) {
      return null;
    }
  }

  /// Supprimer l'utilisateur du cache
  Future<bool> removeUser() async {
    final prefs = await _preferences;
    return prefs.remove(_keyUser);
  }

  /// Sauvegarder une URL de base personnalisée pour l'API
  Future<bool> saveCustomBaseUrl(String url) async {
    final prefs = await _preferences;
    return prefs.setString(_keyBaseUrl, url);
  }

  /// Récupérer l'URL de base personnalisée si définie
  Future<String?> getCustomBaseUrl() async {
    final prefs = await _preferences;
    return prefs.getString(_keyBaseUrl);
  }

  /// Supprimer l'URL personnalisée pour revenir au défaut
  Future<bool> resetCustomBaseUrl() async {
    final prefs = await _preferences;
    return prefs.remove(_keyBaseUrl);
  }

  /// Nettoyer la session auth (token + données utilisateur)
  Future<void> clearAuth() async {
    final prefs = await _preferences;
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }
}
