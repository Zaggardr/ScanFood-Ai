import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../screens/role_manager.dart';
import 'dart:io';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Vérifier la connectivité avec un ping
  Future<bool> _checkNetwork() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult == ConnectivityResult.none) {
      print('No internet connection');
      return false;
    }
    try {
      final result = await InternetAddress.lookup(
        'firestore.googleapis.com',
      ).timeout(
        Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Network lookup timed out');
        },
      );
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        print('Network test successful');
        return true;
      }
      print('Network test failed: No valid response');
      return false;
    } catch (e) {
      print('Network test failed: $e');
      return false;
    }
  }

  Future<(User?, String?)> register(
    String email,
    String password, {
    String? name,
    String? city,
    String? username,
    String? imageUrl,
    required String role,
  }) async {
    print(
      'Register attempt: email=$email, role=$role, username=$username, imageUrl=$imageUrl',
    );
    if (!await _checkNetwork()) {
      return (null, 'No internet connection. Please check your network.');
    }
    try {
      UserCredential result = await _auth
          .createUserWithEmailAndPassword(email: email, password: password)
          .timeout(
            Duration(seconds: 15),
            onTimeout: () {
              throw FirebaseAuthException(
                code: 'timeout',
                message: 'Authentication timed out. Please check your network.',
              );
            },
          );
      User? user = result.user;
      if (user != null) {
        try {
          print('Attempting to set user role for: ${user.email}');
          await RoleManager.setUserRole(
            user,
            role,
            username: username,
            imageUrl: imageUrl,
          );
          print('Registration successful: ${user.email}');
          return (user, null);
        } catch (e) {
          print('Error setting user role: $e');
          try {
            await user.delete();
            print('User deleted due to role setting failure: ${user.email}');
          } catch (deleteError) {
            print('Error deleting user: $deleteError');
          }
          return (null, 'Failed to set user role: $e');
        }
      }
      print('Registration failed: No user created');
      return (null, 'No user created');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: code=${e.code}, message=${e.message}');
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'weak-password':
          errorMessage = 'The password is too weak (minimum 6 characters).';
          break;
        case 'timeout':
          errorMessage = 'Authentication timed out. Please check your network.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during registration.';
      }
      return (null, errorMessage);
    } catch (e) {
      print('Unexpected error during registration: $e');
      return (null, 'Unexpected error: $e');
    }
  }

  Future<User?> login(String email, String password) async {
    print('Login attempt: email=$email');
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print('Login successful: ${result.user?.email}');
      return result.user;
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: code=${e.code}, message=${e.message}');
      return null;
    } catch (e) {
      print('Unexpected error during login: $e');
      return null;
    }
  }

  Future<void> resetPassword(String email) async {
    print('Reset password attempt: email=$email');
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print('Reset email sent to $email');
    } on FirebaseAuthException catch (e) {
      print('FirebaseAuthException: code=${e.code}, message=${e.message}');
      throw e;
    } catch (e) {
      print('Unexpected error during reset: $e');
      throw e;
    }
  }

  Future<(bool, String?)> sendEmailVerification(User user) async {
    print('Attempting to send verification email to: ${user.email}');
    try {
      if (!user.emailVerified) {
        await user.sendEmailVerification().timeout(
          Duration(seconds: 10),
          onTimeout: () {
            throw Exception('Email verification timed out');
          },
        );
        print('Verification email sent to: ${user.email}');
        return (true, null);
      }
      print('User already verified: ${user.email}');
      return (true, 'User already verified');
    } on FirebaseAuthException catch (e) {
      print(
        'FirebaseAuthException in sendEmailVerification: code=${e.code}, message=${e.message}',
      );
      return (false, 'Failed to send verification email: ${e.message}');
    } catch (e) {
      print('Unexpected error in sendEmailVerification: $e');
      return (false, 'Failed to send verification email: $e');
    }
  }
}
