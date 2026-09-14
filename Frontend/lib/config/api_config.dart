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

  /// Endpoints — Authentification
  static String get registerUrl => '$_baseUrl/register';
  static String get loginUrl => '$_baseUrl/login';
  static String get logoutUrl => '$_baseUrl/logout';
  static String get meUrl => '$_baseUrl/me';

  /// Endpoints — Espace Agriculteur
  static String get mesProduitsUrl => '$_baseUrl/mes-produits';
  static String get mesCommandesUrl => '$_baseUrl/mes-commandes';
  static String notifierTransporteurUrl(int commandeId) =>
      '$_baseUrl/commandes/$commandeId/notifier-transporteur';
  static String get abonnementSouscrireUrl => '$_baseUrl/abonnement/souscrire';
  static String get abonnementStatutUrl => '$_baseUrl/abonnement/statut';
  static String get simulerRevenusUrl => '$_baseUrl/simuler-revenus';
  static String get predictionPrixUrl => '$_baseUrl/prediction-prix';

  /// Endpoints — Espace Acheteur
  static String get produitsUrl => '$_baseUrl/produits';
  static String produitDetailUrl(int produitId) => '$_baseUrl/produits/$produitId';
  static String get commandesUrl => '$_baseUrl/commandes';
  static String commandeDetailUrl(int commandeId) => '$_baseUrl/commandes/$commandeId';

  /// Endpoints — Notation ("Noter agriculteur")
  static String get notationsUrl => '$_baseUrl/notations';
  static String agriculteurNotationsUrl(int agriculteurId) =>
      '$_baseUrl/agriculteurs/$agriculteurId/notations';

  /// Endpoints — Position ("Partager position", commun acheteur/transporteur)
  static String get positionUrl => '$_baseUrl/position';

  /// Endpoints — Chat de livraison (commun acheteur/transporteur)
  static String livraisonMessagesUrl(int livraisonId) =>
      '$_baseUrl/livraisons/$livraisonId/messages';

  /// Endpoints — Paiement (abonnement premium uniquement)
  static String payerPaiementUrl(int paiementId) =>
      '$_baseUrl/paiements/$paiementId/payer';
}
