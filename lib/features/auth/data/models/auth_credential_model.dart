import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';

class AuthCredentialModel {
  final String id;
  final String? fullName;
  final String? email;
  final bool? isEmailConfirmed;

  AuthCredentialModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.isEmailConfirmed,
  });

  AuthCredential toEntity() => AuthCredential(
        id: id,
        fullName: fullName,
        email: email,
        isEmailConfirmed: isEmailConfirmed,
      );

  factory AuthCredentialModel.fromJson(Map<String, dynamic> json) =>
      AuthCredentialModel(
        id: json['id'],
        fullName: json['name'],
        email: json['email'],
        isEmailConfirmed: json['isEmailConfirmed'],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': fullName,
        'email': email,
        'isEmailConfirmed': isEmailConfirmed,
      };
}
