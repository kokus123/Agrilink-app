import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  /// Port par défaut utilisé par Laravel (généralement 8000 ou 8001)
  static const String defaultPort = '8000';

  /// Détection de l'hôte selon la plateforme :
  /// - Émulateur Android : 10.0.2.2 pointe vers le localhost de la machine hôte
  /// - Web / Linux / Desktop / iOS Simulateur : 127.0.0.1
  static String get defaultHost {
    if (kIsWeb) return '127.0.0.1';
    try {
      if (Platform.isAndroid) return '10.0.2.2';
    } catch (_) {}
    return '127.0.0.1';
  }

  static String get defaultBaseUrl => 'http://$defaultHost:$defaultPort/api';

  /// URL de base courante
  static String _baseUrl = defaultBaseUrl;

  static String get baseUrl => _baseUrl;

  static void setBaseUrl(String url) {
    var clean = url.trim();
    if (clean.endsWith('/')) {
      clean = clean.substring(0, clean.length - 1);
    }
    _baseUrl = clean;
  }

  /// Endpoints
  static String get registerUrl => '$_baseUrl/register';
  static String get loginUrl => '$_baseUrl/login';
  static String get logoutUrl => '$_baseUrl/logout';
  static String get meUrl => '$_baseUrl/me';
}
