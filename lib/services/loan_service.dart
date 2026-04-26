import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:pocketledger/models/transaction_model.dart';

class LoanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // Add a new loan
  Future<void> addLoan({
    required String personName,
    required double amount,
    required LoanType type,
    String? linkedAccountId,
    String? linkedAccountName,
    required String note,
  }) async {
    if (_uid == null) return;

    await _db.runTransaction((tx) async {
      // 1. Create the Loan document
      final loanRef = _db.collection('loans').doc();
      final loan = LoanModel(
        id: loanRef.id,
        personName: personName,
        amount: amount,
        remainingAmount: amount,
        type: type,
        status: LoanStatus.pending,
        linkedAccountId: linkedAccountId,
        date: DateTime.now(),
        note: note,
        userId: _uid!,
        repayments: [],
      );
      
      tx.set(loanRef, loan.toFirestore());

      // 2. If a linked account is provided, affect the account balance and add a transaction
      if (linkedAccountId != null && linkedAccountName != null) {
        final accountRef = _db.collection('accounts').doc(linkedAccountId);
        final accountDoc = await tx.get(accountRef);

        if (!accountDoc.exists) throw Exception('Linked account not found');

        final accountData = accountDoc.data() as Map<String, dynamic>;
        double currentTotal = (accountData['totalBalance'] ?? 0).toDouble();
        Map<String, double> breakdown = Map<String, double>.from(
          (accountData['breakdown'] ?? {}).map((key, value) => MapEntry(key, value.toDouble())),
        );

        // Assume the loan is tied to 'Self' owner for simplicity, or we could ask for owner.
        // We will default to 'Self'.
        String owner = 'Self';
        double ownerBalance = breakdown[owner] ?? 0;

        TransactionType transType;
        if (type == LoanType.given) {
          // Money is going out of the account
          currentTotal -= amount;
          ownerBalance -= amount;
          transType = TransactionType.expense;
        } else {
          // Money is coming into the account
          currentTotal += amount;
          ownerBalance += amount;
          transType = TransactionType.income;
        }

        breakdown[owner] = ownerBalance;

        tx.update(accountRef, {
          'totalBalance': currentTotal,
          'breakdown': breakdown,
        });

        // Add a normal transaction to reflect this change
        final transRef = _db.collection('transactions').doc();
        final transaction = TransactionModel(
          id: transRef.id,
          accountId: linkedAccountId,
          accountName: linkedAccountName,
          owner: owner,
          amount: amount,
          type: transType,
          category: type == LoanType.given ? 'Loan Given' : 'Loan Taken',
          note: 'Loan with $personName',
          date: DateTime.now(),
          userId: _uid!,
        );
        tx.set(transRef, transaction.toFirestore());
      }
    });
  }

  // Add a repayment to a loan
  Future<void> addRepayment({
    required String loanId,
    required double paymentAmount,
    String? linkedAccountId,
    String? linkedAccountName,
    required String note,
  }) async {
    if (_uid == null) return;

    await _db.runTransaction((tx) async {
      final loanRef = _db.collection('loans').doc(loanId);
      final loanDoc = await tx.get(loanRef);

      if (!loanDoc.exists) throw Exception('Loan not found');

      final loan = LoanModel.fromFirestore(loanDoc);
      
      if (loan.remainingAmount < paymentAmount) {
        throw Exception('Payment amount cannot exceed remaining balance');
      }

      double newRemaining = loan.remainingAmount - paymentAmount;
      LoanStatus newStatus = newRemaining <= 0 ? LoanStatus.paid : LoanStatus.pending;

      final repayment = RepaymentModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        amount: paymentAmount,
        date: DateTime.now(),
        note: note,
      );

      final updatedRepayments = List<RepaymentModel>.from(loan.repayments)..add(repayment);

      tx.update(loanRef, {
        'remainingAmount': newRemaining,
        'status': newStatus == LoanStatus.paid ? 'paid' : 'pending',
        'repayments': updatedRepayments.map((r) => r.toMap()).toList(),
      });

      // If tied to an account, adjust balances
      if (linkedAccountId != null && linkedAccountName != null) {
        final accountRef = _db.collection('accounts').doc(linkedAccountId);
        final accountDoc = await tx.get(accountRef);

        if (!accountDoc.exists) throw Exception('Linked account not found');

        final accountData = accountDoc.data() as Map<String, dynamic>;
        double currentTotal = (accountData['totalBalance'] ?? 0).toDouble();
        Map<String, double> breakdown = Map<String, double>.from(
          (accountData['breakdown'] ?? {}).map((key, value) => MapEntry(key, value.toDouble())),
        );

        String owner = 'Self';
        double ownerBalance = breakdown[owner] ?? 0;

        TransactionType transType;
        if (loan.type == LoanType.given) {
          // Receiving money back (Income)
          currentTotal += paymentAmount;
          ownerBalance += paymentAmount;
          transType = TransactionType.income;
        } else {
          // Paying money back (Expense)
          currentTotal -= paymentAmount;
          ownerBalance -= paymentAmount;
          transType = TransactionType.expense;
        }

        breakdown[owner] = ownerBalance;

        tx.update(accountRef, {
          'totalBalance': currentTotal,
          'breakdown': breakdown,
        });

        // Record the transaction
        final transRef = _db.collection('transactions').doc();
        final transaction = TransactionModel(
          id: transRef.id,
          accountId: linkedAccountId,
          accountName: linkedAccountName,
          owner: owner,
          amount: paymentAmount,
          type: transType,
          category: loan.type == LoanType.given ? 'Loan Repayment Received' : 'Loan Repayment Paid',
          note: 'Repayment from/to ${loan.personName}',
          date: DateTime.now(),
          userId: _uid!,
        );
        tx.set(transRef, transaction.toFirestore());
      }
    });
  }

  // Get stream of all loans
  Stream<List<LoanModel>> getLoans() {
    if (_uid == null) return Stream.value([]);

    return _db
        .collection('loans')
        .where('userId', isEqualTo: _uid)
        .snapshots()
        .map((snapshot) {
      var list = snapshot.docs.map((doc) => LoanModel.fromFirestore(doc)).toList();
      // Sort locally to bypass Firebase composite index requirements
      list.sort((a, b) => b.date.compareTo(a.date));
      return list;
    });
  }
}
