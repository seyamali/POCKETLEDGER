import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/core/utils/error_logger.dart';

class TransactionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Add Income or Expense
  Future<void> addTransaction(TransactionModel transaction) async {
    if (_uid == null) return;

    try {
      await _db.runTransaction((tx) async {
      final accountRef = _db.collection('accounts').doc(transaction.accountId);
      final accountDoc = await tx.get(accountRef);

      if (!accountDoc.exists) {
        throw AppException('Account not found');
      }

      final accountData = accountDoc.data() as Map<String, dynamic>;
      double currentTotal = (accountData['totalBalance'] ?? 0).toDouble();
      Map<String, double> breakdown = Map<String, double>.from(
        (accountData['breakdown'] ?? {}).map((key, value) => MapEntry(key, value.toDouble())),
      );

      double ownerBalance = breakdown[transaction.owner] ?? 0;

      if (transaction.type == TransactionType.income) {
        currentTotal += transaction.amount;
        ownerBalance += transaction.amount;
      } else if (transaction.type == TransactionType.expense) {
        currentTotal -= transaction.amount;
        ownerBalance -= transaction.amount;
      }

      breakdown[transaction.owner] = ownerBalance;

      // Update account
      tx.update(accountRef, {
        'totalBalance': currentTotal,
        'breakdown': breakdown,
      });

      // Create transaction record — always stamp the real userId from auth
      final transRef = _db.collection('transactions').doc();
      final transactionWithUserId = TransactionModel(
        id: transRef.id,
        accountId: transaction.accountId,
        accountName: transaction.accountName,
        owner: transaction.owner,
        amount: transaction.amount,
        type: transaction.type,
        category: transaction.category,
        note: transaction.note,
        date: transaction.date,
        userId: _uid!, // Always use the real auth UID
        toAccountId: transaction.toAccountId,
        toAccountName: transaction.toAccountName,
        toOwner: transaction.toOwner,
      );
      tx.set(transRef, transactionWithUserId.toFirestore());
      });
    } catch (e, stackTrace) {
      ErrorLogger.logError(e, stackTrace, 'addTransaction');
      rethrow;
    }
  }

  // Add Transfer
  Future<void> addTransfer({
    required String fromAccountId,
    required String fromAccountName,
    required String fromOwner,
    required String toAccountId,
    required String toAccountName,
    required String toOwner,
    required double amount,
    required String note,
    required String category,
  }) async {
    if (_uid == null) return;

    try {
      await _db.runTransaction((tx) async {
      final fromRef = _db.collection('accounts').doc(fromAccountId);
      final toRef = _db.collection('accounts').doc(toAccountId);

      final fromDoc = await tx.get(fromRef);
      final toDoc = await tx.get(toRef);

      if (!fromDoc.exists || !toDoc.exists) {
        throw AppException('One or more accounts not found');
      }

      // Update Source Account
      final fromData = fromDoc.data() as Map<String, dynamic>;
      double fromTotal = (fromData['totalBalance'] ?? 0).toDouble();
      Map<String, double> fromBreakdown = Map<String, double>.from(
        (fromData['breakdown'] ?? {}).map((key, value) => MapEntry(key, value.toDouble())),
      );
      fromTotal -= amount;
      fromBreakdown[fromOwner] = (fromBreakdown[fromOwner] ?? 0) - amount;

      tx.update(fromRef, {
        'totalBalance': fromTotal,
        'breakdown': fromBreakdown,
      });

      // Update Destination Account
      final toData = toDoc.data() as Map<String, dynamic>;
      double toTotal = (toData['totalBalance'] ?? 0).toDouble();
      Map<String, double> toBreakdown = Map<String, double>.from(
        (toData['breakdown'] ?? {}).map((key, value) => MapEntry(key, value.toDouble())),
      );
      toTotal += amount;
      toBreakdown[toOwner] = (toBreakdown[toOwner] ?? 0) + amount;

      tx.update(toRef, {
        'totalBalance': toTotal,
        'breakdown': toBreakdown,
      });

      // Create transaction record
      final transRef = _db.collection('transactions').doc();
      final transfer = TransactionModel(
        id: transRef.id,
        accountId: fromAccountId,
        accountName: fromAccountName,
        owner: fromOwner,
        amount: amount,
        type: TransactionType.transfer,
        category: category,
        note: note,
        date: DateTime.now(),
        userId: _uid!,
        toAccountId: toAccountId,
        toAccountName: toAccountName,
        toOwner: toOwner,
      );
      tx.set(transRef, transfer.toFirestore());
      });
    } catch (e, stackTrace) {
      ErrorLogger.logError(e, stackTrace, 'addTransfer');
      rethrow;
    }
  }

  // Add Transfer with a specific date (used by Savings page for month selection)
  Future<void> addTransferWithDate({
    required String fromAccountId,
    required String fromAccountName,
    required String fromOwner,
    required String toAccountId,
    required String toAccountName,
    required String toOwner,
    required double amount,
    required String note,
    required String category,
    required DateTime date,
  }) async {
    if (_uid == null) return;

    try {
      await _db.runTransaction((tx) async {
      final fromRef = _db.collection('accounts').doc(fromAccountId);
      final toRef = _db.collection('accounts').doc(toAccountId);

      final fromDoc = await tx.get(fromRef);
      final toDoc = await tx.get(toRef);

      if (!fromDoc.exists || !toDoc.exists) throw AppException('Account not found');

      final fromData = fromDoc.data() as Map<String, dynamic>;
      double fromTotal = (fromData['totalBalance'] ?? 0).toDouble();
      Map<String, double> fromBreakdown = Map<String, double>.from(
        (fromData['breakdown'] ?? {}).map((key, value) => MapEntry(key, value.toDouble())),
      );
      fromTotal -= amount;
      fromBreakdown[fromOwner] = (fromBreakdown[fromOwner] ?? 0) - amount;
      tx.update(fromRef, {'totalBalance': fromTotal, 'breakdown': fromBreakdown});

      final toData = toDoc.data() as Map<String, dynamic>;
      double toTotal = (toData['totalBalance'] ?? 0).toDouble();
      Map<String, double> toBreakdown = Map<String, double>.from(
        (toData['breakdown'] ?? {}).map((key, value) => MapEntry(key, value.toDouble())),
      );
      toTotal += amount;
      toBreakdown[toOwner] = (toBreakdown[toOwner] ?? 0) + amount;
      tx.update(toRef, {'totalBalance': toTotal, 'breakdown': toBreakdown});

      final transRef = _db.collection('transactions').doc();
      final transfer = TransactionModel(
        id: transRef.id,
        accountId: fromAccountId,
        accountName: fromAccountName,
        owner: fromOwner,
        amount: amount,
        type: TransactionType.transfer,
        category: category,
        note: note,
        date: date, // Use the provided date
        userId: _uid!,
        toAccountId: toAccountId,
        toAccountName: toAccountName,
        toOwner: toOwner,
      );
      tx.set(transRef, transfer.toFirestore());
      });
    } catch (e, stackTrace) {
      ErrorLogger.logError(e, stackTrace, 'addTransferWithDate');
      rethrow;
    }
  }

  // Get stream of recent transactions
  Stream<List<TransactionModel>> getRecentTransactions({int limit = 10}) {
    if (_uid == null) return Stream.value([]);

    return _db
        .collection('transactions')
        .where('userId', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
    });
  }

  // Get stream of transactions for a specific account (Updated to show transfers in both accounts)
  Stream<List<TransactionModel>> getTransactionsByAccount(String accountId, {int limit = 20}) {
    if (_uid == null) return Stream.value([]);
    
    // We use array-contains to find transactions where this account is involved
    // either as a primary account (accountId) or a target account (toAccountId)
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: _uid)
        .where('involvedAccountIds', arrayContains: accountId)
        .orderBy('date', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
    });
  }
  // Add a manual adjustment (doesn't affect a source account)
  Future<void> addManualBalanceAdjustment({
    required String accountId,
    required String accountName,
    required double amount,
    required String category,
    required DateTime date,
    required bool isAddition,
  }) async {
    if (_uid == null) return;

    try {
      await _db.runTransaction((tx) async {
      final accountRef = _db.collection('accounts').doc(accountId);
      final accountDoc = await tx.get(accountRef);

      if (!accountDoc.exists) throw AppException('Account not found');

      final accountData = accountDoc.data() as Map<String, dynamic>;
      double currentTotal = (accountData['totalBalance'] ?? 0).toDouble();
      Map<String, double> breakdown = Map<String, double>.from(
        (accountData['breakdown'] ?? {}).map((key, value) => MapEntry(key, value.toDouble())),
      );

      if (isAddition) {
        currentTotal += amount;
        breakdown['Self'] = (breakdown['Self'] ?? 0) + amount;
      } else {
        currentTotal -= amount;
        breakdown['Self'] = (breakdown['Self'] ?? 0) - amount;
      }

      tx.update(accountRef, {
        'totalBalance': currentTotal,
        'breakdown': breakdown,
      });

      final transRef = _db.collection('transactions').doc();
      final adjustment = TransactionModel(
        id: transRef.id,
        accountId: accountId,
        accountName: accountName,
        owner: 'Self',
        amount: amount,
        type: isAddition ? TransactionType.income : TransactionType.expense,
        category: category,
        note: 'Manual entry (Already paid)',
        date: date,
        userId: _uid!,
      );
      tx.set(transRef, adjustment.toFirestore());
      });
    } catch (e, stackTrace) {
      ErrorLogger.logError(e, stackTrace, 'addManualBalanceAdjustment');
      rethrow;
    }
  }
}
