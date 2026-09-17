import '../config/api_config.dart';
import 'api_service.dart';

class ProfileService {
  final ApiService _api = ApiService();

  /// [currentPassword]/[newPassword] restent null si l'utilisateur ne change
  /// pas son mot de passe — le backend ne l'exige que si un nouveau mot de
  /// passe est fourni.
  Future<void> mettreAJour({
    String? name,
    String? phone,
    String? email,
    String? currentPassword,
    String? newPassword,
    String? newPasswordConfirmation,
  }) async {
    await _api.patch(
      ApiConfig.meUrl,
      body: {
        if (name != null) 'name': name,
        if (phone != null) 'phone': phone,
        if (email != null) 'email': email,
        if (currentPassword != null) 'current_password': currentPassword,
        if (newPassword != null) 'password': newPassword,
        if (newPasswordConfirmation != null) 'password_confirmation': newPasswordConfirmation,
      },
      requiresAuth: true,
    );
  }

  /// Upload immédiat de la photo de profil (tap sur l'avatar). Prend des
  /// octets bruts plutôt qu'un `File` — `File` (dart:io) ne fonctionne pas
  /// sur Flutter Web, alors que des octets lus via `XFile.readAsBytes()`
  /// marchent sur toutes les plateformes.
  Future<void> uploaderPhoto(List<int> photoBytes, {String fileName = 'profil.jpg'}) async {
    await _api.multipart(
      ApiConfig.meUrl,
      method: 'PATCH',
      fileBytes: photoBytes,
      fileName: fileName,
      fileFieldName: 'photo',
      requiresAuth: true,
    );
  }
}
