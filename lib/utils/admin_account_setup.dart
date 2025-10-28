import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Run this script ONCE to create the 6 preset admin accounts
/// This should be run by a system administrator
/// 
/// HOW TO RUN:
/// 1. Create a temporary button in your app
/// 2. Call setupPresetAdminAccounts() when clicked
/// 3. Remove the button after setup is complete

class AdminAccountSetup {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Preset admin accounts for 6 departments
  static const Map<String, Map<String, String>> presetAdmins = {
    'CSE': {
      'email': 'cseadtu@admin.in',
      'password': 'cse1234',
      'department': 'CSE',
    },
    'ECE': {
      'email': 'eceadtu@admin.in',
      'password': 'ece1234',
      'department': 'ECE',
    },
    'ME': {
      'email': 'meadtu@admin.in',
      'password': 'me1234',
      'department': 'ME',
    },
    'CE': {
      'email': 'ceadtu@admin.in',
      'password': 'ce1234',
      'department': 'CE',
    },
    'EE': {
      'email': 'eeadtu@admin.in',
      'password': 'ee1234',
      'department': 'EE',
    },
    'IT': {
      'email': 'itadtu@admin.in',
      'password': 'it1234',
      'department': 'IT',
    },
  };

  /// Create all preset admin accounts
  static Future<Map<String, dynamic>> setupPresetAdminAccounts() async {
    final results = <String, dynamic>{};
    int successCount = 0;
    int failureCount = 0;
    final errors = <String>[];

    for (final entry in presetAdmins.entries) {
      final dept = entry.key;
      final credentials = entry.value;

      try {
        await _createSingleAdminAccount(
          email: credentials['email']!,
          password: credentials['password']!,
          department: credentials['department']!,
        );

        results[dept] = 'Created successfully';
        successCount++;
        print('✅ $dept admin account created: ${credentials['email']}');
      } catch (e) {
        results[dept] = 'Failed: $e';
        failureCount++;
        errors.add('$dept: $e');
        print('❌ Failed to create $dept admin: $e');
      }
    }

    results['summary'] = {
      'total': presetAdmins.length,
      'success': successCount,
      'failed': failureCount,
      'errors': errors,
    };

    return results;
  }

  /// Create a single admin account
  static Future<void> _createSingleAdminAccount({
    required String email,
    required String password,
    required String department,
  }) async {
    try {
      // Create user in Firebase Auth
      final UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = result.user;
      if (user == null) {
        throw Exception('Failed to create user');
      }

      // Create user profile in Firestore
      await _firestore.collection('users').doc(user.uid).set({
        'email': email,
        'role': 'admin',
        'department': department,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Sign out after creating each account
      await _auth.signOut();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('⚠️  Account already exists: $email');
        return; // Skip if already exists
      }
      rethrow;
    }
  }

  /// Delete all preset admin accounts (use with caution!)
  static Future<void> deleteAllPresetAdminAccounts() async {
    print('⚠️  WARNING: This will delete all preset admin accounts!');

    for (final entry in presetAdmins.entries) {
      final dept = entry.key;
      final email = entry.value['email']!;
      final password = entry.value['password']!;

      try {
        // Sign in to delete
        final UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );

        if (result.user != null) {
          // Delete Firestore document
          await _firestore.collection('users').doc(result.user!.uid).delete();

          // Delete Firebase Auth account
          await result.user!.delete();

          print('✅ Deleted $dept admin account');
        }
      } catch (e) {
        print('❌ Failed to delete $dept admin: $e');
      }
    }

    await _auth.signOut();
  }
}
