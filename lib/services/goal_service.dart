import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocketledger/models/goal_model.dart';
import 'package:pocketledger/models/transaction_model.dart';

class GoalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;
  CollectionReference get _col => _db.collection('goals');

  // Set or update a goal for a specific month
  Future<void> setGoal({
    required String monthYear,
    required double incomeTarget,
    required double expenseLimit,
    required double savingsTarget,
    required Map<String, double> categoryLimits,
    double initialProgressIncome = 0,
    double initialProgressExpense = 0,
    double initialProgressSavings = 0,
  }) async {
    if (_uid == null) return;

    final query = await _col
        .where('userId', isEqualTo: _uid)
        .where('monthYear', isEqualTo: monthYear)
        .limit(1)
        .get();

    if (query.docs.isNotEmpty) {
      // Update existing
      await _col.doc(query.docs.first.id).update({
        'incomeTarget': incomeTarget,
        'expenseLimit': expenseLimit,
        'savingsTarget': savingsTarget,
        'initialProgressIncome': initialProgressIncome,
        'initialProgressExpense': initialProgressExpense,
        'initialProgressSavings': initialProgressSavings,
        'categoryLimits': categoryLimits,
      });
    } else {
      // Create new
      final docRef = _col.doc();
      final goal = GoalModel(
        id: docRef.id,
        monthYear: monthYear,
        incomeTarget: incomeTarget,
        expenseLimit: expenseLimit,
        savingsTarget: savingsTarget,
        initialProgressIncome: initialProgressIncome,
        initialProgressExpense: initialProgressExpense,
        initialProgressSavings: initialProgressSavings,
        categoryLimits: categoryLimits,
        userId: _uid!,
      );
      await docRef.set(goal.toFirestore());
    }
  }

  // Get Goal for a specific month
  Stream<GoalModel?> getGoal(String monthYear) {
    if (_uid == null) return Stream.value(null);

    return _col
        .where('userId', isEqualTo: _uid)
        .where('monthYear', isEqualTo: monthYear)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      return GoalModel.fromFirestore(snapshot.docs.first);
    });
  }

  // Helper to fetch all transactions for a specific month (locally filtered to bypass indexes)
  Stream<List<TransactionModel>> getTransactionsForMonth(int month, int year) {
    if (_uid == null) return Stream.value([]);

    // We fetch all transactions and filter locally because filtering by month/year requires complex queries
    // or adding month/year fields to the transactions table. For a local app, this is fast enough.
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransactionModel.fromFirestore(doc))
          .where((tx) => tx.date.month == month && tx.date.year == year)
          .toList();
    });
  }

  // Fetch all transactions for multi-month charting
  Stream<List<TransactionModel>> getAllTransactions() {
    if (_uid == null) return Stream.value([]);
    return _db
        .collection('transactions')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).toList();
    });
  }
}
