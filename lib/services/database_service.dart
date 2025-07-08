import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DatabaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create or update user in Firestore
  Future<void> createUserDocument(User user, {bool isNewUser = false}) async {
    final userRef = _firestore.collection('users').doc(user.uid);

    try {
      final userDoc = await userRef.get();

      if (!userDoc.exists || isNewUser) {
        // Create new user document
        final userData = {
          'uid': user.uid,
          'email': user.email ?? '',
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
          'phoneNumber': user.phoneNumber ?? '',
          'createdAt': FieldValue.serverTimestamp(),
          'lastLoginAt': FieldValue.serverTimestamp(),
          'isEmailVerified': user.emailVerified,
          'signInProvider': 'google',
          // Add any additional user preferences or settings
          'preferences': {
            'notifications': true,
            'theme': 'light',
            'currency': 'USD',
          },
        };

        await userRef.set(userData);
        print('✅ New user document created in Firestore');
      } else {
        // Update existing user's last login time
        await userRef.update({
          'lastLoginAt': FieldValue.serverTimestamp(),
          'displayName': user.displayName ?? '',
          'photoURL': user.photoURL ?? '',
        });
        print('✅ User login time updated in Firestore');
      }
    } catch (e) {
      print('❌ Error saving user to Firestore: $e');
      throw Exception('Failed to save user data: $e');
    }
  }

  // Get user data from Firestore
  Future<DocumentSnapshot> getUserData(String uid) async {
    try {
      return await _firestore.collection('users').doc(uid).get();
    } catch (e) {
      print('❌ Error getting user data: $e');
      throw Exception('Failed to get user data: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(String uid, Map<String, dynamic> data) async {
    try {
      // Add updateAt timestamp to the data
      data['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('users').doc(uid).update(data);
      print('✅ User data updated successfully');
    } catch (e) {
      print('❌ Error updating user data: $e');
      throw Exception('Failed to update user data: $e');
    }
  }

  // Stream user data for real-time updates
  Stream<DocumentSnapshot> getUserDataStream(String uid) {
    return _firestore.collection('users').doc(uid).snapshots();
  }

  // Delete user document
  Future<void> deleteUserDocument(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
      print('✅ User document deleted successfully');
    } catch (e) {
      print('❌ Error deleting user document: $e');
      throw Exception('Failed to delete user document: $e');
    }
  }

  // Check if user document exists
  Future<bool> userDocumentExists(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      return doc.exists;
    } catch (e) {
      print('❌ Error checking user document existence: $e');
      return false;
    }
  }

  // Update user preferences
  Future<void> updateUserPreferences(String uid, Map<String, dynamic> preferences) async {
    try {
      await _firestore.collection('users').doc(uid).update({
        'preferences': preferences,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('✅ User preferences updated successfully');
    } catch (e) {
      print('❌ Error updating user preferences: $e');
      throw Exception('Failed to update user preferences: $e');
    }
  }
}
