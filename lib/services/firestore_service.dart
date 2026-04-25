import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? uid = FirebaseAuth.instance.currentUser?.uid;

  // Generic method to save data with the current User ID
  Future<void> saveData(String collection, Map<String, dynamic> data) async {
    if (uid == null) throw Exception("User not logged in");
    
    // Always attach the user's UID to the data
    data['userId'] = uid;
    data['createdAt'] = FieldValue.serverTimestamp();
    
    await _db.collection(collection).add(data);
  }

  // Generic method to fetch ONLY the current user's data
  Stream<QuerySnapshot> getUserData(String collection) {
    if (uid == null) throw Exception("User not logged in");
    
    // Filter the query so it only returns documents matching the user's UID
    return _db.collection(collection)
        .where('userId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Example: Save a transaction
  Future<void> addTransaction(Map<String, dynamic> transactionData) async {
    await saveData('transactions', transactionData);
  }

  // Example: Get all transactions for the logged-in user
  Stream<QuerySnapshot> getTransactions() {
    return getUserData('transactions');
  }
}
