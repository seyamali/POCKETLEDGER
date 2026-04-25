import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocketledger/utils/hash_helper.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Secret key for JWT (In a real app, store this securely in an environment variable)
  final String _jwtSecret = 'your-very-secure-pocketledger-secret-key';

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

  // Sign up and store hashed password in Firestore + Use JWT
  Future<Map<String, dynamic>> signUp(String email, String password) async {
    try {
      final hashedPassword = HashHelper.hashPassword(password);
      
      // 1. Create user in Firebase Auth
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: hashedPassword,
      );

      final String uid = userCredential.user!.uid;

      // 2. Store user profile in Firestore (including hashed password)
      await _db.collection('users').doc(uid).set({
        'uid': uid,
        'email': email,
        'password': hashedPassword, // Storing as requested
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Generate a JWT for this user
      final jwt = JWT(
        {
          'uid': uid,
          'email': email,
          'iat': DateTime.now().millisecondsSinceEpoch,
        },
        issuer: 'pocketledger-app',
      );

      final token = jwt.sign(SecretKey(_jwtSecret));

      return {
        'userCredential': userCredential,
        'jwt': token,
      };
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
