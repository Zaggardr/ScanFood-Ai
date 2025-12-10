import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/role_manager.dart';

class UserService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new user (for admin)
  Future<(User?, String?)> createUser({
    required String email,
    required String role,
    String? name,
    String? city,
  }) async {
    try {
      // Generate a temporary password
      String tempPassword = 'Temp@${DateTime.now().millisecondsSinceEpoch}';
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: tempPassword,
      );
      User? user = result.user;

      if (user != null) {
        // Set role and additional info in Firestore
        await RoleManager.setUserRole(user, role);
        await _firestore.collection('users').doc(user.uid).update({
          'name': name ?? '',
          'city': city ?? '',
          'updatedAt': FieldValue.serverTimestamp(),
        });

        // Send password reset email for user to set their password
        await _auth.sendPasswordResetEmail(email: email);
        return (user, null);
      }
      return (null, 'Failed to create user');
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'email-already-in-use':
          errorMessage = 'This email is already registered.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during user creation.';
      }
      return (null, errorMessage);
    } catch (e) {
      return (null, 'Unexpected error: $e');
    }
  }

  // Get all users (for admin)
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      QuerySnapshot snapshot = await _firestore.collection('users').get();
      return snapshot.docs.map((doc) {
        return {'uid': doc.id, ...doc.data() as Map<String, dynamic>};
      }).toList();
    } catch (e) {
      throw Exception('Error fetching users: $e');
    }
  }

  // Update user details
  Future<String?> updateUser({
    required String uid,
    String? name,
    String? city,
    String? role,
  }) async {
    try {
      Map<String, dynamic> updates = {};
      if (name != null) updates['name'] = name;
      if (city != null) updates['city'] = city;
      if (role != null) updates['role'] = role;
      if (updates.isNotEmpty) {
        updates['updatedAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(uid).update(updates);
      }
      return null;
    } catch (e) {
      return 'Error updating user: $e';
    }
  }

  // Delete user
  Future<String?> deleteUser(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      // Note: Firebase Auth user deletion requires admin SDK, so we only remove Firestore data
      return null;
    } catch (e) {
      return 'Error deleting user: $e';
    }
  }
}
