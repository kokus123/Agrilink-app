import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/models/user_model.dart';
import 'package:frontend/services/auth_service.dart';

void main() {
  group('UserModel Tests', () {
    test('User correctly parsed from Laravel JsonResource format', () {
      final json = {
        'id': 12,
        'name': 'Mamadou Diallo',
        'email': 'mamadou@agrilink.cm',
        'phone': '+237699112233',
        'role': 'agriculteur',
        'is_active': 1,
        'is_subscribed': 0,
        'subscription_expires_at': null,
        'created_at': '2026-09-08T12:00:00.000000Z',
      };

      final user = UserModel.fromJson(json);

      expect(user.id, 12);
      expect(user.name, 'Mamadou Diallo');
      expect(user.email, 'mamadou@agrilink.cm');
      expect(user.phone, '+237699112233');
      expect(user.role, 'agriculteur');
      expect(user.isAgriculteur, true);
      expect(user.isAcheteur, false);
      expect(user.isActive, true);
      expect(user.isSubscribed, false);
      expect(user.roleLabel, 'Agriculteur');
    });

    test('AuthResponse correctly parses Laravel login response', () {
      final responseJson = {
        'message': 'Connexion réussie.',
        'user': {
          'id': 1,
          'name': 'Aline Kamga',
          'email': 'aline@agrilink.cm',
          'phone': null,
          'role': 'acheteur',
          'is_active': true,
          'is_subscribed': true,
          'subscription_expires_at': '2027-01-01T00:00:00.000000Z',
          'created_at': '2026-09-08T10:00:00.000000Z',
        },
        'token': '3|sanctum_token_string_example',
      };

      final authResponse = AuthResponse.fromJson(responseJson);

      expect(authResponse.token, '3|sanctum_token_string_example');
      expect(authResponse.message, 'Connexion réussie.');
      expect(authResponse.user.isAcheteur, true);
      expect(authResponse.user.isAgriculteur, false);
      expect(authResponse.user.isSubscribed, true);
    });
  });
}
