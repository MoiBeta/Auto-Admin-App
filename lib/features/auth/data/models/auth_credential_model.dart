
import 'package:auto_admin_app/features/auth/domain/entity/auth_credential.dart';

class AuthCredentialModel {
  final String id;
  final String? fullName;
  final String? email;
  final bool isEmailConfirmed;

  AuthCredentialModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isEmailConfirmed,
  });

  AuthCredential toEntity() => AuthCredential(
    id: id,
    fullName: fullName,
    email: email,
    isEmailConfirmed: isEmailConfirmed,
  );
}
