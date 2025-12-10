import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RoleManager {
  static const String ROLE_USER = 'user';
  static const String ROLE_ADMIN = 'admin';
  static const String ROLE_ENTERPRISE = 'enterprise';
  static const String ADMIN_EMAIL = 'abdelghafourkorachi9@gmail.com';

  static Future<String> getUserRole(User user) async {
    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .get();

      if (doc.exists) {
        String role = doc.get('role') as String? ?? ROLE_USER;
        // If the user is the admin email but the role isn't admin, update it
        if (user.email == ADMIN_EMAIL && role != ROLE_ADMIN) {
          await setUserRole(user, ROLE_ADMIN);
          return ROLE_ADMIN;
        }
        // If the user isn't the admin email but has the admin role, downgrade to user
        if (user.email != ADMIN_EMAIL && role == ROLE_ADMIN) {
          await setUserRole(user, ROLE_USER);
          return ROLE_USER;
        }
        return role;
      }
      // If no document exists, set the role based on email
      String defaultRole = (user.email == ADMIN_EMAIL) ? ROLE_ADMIN : ROLE_USER;
      await setUserRole(user, defaultRole);
      return defaultRole;
    } catch (e) {
      print('Error getting user role: $e');
      return ROLE_USER;
    }
  }

  static Future<void> setUserRole(
    User user,
    String role, {
    String? username,
    String? imageUrl,
  }) async {
    try {
      // Enforce that only the ADMIN_EMAIL can have ROLE_ADMIN
      String finalRole = role;
      if (user.email == ADMIN_EMAIL) {
        finalRole = ROLE_ADMIN;
      } else if (role == ROLE_ADMIN) {
        finalRole = ROLE_USER; // Prevent non-admin email from being ROLE_ADMIN
      }

      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'email': user.email,
        'role': finalRole,
        'username': username ?? user.email?.split('@').first ?? '',
        'imageUrl': imageUrl ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error setting user role: $e');
      rethrow;
    }
  }
}
