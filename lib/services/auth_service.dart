import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get current AppUser data from Firestore
  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return AppUser.fromMap(doc.data()!, user.uid);
  }

  // Student Sign Up
  Future<AppUser?> signUpStudent({
    required String email,
    required String password,
    required String enrollmentId,
    required String department,
    required String course,
    required String section,
    required String semester,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) return null;

      // Create user document in Firestore
      final appUser = AppUser(
        uid: user.uid,
        email: email,
        role: 'student',
        enrollmentId: enrollmentId,
        department: department,
        course: course,
        section: section,
        semester: semester,
      );

      await _firestore.collection('users').doc(user.uid).set(appUser.toMap());

      return appUser;
    } catch (e) {
      throw Exception('Sign up failed: ${e.toString()}');
    }
  }

  // Student/Regular Login
  Future<AppUser?> signIn({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = result.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Authentication failed',
        );
      }

      // Get user data from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        throw FirebaseAuthException(
          code: 'user-data-not-found',
          message: 'User profile not found. Please contact support.',
        );
      }

      return AppUser.fromMap(doc.data()!, user.uid);
    } on FirebaseAuthException {
      rethrow; // Re-throw FirebaseAuthException to preserve error codes
    } catch (e) {
      throw FirebaseAuthException(code: 'sign-in-error', message: e.toString());
    }
  }

  // Admin Login with preset department emails
  // Expected format: cseadtu@admin.in, eceadtu@admin.in, etc.
  Future<AppUser?> signInAdmin({
    required String email,
    required String password,
  }) async {
    try {
      // Validate admin email format
      final emailLower = email.trim().toLowerCase();
      if (!emailLower.endsWith('@admin.in')) {
        throw FirebaseAuthException(
          code: 'invalid-admin-email',
          message: 'Admin email must end with @admin.in',
        );
      }

      // Try to sign in with email and password
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: emailLower,
        password: password,
      );

      User? user = result.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Authentication failed',
        );
      }

      // Get admin user data from Firestore
      final doc = await _firestore.collection('users').doc(user.uid).get();
      
      AppUser appUser;
      if (!doc.exists) {
        // Auto-create admin profile if doesn't exist (for preset accounts)
        // Extract department from email (e.g., cseadtu@admin.in -> CSE)
        final deptCode = emailLower.replaceAll('adtu@admin.in', '').toUpperCase();
        
        appUser = AppUser(
          uid: user.uid,
          email: emailLower,
          role: 'admin',
          department: deptCode,
        );
        
        await _firestore.collection('users').doc(user.uid).set(appUser.toMap());
      } else {
        appUser = AppUser.fromMap(doc.data()!, user.uid);
        
        // Verify this is an admin account
        if (!appUser.isAdmin) {
          await _auth.signOut(); // Sign out non-admin user
          throw FirebaseAuthException(
            code: 'not-admin',
            message: 'This account is not authorized as admin/teacher.',
          );
        }
      }

      return appUser;
    } on FirebaseAuthException {
      rethrow; // Re-throw FirebaseAuthException to preserve error codes
    } catch (e) {
      throw FirebaseAuthException(
        code: 'admin-sign-in-error',
        message: e.toString(),
      );
    }
  }  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if user is logged in
  bool isLoggedIn() {
    return currentUser != null;
  }
}
