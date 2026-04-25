import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocketledger/models/account_model.dart';

class AccountService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Create a new account
  Future<void> createAccount({
    required String name,
    required String type,
    required String initialOwner,
    required double initialBalance,
  }) async {
    if (_uid == null) return;

    final docRef = _db.collection('accounts').doc();
    final account = AccountModel(
      id: docRef.id,
      name: name,
      type: type,
      totalBalance: initialBalance,
      breakdown: {initialOwner: initialBalance},
      userId: _uid!,
    );

    await docRef.set(account.toFirestore());
  }

  // Get stream of accounts for the current user
  Stream<List<AccountModel>> getAccounts() {
    final String? uid = _uid;
    print('DEBUG: Fetching accounts for UID: $uid');
    
    if (uid == null) {
      print('DEBUG: No user logged in, returning empty stream');
      return const Stream.empty();
    }

    return _db
        .collection('accounts')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          print('DEBUG: Found ${snapshot.docs.length} accounts in Firestore');
          return snapshot.docs
            .map((doc) => AccountModel.fromFirestore(doc))
            .toList();
        });
  }
}
