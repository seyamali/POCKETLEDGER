import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocketledger/utils/hash_helper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
  Future<void> updateProfile({required String name, required String profilePic}) async {
    final uid = currentUserUid;
    if (uid != null) {
      await _db.collection('users').doc(uid).update({
        'name': name,
        'profilePic': profilePic,
      });
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
