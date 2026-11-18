import 'package:auto_admin_app/core/errors/app_error.dart';
import 'package:auto_admin_app/core/errors/app_exception.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Gets a Google ID token for the account the user picks. The backend
/// verifies it and returns its own session tokens.
abstract class GoogleIdTokenSource {
  /// Null when the user closes the account picker.
  Future<String?> getIdToken();

  /// Forgets the chosen account, so the picker shows up next time.
  Future<void> signOut();
}

class GoogleSignInIdTokenSource implements GoogleIdTokenSource {
  /// OAuth web client ID of the backend: the audience of the ID tokens.
  final String serverClientId;
  final GoogleSignIn _googleSignIn;

  Future<void>? _initialized;

  GoogleSignInIdTokenSource({
    required this.serverClientId,
    GoogleSignIn? googleSignIn,
  }) : _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  // GoogleSignIn must be initialized exactly once.
  Future<void> _ensureInitialized() =>
      _initialized ??= _googleSignIn.initialize(serverClientId: serverClientId);

  @override
  Future<String?> getIdToken() async {
    if (serverClientId.isEmpty) {
      throw const AppException(AppError(
        message: 'El inicio de sesión con Google no está disponible.',
        type: AppErrorType.unknown,
      ));
    }
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
      throw AppException(AppError(
        message: 'No se pudo iniciar sesión con Google.',
        type: AppErrorType.unknown,
        originalError: e,
      ));
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw const AppException(AppError(
        message: 'No se pudo iniciar sesión con Google.',
        type: AppErrorType.unknown,
      ));
    }
    return idToken;
  }

  @override
  Future<void> signOut() async {
    if (serverClientId.isEmpty) return;
    await _ensureInitialized();
    await _googleSignIn.signOut();
  }
}
