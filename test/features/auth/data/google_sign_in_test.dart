import 'package:auto_admin_app/core/errors/app_exception.dart';
import 'package:auto_admin_app/features/auth/data/datasources/auth_data_source.dart';
import 'package:auto_admin_app/features/auth/data/datasources/google_id_token_source.dart';
import 'package:auto_admin_app/features/auth/data/models/auth_credential_model.dart';
import 'package:auto_admin_app/features/auth/data/repository/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_sign_in/google_sign_in.dart';

class _FakeGoogleSignIn implements GoogleSignIn {
  int initializeCalls = 0;
  String? serverClientId;
  bool signedOut = false;
  Object? error;
  String? idToken = 'google-id-token';

  @override
  Future<void> initialize({
    String? clientId,
    String? serverClientId,
    String? nonce,
    String? hostedDomain,
  }) async {
    initializeCalls++;
    this.serverClientId = serverClientId;
  }

  @override
  Future<GoogleSignInAccount> authenticate({
    List<String> scopeHint = const <String>[],
  }) async {
    if (error != null) throw error!;
    return _FakeAccount(idToken);
  }

  @override
  Future<void> signOut() async => signedOut = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAccount implements GoogleSignInAccount {
  final String? idToken;
  _FakeAccount(this.idToken);

  @override
  GoogleSignInAuthentication get authentication =>
      GoogleSignInAuthentication(idToken: idToken);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTokenSource implements GoogleIdTokenSource {
  String? idToken = 'google-id-token';
  bool signedOut = false;
  bool failSignOut = false;

  @override
  Future<String?> getIdToken() async => idToken;

  @override
  Future<void> signOut() async {
    if (failSignOut) throw Exception('no network');
    signedOut = true;
  }
}

class _FakeDataSource implements AuthDataSource {
  String? sentIdToken;
  bool loggedOut = false;

  @override
  Future<AuthCredentialModel?> loginWithGoogle(String idToken) async {
    sentIdToken = idToken;
    return AuthCredentialModel(
      id: '1',
      fullName: 'Ana',
      email: 'ana@gmail.com',
    );
  }

  @override
  Future<void> logout() async => loggedOut = true;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('GoogleSignInIdTokenSource', () {
    late _FakeGoogleSignIn google;
    GoogleSignInIdTokenSource source([String clientId = 'web-client-id']) =>
        GoogleSignInIdTokenSource(
          serverClientId: clientId,
          googleSignIn: google,
        );

    setUp(() => google = _FakeGoogleSignIn());

    test('returns the ID token of the chosen account', () async {
      expect(await source().getIdToken(), 'google-id-token');
      expect(google.serverClientId, 'web-client-id');
    });

    test('initializes Google Sign-In only once', () async {
      final s = source();
      await s.getIdToken();
      await s.getIdToken();
      await s.signOut();
      expect(google.initializeCalls, 1);
    });

    test('returns null when the user closes the picker', () async {
      google.error = const GoogleSignInException(
        code: GoogleSignInExceptionCode.canceled,
      );
      expect(await source().getIdToken(), isNull);
    });

    test('reports any other failure', () async {
      google.error = const GoogleSignInException(
        code: GoogleSignInExceptionCode.clientConfigurationError,
      );
      await expectLater(source().getIdToken(), throwsA(isA<AppException>()));
    });

    test('reports an account without ID token', () async {
      google.idToken = null;
      await expectLater(source().getIdToken(), throwsA(isA<AppException>()));
    });

    test('is unavailable without a client ID', () async {
      await expectLater(source('').getIdToken(), throwsA(isA<AppException>()));
      expect(google.initializeCalls, 0);
    });
  });

  group('AuthRepositoryImpl with Google', () {
    late _FakeTokenSource google;
    late _FakeDataSource api;
    late AuthRepositoryImpl repository;

    setUp(() {
      google = _FakeTokenSource();
      api = _FakeDataSource();
      repository = AuthRepositoryImpl(api, google);
    });

    test('sends the Google ID token to the backend', () async {
      final credential = await repository.loginWithGoogle();

      expect(api.sentIdToken, 'google-id-token');
      expect(credential?.email, 'ana@gmail.com');
    });

    test('does not call the backend when the user cancels', () async {
      google.idToken = null;

      expect(await repository.loginWithGoogle(), isNull);
      expect(api.sentIdToken, isNull);
    });

    test('logout also forgets the Google account', () async {
      await repository.logout();

      expect(api.loggedOut, isTrue);
      expect(google.signedOut, isTrue);
    });

    test('logout succeeds even if Google sign-out fails', () async {
      google.failSignOut = true;

      await repository.logout();
      expect(api.loggedOut, isTrue);
    });
  });
}
