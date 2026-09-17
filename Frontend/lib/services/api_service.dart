import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, List<String>>? validationErrors;
  /// Corps brut décodé de la réponse d'erreur — utile pour détecter des
  /// indicateurs métier précis (ex: {"limite_atteinte": true}) sans avoir
  /// à ajouter un champ dédié à ApiException à chaque nouveau cas.
  final Map<String, dynamic>? body;

  ApiException({
    required this.message,
    this.statusCode,
    this.validationErrors,
    this.body,
  });

  /// Retourne un message lisible combinant les erreurs de validation s'il y en a
  String get userFriendlyMessage {
    if (validationErrors != null && validationErrors!.isNotEmpty) {
      final buffer = StringBuffer();
      validationErrors!.forEach((field, errors) {
        for (var error in errors) {
          buffer.writeln('• $error');
        }
      });
      return buffer.toString().trim();
    }
    return message;
  }

  /// Retourne l'erreur spécifique pour un champ donné (ex: 'email', 'password')
  String? getErrorForField(String field) {
    if (validationErrors == null) return null;
    final list = validationErrors![field];
    if (list != null && list.isNotEmpty) {
      return list.first;
    }
    return null;
  }

  @override
  String toString() => userFriendlyMessage;
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  final StorageService _storageService = StorageService();

  static const Duration timeoutDuration = Duration(seconds: 15);

  /// Construit les headers HTTP standard avec Token Sanctum optionnel
  Future<Map<String, String>> _buildHeaders({bool requiresAuth = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (requiresAuth) {
      final token = await _storageService.getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Requête POST
  Future<Map<String, dynamic>> post(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse(url);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .post(uri, headers: headers, body: encodedBody)
          .timeout(timeoutDuration);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        message:
            'Impossible de contacter le serveur ($url). Vérifiez votre connexion et assurez-vous que "php artisan serve" est lancé.\n(${e.message})',
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Le serveur met trop de temps à répondre (Timeout).',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Erreur réseau client : ${e.message}',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Une erreur inattendue est survenue : $e');
    }
  }

  /// Requête GET
  Future<Map<String, dynamic>> get(
    String url, {
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse(url);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response =
          await _client.get(uri, headers: headers).timeout(timeoutDuration);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        message:
            'Impossible de contacter le serveur ($url).\n(${e.message})',
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Le serveur met trop de temps à répondre (Timeout).',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Erreur réseau client : ${e.message}',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Une erreur inattendue est survenue : $e');
    }
  }

  /// Requête PATCH (mise à jour partielle — utilisé pour modifier un produit)
  Future<Map<String, dynamic>> patch(
    String url, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse(url);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      final encodedBody = body != null ? jsonEncode(body) : null;

      final response = await _client
          .patch(uri, headers: headers, body: encodedBody)
          .timeout(timeoutDuration);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        message:
            'Impossible de contacter le serveur ($url).\n(${e.message})',
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Le serveur met trop de temps à répondre (Timeout).',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Erreur réseau client : ${e.message}',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Une erreur inattendue est survenue : $e');
    }
  }

  /// Requête DELETE
  Future<Map<String, dynamic>> delete(
    String url, {
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse(url);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);

      final response = await _client
          .delete(uri, headers: headers)
          .timeout(timeoutDuration);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        message:
            'Impossible de contacter le serveur ($url).\n(${e.message})',
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Le serveur met trop de temps à répondre (Timeout).',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Erreur réseau client : ${e.message}',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Une erreur inattendue est survenue : $e');
    }
  }

  /// Requête multipart/form-data (upload de fichier, ex: photo produit).
  ///
  /// On travaille en octets bruts ([fileBytes]) plutôt qu'avec un `File`
  /// (dart:io) — `File` ne fonctionne PAS sur Flutter Web (pas d'accès
  /// disque dans un navigateur), alors que des octets lus via
  /// `XFile.readAsBytes()` marchent identiquement sur web, mobile et
  /// desktop. C'est à l'appelant de lire les octets avant d'appeler cette
  /// méthode.
  ///
  /// Laravel ne lit les fichiers ($_FILES) que sur de vraies requêtes HTTP
  /// POST — pour simuler un PATCH avec fichier, on envoie donc un POST
  /// avec un champ `_method=PATCH` (mécanisme standard de Laravel pour les
  /// formulaires HTML/multipart, qui ne savent faire que GET/POST).
  Future<Map<String, dynamic>> multipart(
    String url, {
    required String method, // 'POST' ou 'PATCH'
    Map<String, String>? fields,
    List<int>? fileBytes,
    String fileName = 'upload.jpg',
    String fileFieldName = 'image',
    bool requiresAuth = false,
  }) async {
    try {
      final uri = Uri.parse(url);
      final request = http.MultipartRequest('POST', uri);

      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      headers.remove('Content-Type'); // fixé automatiquement par MultipartRequest
      request.headers.addAll(headers);

      final allFields = {...?fields};
      if (method.toUpperCase() == 'PATCH') {
        allFields['_method'] = 'PATCH';
      }
      request.fields.addAll(allFields);

      if (fileBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          fileFieldName,
          fileBytes,
          filename: fileName,
        ));
      }

      final streamedResponse = await request.send().timeout(timeoutDuration);
      final response = await http.Response.fromStream(streamedResponse);

      return _processResponse(response);
    } on SocketException catch (e) {
      throw ApiException(
        message:
            'Impossible de contacter le serveur ($url).\n(${e.message})',
      );
    } on TimeoutException {
      throw ApiException(
        message: 'Le serveur met trop de temps à répondre (Timeout).',
      );
    } on http.ClientException catch (e) {
      throw ApiException(
        message: 'Erreur réseau client : ${e.message}',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException(message: 'Une erreur inattendue est survenue : $e');
    }
  }

  /// Traitement des codes de réponse HTTP et du JSON
  Map<String, dynamic> _processResponse(http.Response response) {
    Map<String, dynamic> body = {};
    try {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
        } else {
          body = {'data': decoded};
        }
      }
    } catch (_) {
      // Le body n'est pas un JSON valide (ex: page HTML d'erreur 500)
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Gestion des erreurs de validation Laravel (422)
    if (response.statusCode == 422) {
      Map<String, List<String>> validationErrors = {};
      if (body.containsKey('errors') && body['errors'] is Map) {
        final errorsMap = body['errors'] as Map<String, dynamic>;
        errorsMap.forEach((key, val) {
          if (val is List) {
            validationErrors[key] = val.map((e) => e.toString()).toList();
          } else if (val is String) {
            validationErrors[key] = [val];
          }
        });
      }

      final message = body['message'] as String? ??
          'Données invalides. Veuillez vérifier les champs.';

      throw ApiException(
        message: message,
        statusCode: 422,
        validationErrors: validationErrors,
        body: body,
      );
    }

    // Gestion 401 Unauthorized
    if (response.statusCode == 401) {
      throw ApiException(
        message: body['message'] as String? ?? 'Non authentifié. Veuillez vous reconnecter.',
        statusCode: 401,
        body: body,
      );
    }

    // Gestion 403 Forbidden
    if (response.statusCode == 403) {
      throw ApiException(
        message: body['message'] as String? ?? 'Accès refusé.',
        statusCode: 403,
        body: body,
      );
    }

    // Gestion 404
    if (response.statusCode == 404) {
      throw ApiException(
        message: 'Ressource introuvable sur le serveur (404).',
        statusCode: 404,
        body: body,
      );
    }

    // Gestion 409 Conflict (ex : livraison déjà prise en charge, paiement déjà traité)
    if (response.statusCode == 409) {
      throw ApiException(
        message: body['message'] as String? ?? 'Conflit : action déjà effectuée.',
        statusCode: 409,
        body: body,
      );
    }

    // Gestion 500 et autres erreurs
    final fallbackMsg = body['message'] as String? ??
        'Erreur du serveur (Code ${response.statusCode}).';
    throw ApiException(
      message: fallbackMsg,
      statusCode: response.statusCode,
      body: body,
    );
  }
}
