import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<User?> get authState => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /* ================= SIGN UP ================= */

  Future<void> signUp(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception("Email and password cannot be empty");
      }

      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      await cred.user!.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  /* ================= SIGN IN ================= */

  Future<void> signIn(String email, String password) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        throw Exception("Email and password cannot be empty");
      }

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } on FirebaseAuthException catch (e) {
      throw Exception(_mapAuthError(e));
    }
  }

  /* ================= SIGN OUT ================= */

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /* ================= EMAIL VERIFICATION ================= */

  Future<void> resendVerification() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("No logged-in user");
    }

    if (user.emailVerified) {
      throw Exception("Email already verified");
    }

    await user.sendEmailVerification();
  }

  Future<bool> reloadAndCheckVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    await user.reload();
    return _auth.currentUser!.emailVerified;
  }

  /* ================= ERROR MAPPER ================= */

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return "Email already in use";
      case 'invalid-email':
        return "Invalid email address";
      case 'weak-password':
        return "Password is too weak (min 6 chars)";
      case 'user-not-found':
        return "No user found with this email";
      case 'wrong-password':
        return "Incorrect password";
      case 'user-disabled':
        return "This account has been disabled";
      case 'operation-not-allowed':
        return "Email/password login is disabled";
      case 'too-many-requests':
        return "Too many attempts. Try again later";
      default:
        return e.message ?? "Authentication failed";
    }
  }
}
