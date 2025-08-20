import 'package:auto_admin_app/features/auth/data/datasources/auth_data_source.dart';
import 'package:auto_admin_app/features/auth/data/models/auth_credential_model.dart';
import 'package:auto_admin_app/features/auth/domain/errors/auth_error.dart';
import 'package:auto_admin_app/features/auth/domain/errors/auth_exception.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/change_password_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/login_data.dart';
import 'package:auto_admin_app/features/auth/domain/usecases/inputs/sign_up_data.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseAuthDataSource extends AuthDataSource {
  final _auth = FirebaseAuth.instance;

  @override
  Future<bool> changePassword(ChangePasswordData changePasswordData) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        final credential = EmailAuthProvider.credential(
            email: user.email ?? '', password: changePasswordData.oldPassword);
        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(changePasswordData.newPassword);
        return true;
      } on FirebaseAuthException catch (_) {
        throw AuthException(AuthError.unknown);
      }
    }
    return false;
  }

  @override
  Future<bool> confirmEmail() async {
    await _auth.currentUser?.reload();
    final user = _auth.currentUser;
    return user != null && user.emailVerified;
  }

  @override
  Future<String?> getAccessToken() async {
    final user = _auth.currentUser;
    return user?.getIdToken();
  }

  @override
  Future<AuthCredentialModel?> getAuthState() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    await user.reload();
    final refreshedUser = _auth.currentUser!;

    return AuthCredentialModel(
      id: refreshedUser.uid,
      fullName: refreshedUser.displayName,
      email: refreshedUser.email,
      isEmailConfirmed: refreshedUser.emailVerified,
    );
  }

  @override
  Future<AuthCredentialModel?> login(LoginData loginData) async {
    try {
      UserCredential firebaseCredential =
          await _auth.signInWithEmailAndPassword(
        email: loginData.email.trim(),
        password: loginData.password,
      );
      return AuthCredentialModel(
        id: firebaseCredential.user?.uid ?? '',
        fullName: firebaseCredential.user?.displayName,
        email: firebaseCredential.user?.email,
        isEmailConfirmed: firebaseCredential.user?.emailVerified ?? false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw AuthException(AuthError.userNotFound);
      } else if (e.code == 'wrong-password') {
        throw AuthException(AuthError.invalidCredentials);
      }
    }
    return null;
  }

  @override
  Future<void> logout() async {
    await FirebaseAuth.instance.signOut();
  }

  @override
  Future<AuthCredentialModel?> registerUser(SignUpData signUpData) async {
    try {
      UserCredential firebaseCredential =
          await _auth.createUserWithEmailAndPassword(
        email: signUpData.email.trim(),
        password: signUpData.password,
      );
      await firebaseCredential.user?.sendEmailVerification();
      return AuthCredentialModel(
        id: firebaseCredential.user?.uid ?? '',
        fullName: firebaseCredential.user?.displayName,
        email: firebaseCredential.user?.email,
        isEmailConfirmed: firebaseCredential.user?.emailVerified ?? false,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw AuthException(AuthError.invalidNewPassword);
      } else if (e.code == 'email-already-in-use') {
        throw AuthException(AuthError.userAlreadyExist);
      }
    } catch (e) {
      throw AuthException(AuthError.unknown);
    }
    return null;
  }

  @override
  Future<void> resendConfirmationCode() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }
}
