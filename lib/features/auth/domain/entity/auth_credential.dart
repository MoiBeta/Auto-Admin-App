class AuthCredential {
  final String? id;
  final String? fullName;
  final String? email;
  final bool? isEmailConfirmed;

  AuthCredential({
    required this.id,
    required this.fullName,
    required this.email,
    required this.isEmailConfirmed,
  });

  AuthCredential copyWith({
    String? id,
    String? fullName,
    String? email,
    bool? isEmailConfirmed,
  }) {
    return AuthCredential(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      isEmailConfirmed: isEmailConfirmed ?? this.isEmailConfirmed,
    );
  }
}
