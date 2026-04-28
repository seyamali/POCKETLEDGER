import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'package:pocketledger/utils/hash_helper.dart';
import 'dart:typed_data';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  // Firebase Storage removed for Spark Plan compatibility

  // Get current user UID
  String? get currentUserUid => _auth.currentUser?.uid;

  // Stream of auth changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential?> signIn(String email, String password) async {
    try {
      final hashedPassword = HashHelper.hashPassword(password);
      return await _auth.signInWithEmailAndPassword(
        email: email, 
        password: hashedPassword,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign up with Email and Password
  Future<UserCredential?> signUp({
    required String email, 
    required String password,
    required String name,
  }) async {
    try {
      // 1. Hash password as requested previously
      final hashedPassword = HashHelper.hashPassword(password);

      // 2. Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: hashedPassword,
      );

      // 3. Create a user profile in Firestore
      if (userCredential.user != null) {
        await _db.collection('users').doc(userCredential.user!.uid).set({
          'uid': userCredential.user!.uid,
          'email': email,
          'name': name,
          'createdAt': FieldValue.serverTimestamp(),
          'profilePic': '', // Placeholder for profile picture URL
        });
      }

      return userCredential;
    } catch (e) {
      rethrow;
    }
  }

  // Create/Initialize Profile
  Future<void> createProfile({required String name}) async {
    final uid = currentUserUid;
    final email = _auth.currentUser?.email;
    if (uid != null) {
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'name': name,
        'createdAt': FieldValue.serverTimestamp(),
        'profilePic': '',
      }, SetOptions(merge: true));
    }
  }

  // Update Profile
  Future<void> updateProfile({required String name, String? profilePic}) async {
    final uid = currentUserUid;
    if (uid != null) {
      final updates = <String, dynamic>{'name': name};
      if (profilePic != null) updates['profilePic'] = profilePic;
      
      await _db.collection('users').doc(uid).set(updates, SetOptions(merge: true));
    }
  }

  // Upload Profile Image (Converted to Base64 for Firestore)
  Future<String?> uploadProfileImage(Uint8List imageBytes) async {
    try {
      // 1. Convert bytes to Base64 string
      String base64Image = base64Encode(imageBytes);
      
      // 2. Format as a Data URL so Image.network can't use it, but MemoryImage can
      // We prefix it so we know it's a base64 string
      return "base64:$base64Image";
    } catch (e) {
      print('DEBUG: Base64 conversion error: $e');
      return null;
    }
  }

  // Get current user profile data
  Stream<DocumentSnapshot> getUserProfile() {
    final uid = currentUserUid;
    if (uid == null) return const Stream.empty();
    return _db.collection('users').doc(uid).snapshots();
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
