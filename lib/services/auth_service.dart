import 'package:firebase_auth/firebase_auth.dart';

/// Thin wrapper around Firebase Auth anonymous sign-in.
///
/// Each device gets its own anonymous Firebase user the first time the
/// app runs; that uid is what "one vote per person" is keyed on. This is
/// a placeholder for real accounts later — swapping anonymous sign-in for
/// email/Google sign-in later won't change anything that reads `uid`.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Signs in anonymously if not already signed in. Call once at startup,
  /// before anything that needs `currentUid`.
  Future<void> ensureSignedIn() async {
    if (_auth.currentUser == null) {
      await _auth.signInAnonymously();
    }
  }

  String get currentUid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError(
        'No signed-in user. Call AuthService.instance.ensureSignedIn() first.',
      );
    }
    return uid;
  }
}
