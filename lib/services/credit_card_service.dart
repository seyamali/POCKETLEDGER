import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocketledger/models/credit_card_model.dart';
import 'package:pocketledger/services/notification_service.dart';

class CreditCardService {
  static final CreditCardService _instance = CreditCardService._internal();
  factory CreditCardService() => _instance;
  CreditCardService._internal();

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final NotificationService _notificationService = NotificationService();

  String get _uid => FirebaseAuth.instance.currentUser!.uid;
  CollectionReference get _col => _db.collection('users').doc(_uid).collection('creditCards');

  // ── Streams ─────────────────────────────────────────────────────────────────

  Stream<List<CreditCardModel>> getCards() {
    return _col.orderBy('createdAt', descending: false).snapshots().map(
      (snap) => snap.docs.map((d) => CreditCardModel.fromFirestore(d)).toList(),
    );
  }

  // ── CRUD ────────────────────────────────────────────────────────────────────

  Future<void> addCard(CreditCardModel card) async {
    final ref = await _col.add(card.toFirestore());
    final saved = card.copyWith();
    // Schedule reminder using the Firestore-assigned ID
    await _notificationService.scheduleCardDueReminder(
      cardId: ref.id,
      cardNickname: saved.cardNickname,
      dueDate: saved.nextDueDate,
      minimumPayment: saved.minimumPayment,
    );
  }

  Future<void> updateCard(CreditCardModel card) async {
    await _col.doc(card.id).update(card.toFirestore());
    await _notificationService.cancelCardReminder(card.id);
    await _notificationService.scheduleCardDueReminder(
      cardId: card.id,
      cardNickname: card.cardNickname,
      dueDate: card.nextDueDate,
      minimumPayment: card.minimumPayment,
    );
  }

  Future<void> updateBalance(String cardId, double newBalance) async {
    await _col.doc(cardId).update({'outstandingBalance': newBalance});
  }

  /// Increase outstanding balance (charge made on card)
  Future<void> addCharge(String cardId, double amount) async {
    await _col.doc(cardId).update({
      'outstandingBalance': FieldValue.increment(amount),
    });
  }

  /// Decrease outstanding balance (payment made)
  Future<void> recordPayment(String cardId, double amount) async {
    await _col.doc(cardId).update({
      'outstandingBalance': FieldValue.increment(-amount),
    });
  }

  Future<void> deleteCard(String cardId) async {
    await _col.doc(cardId).delete();
    await _notificationService.cancelCardReminder(cardId);
  }

  // ── Aggregates (for Dashboard) ──────────────────────────────────────────────

  Stream<Map<String, double>> getCreditSummary() {
    return getCards().map((cards) {
      final totalLimit = cards.fold<double>(0, (s, c) => s + c.creditLimit);
      final totalBalance = cards.fold<double>(0, (s, c) => s + c.outstandingBalance);
      return {
        'totalLimit': totalLimit,
        'totalBalance': totalBalance,
        'utilization': totalLimit > 0 ? totalBalance / totalLimit : 0,
      };
    });
  }
}
