import 'package:equatable/equatable.dart';
import 'user_model.dart';

/// Server response payload for successful authentication (login, register, refresh).
class AuthResponseModel extends Equatable {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final UserModel user;

  const AuthResponseModel({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    final rawExpiresAt = json['expiresAt'] ?? json['ExpiresAt'];
    DateTime parsedExpiresAt;
    if (rawExpiresAt is String) {
      parsedExpiresAt = DateTime.tryParse(rawExpiresAt) ??
          DateTime.now().add(const Duration(days: 7));
    } else {
      parsedExpiresAt = DateTime.now().add(const Duration(days: 7));
    }

    final rawUser = json['user'] ?? json['User'];
    final userModel = rawUser is Map
        ? UserModel.fromJson(Map<String, dynamic>.from(rawUser))
        : const UserModel(id: '', email: '', firstName: '', lastName: '');

    return AuthResponseModel(
      accessToken: (json['accessToken'] ?? json['AccessToken'] ?? '').toString(),
      refreshToken:
          (json['refreshToken'] ?? json['RefreshToken'] ?? '').toString(),
      expiresAt: parsedExpiresAt,
      user: userModel,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'accessToken': accessToken,
      'refreshToken': refreshToken,
      'expiresAt': expiresAt.toIso8601String(),
      'user': user.toJson(),
    };
  }

  AuthResponseModel copyWith({
    String? accessToken,
    String? refreshToken,
    DateTime? expiresAt,
    UserModel? user,
  }) {
    return AuthResponseModel(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      expiresAt: expiresAt ?? this.expiresAt,
      user: user ?? this.user,
    );
  }

  @override
  List<Object?> get props => [accessToken, refreshToken, expiresAt, user];
}
