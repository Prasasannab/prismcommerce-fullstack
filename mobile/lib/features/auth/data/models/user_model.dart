import 'package:equatable/equatable.dart';

/// Represents an authenticated user profile in the PrismCommerce mobile platform.
class UserModel extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String role;

  const UserModel({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.role = 'Customer',
  });

  /// Computed display name.
  String get fullName {
    final combined = '$firstName $lastName'.trim();
    if (combined.isNotEmpty) return combined;
    if (email.isNotEmpty) return email;
    return 'User';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    String first = (json['firstName'] ?? json['FirstName'] ?? '').toString();
    String last = (json['lastName'] ?? json['LastName'] ?? '').toString();

    // If firstName/lastName are empty, check if a single 'name' or 'Name' was returned (e.g. from /auth/me)
    if (first.isEmpty && last.isEmpty) {
      final nameStr = (json['name'] ?? json['Name'] ?? '').toString().trim();
      if (nameStr.isNotEmpty) {
        final segments = nameStr.split(' ');
        first = segments.first;
        if (segments.length > 1) {
          last = segments.sublist(1).join(' ');
        }
      }
    }

    return UserModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      email: (json['email'] ?? json['Email'] ?? '').toString(),
      firstName: first,
      lastName: last,
      role: (json['role'] ?? json['Role'] ?? 'Customer').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? firstName,
    String? lastName,
    String? role,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      role: role ?? this.role,
    );
  }

  @override
  List<Object?> get props => [id, email, firstName, lastName, role];
}
