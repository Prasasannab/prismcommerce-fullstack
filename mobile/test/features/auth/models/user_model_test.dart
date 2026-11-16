import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/data/models/auth_response_model.dart';
import 'package:mobile/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel', () {
    test('supports value equality', () {
      const user1 = UserModel(
        id: 'u-1',
        email: 'alex@example.com',
        firstName: 'Alex',
        lastName: 'Mercer',
        role: 'Customer',
      );
      const user2 = UserModel(
        id: 'u-1',
        email: 'alex@example.com',
        firstName: 'Alex',
        lastName: 'Mercer',
        role: 'Customer',
      );

      expect(user1, equals(user2));
    });

    test('fullName computes correctly when first and last names exist', () {
      const user = UserModel(
        id: 'u-1',
        email: 'alex@example.com',
        firstName: 'Alex',
        lastName: 'Mercer',
      );
      expect(user.fullName, 'Alex Mercer');
    });

    test('fullName falls back to email or User when names are missing', () {
      const userWithEmail = UserModel(
        id: 'u-1',
        email: 'alex@example.com',
        firstName: '',
        lastName: '',
      );
      expect(userWithEmail.fullName, 'alex@example.com');

      const emptyUser = UserModel(
        id: 'u-1',
        email: '',
        firstName: '',
        lastName: '',
      );
      expect(emptyUser.fullName, 'User');
    });

    test('fromJson parses camelCase and PascalCase payloads', () {
      final jsonCamel = {
        'id': '11111111-1111-1111-1111-111111111111',
        'email': 'customer@prismcommerce.com',
        'firstName': 'Alex',
        'lastName': 'Mercer',
        'role': 'Customer',
      };
      final userCamel = UserModel.fromJson(jsonCamel);
      expect(userCamel.id, '11111111-1111-1111-1111-111111111111');
      expect(userCamel.email, 'customer@prismcommerce.com');
      expect(userCamel.firstName, 'Alex');
      expect(userCamel.lastName, 'Mercer');
      expect(userCamel.role, 'Customer');

      final jsonPascal = {
        'Id': '22222222-2222-2222-2222-222222222222',
        'Email': 'admin@prismcommerce.com',
        'FirstName': 'Sam',
        'LastName': 'Fisher',
        'Role': 'Admin',
      };
      final userPascal = UserModel.fromJson(jsonPascal);
      expect(userPascal.id, '22222222-2222-2222-2222-222222222222');
      expect(userPascal.email, 'admin@prismcommerce.com');
      expect(userPascal.firstName, 'Sam');
      expect(userPascal.lastName, 'Fisher');
      expect(userPascal.role, 'Admin');
    });

    test('fromJson splits single name or Name field when first/last missing', () {
      final json = {
        'id': '33333333-3333-3333-3333-333333333333',
        'email': 'user@example.com',
        'name': 'Johnathan Doe',
      };
      final user = UserModel.fromJson(json);
      expect(user.firstName, 'Johnathan');
      expect(user.lastName, 'Doe');
      expect(user.fullName, 'Johnathan Doe');
    });

    test('toJson serializes correctly', () {
      const user = UserModel(
        id: 'u-1',
        email: 'alex@example.com',
        firstName: 'Alex',
        lastName: 'Mercer',
        role: 'Customer',
      );
      final json = user.toJson();
      expect(json['id'], 'u-1');
      expect(json['email'], 'alex@example.com');
      expect(json['firstName'], 'Alex');
      expect(json['lastName'], 'Mercer');
      expect(json['role'], 'Customer');
    });

    test('copyWith updates specified fields', () {
      const user = UserModel(
        id: 'u-1',
        email: 'alex@example.com',
        firstName: 'Alex',
        lastName: 'Mercer',
      );
      final updated = user.copyWith(firstName: 'Alexander', role: 'VIP');
      expect(updated.id, 'u-1');
      expect(updated.firstName, 'Alexander');
      expect(updated.lastName, 'Mercer');
      expect(updated.role, 'VIP');
    });
  });

  group('AuthResponseModel', () {
    test('fromJson and toJson round-trip properly', () {
      final now = DateTime.now().toUtc();
      final json = {
        'accessToken': 'jwt-access-token-123',
        'refreshToken': 'jwt-refresh-token-456',
        'expiresAt': now.toIso8601String(),
        'user': {
          'id': 'u-1',
          'email': 'alex@example.com',
          'firstName': 'Alex',
          'lastName': 'Mercer',
          'role': 'Customer',
        },
      };

      final authResponse = AuthResponseModel.fromJson(json);
      expect(authResponse.accessToken, 'jwt-access-token-123');
      expect(authResponse.refreshToken, 'jwt-refresh-token-456');
      expect(authResponse.user.email, 'alex@example.com');

      final serialized = authResponse.toJson();
      expect(serialized['accessToken'], 'jwt-access-token-123');
      expect(serialized['refreshToken'], 'jwt-refresh-token-456');
      expect(serialized['user']['id'], 'u-1');
    });

    test('supports value equality and copyWith', () {
      final now = DateTime.utc(2026, 11, 16);
      const user = UserModel(
        id: 'u-1',
        email: 'alex@example.com',
        firstName: 'Alex',
        lastName: 'Mercer',
      );
      final resp1 = AuthResponseModel(
        accessToken: 'token-a',
        refreshToken: 'refresh-a',
        expiresAt: now,
        user: user,
      );
      final resp2 = AuthResponseModel(
        accessToken: 'token-a',
        refreshToken: 'refresh-a',
        expiresAt: now,
        user: user,
      );

      expect(resp1, equals(resp2));

      final updated = resp1.copyWith(accessToken: 'token-b');
      expect(updated.accessToken, 'token-b');
      expect(updated.refreshToken, 'refresh-a');
    });
  });
}
