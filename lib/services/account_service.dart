import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocketledger/models/account_model.dart';
import 'package:pocketledger/models/transaction_model.dart';

class AccountService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Create a new account and initial transactions
  Future<String?> createAccount({
    required String name,
    required String type,
    required Map<String, double> breakdown,
    String? accountNumber,
    String? cardNumber,
    String? branchName,
    String? routingNumber,
    String? mobileNumber,
    bool isInstallmentEnabled = false,
    double installmentAmount = 0.0,
    String? installmentFrequency,
    int installmentDuration = 0,
    int installmentsPaid = 0,
    DateTime? nextDueDate,
  }) async {
    if (_uid == null) return null;

    // Rule #7: Total balance is the sum of all owner balances
    double totalBalance = breakdown.values.fold(0, (sum, val) => sum + val);

    final WriteBatch batch = _db.batch();

    // 1. Create the Account Document
    final docRef = _db.collection('accounts').doc();
    final account = AccountModel(
      id: docRef.id,
      name: name,
      type: type,
      totalBalance: totalBalance,
      breakdown: breakdown,
      userId: _uid!,
      accountNumber: accountNumber,
      cardNumber: cardNumber,
      branchName: branchName,
      routingNumber: routingNumber,
      mobileNumber: mobileNumber,
      isInstallmentEnabled: isInstallmentEnabled,
      installmentAmount: installmentAmount,
      installmentFrequency: installmentFrequency,
      installmentDuration: installmentDuration,
      installmentsPaid: installmentsPaid,
      nextDueDate: nextDueDate,
    );
    batch.set(docRef, account.toFirestore());

    // 2. Create "Opening Balance" transactions for each owner
    final now = DateTime.now();
    for (var entry in breakdown.entries) {
      if (entry.value > 0) {
        final transRef = _db.collection('transactions').doc();
        final transaction = TransactionModel(
          id: transRef.id,
          accountId: docRef.id,
          accountName: name,
          owner: entry.key,
          amount: entry.value,
          type: TransactionType.income,
          category: 'Opening Balance',
          note: 'Initial deposit',
          date: now,
          userId: _uid!,
        );
        batch.set(transRef, transaction.toFirestore());
      }
    }

    // Commit both the account and the initial transactions atomically
    await batch.commit();
    return docRef.id;
  }

  // Get stream of accounts for the current user
  Stream<List<AccountModel>> getAccounts() {
    final String? uid = _uid;
    
    if (uid == null) {
      return Stream.value([]);
    }

    return _db
        .collection('accounts')
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
            .map((doc) => AccountModel.fromFirestore(doc))
            .toList();
        });
  }

  // ONE-TIME MIGRATION SCRIPT
  // This looks at all existing accounts and creates "Opening Balance" transactions if they have money
  Future<void> runMigrationForOpeningBalances() async {
    if (_uid == null) return;

    final accountsSnapshot = await _db.collection('accounts').where('userId', isEqualTo: _uid).get();
    
    final WriteBatch batch = _db.batch();
    final now = DateTime.now();
    int addedCount = 0;

    for (var doc in accountsSnapshot.docs) {
      final account = AccountModel.fromFirestore(doc);
      
      // Check if transactions already exist for this account
      final existingTx = await _db
          .collection('transactions')
          .where('accountId', isEqualTo: account.id)
          .where('category', isEqualTo: 'Opening Balance')
          .limit(1)
          .get();

      // If no opening balance transaction exists, create them based on current breakdown
      if (existingTx.docs.isEmpty) {
        for (var entry in account.breakdown.entries) {
          if (entry.value > 0) {
            final transRef = _db.collection('transactions').doc();
            final transaction = TransactionModel(
              id: transRef.id,
              accountId: account.id,
              accountName: account.name,
              owner: entry.key,
              amount: entry.value,
              type: TransactionType.income,
              category: 'Opening Balance',
              note: 'Migrated initial deposit',
              date: now,
              userId: _uid!,
            );
            batch.set(transRef, transaction.toFirestore());
            addedCount++;
          }
        }
      }
    }

    if (addedCount > 0) {
      await batch.commit();
      print('Migration complete: Added $addedCount opening balance transactions.');
    } else {
      print('Migration skipped: No accounts needed opening balances.');
    }
  }
  // Update Account Name
  Future<void> updateAccountName(String accountId, String newName) async {
    if (_uid == null) return;

    final batch = _db.batch();
    
    // 1. Update the Account Document
    batch.update(_db.collection('accounts').doc(accountId), {'name': newName});

    // 2. Update all transactions where this account is the primary account
    final txQuery = await _db.collection('transactions')
        .where('userId', isEqualTo: _uid)
        .where('accountId', isEqualTo: accountId)
        .get();
        
    for (var doc in txQuery.docs) {
      batch.update(doc.reference, {'accountName': newName});
    }

    // 3. Update all transactions where this account is the target (for transfers)
    final toTxQuery = await _db.collection('transactions')
        .where('userId', isEqualTo: _uid)
        .where('toAccountId', isEqualTo: accountId)
        .get();
        
    for (var doc in toTxQuery.docs) {
      batch.update(doc.reference, {'toAccountName': newName});
    }

    await batch.commit();
  }

  // Update Account Details (Name, Bank Details, MFS Details)
  Future<void> updateAccountDetails({
    required String accountId,
    required String name,
    String? accountNumber,
    String? cardNumber,
    String? branchName,
    String? routingNumber,
    String? mobileNumber,
  }) async {
    if (_uid == null) return;

    final batch = _db.batch();

    // 1. Update the Account Document
    batch.update(_db.collection('accounts').doc(accountId), {
      'name': name,
      'accountNumber': accountNumber,
      'cardNumber': cardNumber,
      'branchName': branchName,
      'routingNumber': routingNumber,
      'mobileNumber': mobileNumber,
    });

    // 2. Update all transactions where this account is the primary account
    final txQuery = await _db.collection('transactions')
        .where('userId', isEqualTo: _uid)
        .where('accountId', isEqualTo: accountId)
        .get();
        
    for (var doc in txQuery.docs) {
      batch.update(doc.reference, {'accountName': name});
    }

    // 3. Update all transactions where this account is the target (for transfers)
    final toTxQuery = await _db.collection('transactions')
        .where('userId', isEqualTo: _uid)
        .where('toAccountId', isEqualTo: accountId)
        .get();
        
    for (var doc in toTxQuery.docs) {
      batch.update(doc.reference, {'toAccountName': name});
    }

    await batch.commit();
  }

  // Update Savings Installment Progress
  Future<void> updateSavingsInstallmentProgress(String accountId, int installmentsPaid, DateTime? nextDueDate) async {
    if (_uid == null) return;
    final data = <String, dynamic>{
      'installmentsPaid': installmentsPaid,
    };
    if (nextDueDate != null) {
      data['nextDueDate'] = Timestamp.fromDate(nextDueDate);
    }
    await _db.collection('accounts').doc(accountId).update(data);
  }
}
