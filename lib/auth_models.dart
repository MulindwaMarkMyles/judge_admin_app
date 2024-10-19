import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Register User with Email and Password + Add Role Field
  Future<String?> registerWithEmailAndPassword(
      String email, String password, bool isAdmin) async {
    try {
      
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );


      return null; // Registration successful
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return 'This email is already in use.';
        case 'invalid-email':
          return 'The email address is not valid.';
        case 'weak-password':
          return 'The password is too weak.';
        default:
          return 'Failed to create account. Please try again.';
      }
    } catch (e) {
      print('Error: $e');
      return 'An unexpected error occurred.';
    }
  }

  // Sign In User and Check Role
  Future<String?> signIn(String email, String password) async {
    try {
      // Attempt to sign in with email and password
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      print('Admin logged in');
      return null; // Login successful
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found for this email.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'The email address is not valid.';
        default:
          return 'Failed to sign in. Please try again.';
      }
    } catch (e) {
      print('Error: $e');
      return 'An unexpected error occurred.';
    }
  }


  // Sign Out User
  Future<bool> signOut() async {
    try {
      await _auth.signOut();
      return true;
    } catch (e) {
      print('Error: $e');
      return false;
    }
  }

  // Get Current User (if logged in)
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Stream to listen to authentication state changes
  Stream<User?> get userChanges {
    return _auth.authStateChanges();
  }
}
