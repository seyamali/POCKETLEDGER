import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocketledger/models/recurring_bill_model.dart';
import 'package:pocketledger/models/transaction_model.dart';
import 'package:pocketledger/services/transaction_service.dart';
import 'package:pocketledger/core/utils/error_logger.dart';

import 'package:pocketledger/services/notification_service.dart';

class RecurringBillService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TransactionService _txService = TransactionService();
  final NotificationService _notificationService = NotificationService();

  String? get _uid => _auth.currentUser?.uid;

  static final RecurringBillService _instance = RecurringBillService._internal();
  factory RecurringBillService() => _instance;
  RecurringBillService._internal();

  /// Adds a new recurring subscription to Firestore
  Future<void> createRecurringBill(RecurringBillModel bill) async {
    if (_uid == null) return;
    try {
      final docRef = _db.collection('recurring_bills').doc();
      final newBill = RecurringBillModel(
        id: docRef.id,
        title: bill.title,
        amount: bill.amount,
        category: bill.category,
        frequency: bill.frequency,
        nextDueDate: bill.nextDueDate,
        linkedAccountId: bill.linkedAccountId,
        linkedAccountName: bill.linkedAccountName,
        userId: _uid!,
        isActive: bill.isActive,
      );
      await docRef.set(newBill.toFirestore());

      if (newBill.isActive) {
        await _notificationService.scheduleBillReminder(
          id: newBill.id,
          title: newBill.title,
          dueDate: newBill.nextDueDate,
          amount: newBill.amount,
        );
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError(e, stackTrace, 'createRecurringBill');
      rethrow;
    }
  }

  /// Gets a real-time stream of recurring subscriptions for the logged-in user
  Stream<List<RecurringBillModel>> getRecurringBills() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('recurring_bills')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => RecurringBillModel.fromFirestore(doc))
            .toList());
  }

  /// Updates recurring bill properties
  Future<void> updateRecurringBill(RecurringBillModel bill) async {
    if (_uid == null) return;
    try {
      await _db
          .collection('recurring_bills')
          .doc(bill.id)
          .update(bill.toFirestore());

      // Always cancel existing reminder to avoid duplicate or stale notifications
      await _notificationService.cancelBillReminder(bill.id);

      if (bill.isActive) {
        await _notificationService.scheduleBillReminder(
          id: bill.id,
          title: bill.title,
          dueDate: bill.nextDueDate,
          amount: bill.amount,
        );
      }
    } catch (e, stackTrace) {
      ErrorLogger.logError(e, stackTrace, 'updateRecurringBill');
      rethrow;
    }
  }

  /// Deletes a recurring bill config
  Future<void> deleteRecurringBill(String billId) async {
    if (_uid == null) return;
    try {
      await _db.collection('recurring_bills').doc(billId).delete();
      await _notificationService.cancelBillReminder(billId);
    } catch (e, stackTrace) {
      ErrorLogger.logError(e, stackTrace, 'deleteRecurringBill');
      rethrow;
    }
  }

  /// Processes payment of a bill: records the transaction, adjusts account balance, and advances the due date
  Future<void> payBill(RecurringBillModel bill) async {
    if (_uid == null) return;
    try {
      // 1. Create the Transaction (if an account is linked)
      if (bill.linkedAccountId != null) {
        final tx = TransactionModel(
          id: '',
          accountId: bill.linkedAccountId!,
          accountName: bill.linkedAccountName ?? '',
          owner: 'Self',
          amount: bill.amount,
          type: TransactionType.expense,
          category: bill.category,
          note: 'Subscription: ${bill.title}',
          date: DateTime.now(),
          userId: _uid!,
        );
        await _txService.addTransaction(tx);
      }

      // 2. Increment the nextDueDate by the selected frequency duration
      DateTime nextDate;
      final freq = bill.frequency.toLowerCase();
      if (freq == 'weekly') {
        nextDate = bill.nextDueDate.add(const Duration(days: 7));
      } else if (freq == 'yearly') {
        nextDate = DateTime(bill.nextDueDate.year + 1, bill.nextDueDate.month, bill.nextDueDate.day);
      } else {
        // Monthly
        nextDate = DateTime(bill.nextDueDate.year, bill.nextDueDate.month + 1, bill.nextDueDate.day);
      }

      final updatedBill = RecurringBillModel(
        id: bill.id,
        title: bill.title,
        amount: bill.amount,
        category: bill.category,
        frequency: bill.frequency,
        nextDueDate: nextDate,
        linkedAccountId: bill.linkedAccountId,
        linkedAccountName: bill.linkedAccountName,
        userId: bill.userId,
        isActive: bill.isActive,
      );

      await updateRecurringBill(updatedBill);
    } catch (e, stackTrace) {
      ErrorLogger.logError(e, stackTrace, 'payBill');
      rethrow;
    }
  }
}
