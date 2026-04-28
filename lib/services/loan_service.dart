import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pocketledger/models/loan_model.dart';
import 'package:pocketledger/models/transaction_model.dart';

class LoanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String? _uid = FirebaseAuth.instance.currentUser?.uid;

  // Add a new loan
  Future<void> addLoan(LoanModel loan) async {
    if (_uid == null) return;

    final loanRef = _db.collection('loans').doc();
    await _db.runTransaction((transaction) async {
      // 1. Save Loan Document
      transaction.set(loanRef, loan.toFirestore()..addAll({'userId': _uid}));

      // 2. Adjust Linked Account Balance if provided
      if (loan.linkedAccountId != null) {
        final accountRef = _db.collection('accounts').doc(loan.linkedAccountId);
        final accountDoc = await transaction.get(accountRef);
        
        if (accountDoc.exists) {
          final accountData = accountDoc.data() as Map<String, dynamic>;
          double currentTotal = (accountData['totalBalance'] ?? 0).toDouble();
          Map<String, double> breakdown = Map<String, double>.from(
            (accountData['breakdown'] ?? {}).map((key, value) => MapEntry(key, value.toDouble())),
          );

          double ownerBalance = breakdown[loan.owner] ?? 0;

          if (loan.type == LoanType.taken) {
            // Taking loan adds money to account
            currentTotal += loan.amount;
            ownerBalance += loan.amount;
          } else {
            // Giving loan subtracts money from account
            currentTotal -= loan.amount;
            ownerBalance -= loan.amount;
          }

          breakdown[loan.owner] = ownerBalance;

          transaction.update(accountRef, {
            'totalBalance': currentTotal,
            'breakdown': breakdown,
          });

          // 3. Add initial transaction record
          final transRef = _db.collection('transactions').doc();
          transaction.set(transRef, TransactionModel(
            id: transRef.id,
            accountId: loan.linkedAccountId!,
            accountName: loan.linkedAccountName ?? 'Account',
            owner: loan.owner,
            amount: loan.amount,
            type: loan.type == LoanType.taken ? TransactionType.income : TransactionType.expense,
            category: 'Loan (${loan.type == LoanType.taken ? 'Taken' : 'Given'})',
            note: 'Loan with ${loan.personName}',
            date: loan.date,
            userId: _uid!,
            loanId: loanRef.id,
          ).toFirestore());
        }
      }
    });
  }

  // Add a repayment (Two-way transfer)
  Future<void> addRepayment({
    required String loanId,
    required double paymentAmount,
    String? sourceAccountId,
    String? sourceAccountName,
    String sourceOwner = 'Self',
    String? destAccountId,
    String? destAccountName,
    String? destOwner,
    String note = '',
  }) async {
    if (_uid == null) return;

    await _db.runTransaction((tx) async {
      final loanRef = _db.collection('loans').doc(loanId);
      final loanDoc = await tx.get(loanRef);
      if (!loanDoc.exists) return;

      final loan = LoanModel.fromFirestore(loanDoc);
      final repaymentId = DateTime.now().millisecondsSinceEpoch.toString();
      
      final repayment = RepaymentModel(
        id: repaymentId,
        amount: paymentAmount,
        date: DateTime.now(),
        note: note,
        sourceAccountId: sourceAccountId,
        sourceAccountName: sourceAccountName,
        sourceOwner: sourceOwner,
        destAccountId: destAccountId,
        destAccountName: destAccountName,
        destOwner: destOwner,
      );

      // 1. UPDATE LOAN RECORD
      List<RepaymentModel> newRepayments = List.from(loan.repayments)..add(repayment);
      double newRemaining = loan.remainingAmount - paymentAmount;
      
      tx.update(loanRef, {
        'repayments': newRepayments.map((r) => r.toMap()).toList(),
        'remainingAmount': newRemaining,
        'status': newRemaining <= 0 ? 'paid' : 'pending',
      });

      // 2. ADJUST SOURCE ACCOUNT (Where money is coming from, e.g. My Bank)
      if (sourceAccountId != null && sourceAccountName != null) {
        final accountRef = _db.collection('accounts').doc(sourceAccountId);
        final accountDoc = await tx.get(accountRef);
        if (accountDoc.exists) {
          final accountData = accountDoc.data() as Map<String, dynamic>;
          double currentTotal = (accountData['totalBalance'] ?? 0).toDouble();
          Map<String, double> breakdown = Map<String, double>.from(
            (accountData['breakdown'] ?? {}).map((key, value) => MapEntry(key, value.toDouble())),
          );

          double ownerBalance = breakdown[sourceOwner] ?? 0;

          // Deduct from source
          currentTotal -= paymentAmount;
          ownerBalance -= paymentAmount;
          breakdown[sourceOwner] = ownerBalance;

          tx.update(accountRef, {
            'totalBalance': currentTotal,
            'breakdown': breakdown,
          });

          // Record Transaction for Source
          final transRef = _db.collection('transactions').doc();
          tx.set(transRef, TransactionModel(
            id: transRef.id,
            accountId: sourceAccountId,
            accountName: sourceAccountName,
            owner: sourceOwner,
            amount: paymentAmount,
            type: TransactionType.expense,
            category: 'Loan Repayment (Sent)',
            note: 'Paid to ${loan.personName} from $sourceOwner portion',
            date: DateTime.now(),
            userId: _uid!,
            loanId: loanId,
            repaymentId: repaymentId,
          ).toFirestore());
        }
      }

      // 3. ADJUST DESTINATION ACCOUNT (Where money is going back to, e.g. Mother's bKash)
      if (destAccountId != null && destAccountName != null) {
        final accountRef = _db.collection('accounts').doc(destAccountId);
        final accountDoc = await tx.get(accountRef);
        if (accountDoc.exists) {
          final accountData = accountDoc.data() as Map<String, dynamic>;
          double currentTotal = (accountData['totalBalance'] ?? 0).toDouble();
          Map<String, double> breakdown = Map<String, double>.from(
            (accountData['breakdown'] ?? {}).map((key, value) => MapEntry(key, value.toDouble())),
          );

          String owner = destOwner ?? loan.personName; 
          double ownerBalance = breakdown[owner] ?? 0;

          // Add back to destination
          currentTotal += paymentAmount;
          ownerBalance += paymentAmount;
          breakdown[owner] = ownerBalance;

          tx.update(accountRef, {
            'totalBalance': currentTotal,
            'breakdown': breakdown,
          });

          // Record Transaction for Destination
          final transRef = _db.collection('transactions').doc();
          tx.set(transRef, TransactionModel(
            id: transRef.id,
            accountId: destAccountId,
            accountName: destAccountName,
            owner: owner,
            amount: paymentAmount,
            type: TransactionType.income,
            category: 'Loan Repayment (Received)',
            note: 'Received back into $owner portion',
            date: DateTime.now(),
            userId: _uid!,
            loanId: loanId,
            repaymentId: repaymentId,
          ).toFirestore());
        }
      }
    });
  }

  // Get stream of all loans
  Stream<List<LoanModel>> getLoans() {
    if (_uid == null) return Stream.value([]);

    return _db
        .collection('loans')
        .where('userId', isEqualTo: _uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => LoanModel.fromFirestore(doc)).toList();
    });
  }

  // DELETE A FULL LOAN (AND REVERT BALANCES)
  Future<void> deleteLoan(LoanModel loan) async {
    await _db.runTransaction((tx) async {
      if (loan.linkedAccountId != null) {
        final accRef = _db.collection('accounts').doc(loan.linkedAccountId);
        final accSnap = await tx.get(accRef);
        
        if (accSnap.exists) {
          final data = accSnap.data() as Map<String, dynamic>;
          Map<String, double> breakdown = Map<String, double>.from(
            (data['breakdown'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
          );
          
          double ownerBalance = breakdown[loan.owner] ?? 0;
          double totalBalance = (data['totalBalance'] ?? 0).toDouble();
          
          if (loan.type == LoanType.taken) {
            ownerBalance -= loan.amount;
            totalBalance -= loan.amount;
          } else {
            ownerBalance += loan.amount;
            totalBalance += loan.amount;
          }
          
          breakdown[loan.owner] = ownerBalance;
          tx.update(accRef, {
            'breakdown': breakdown,
            'totalBalance': totalBalance,
          });
        }
      }

      for (var rep in loan.repayments) {
        if (rep.sourceAccountId != null) {
          final srcRef = _db.collection('accounts').doc(rep.sourceAccountId);
          final srcSnap = await tx.get(srcRef);
          if (srcSnap.exists) {
            final data = srcSnap.data() as Map<String, dynamic>;
            Map<String, double> bd = Map<String, double>.from((data['breakdown'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())));
            double tot = (data['totalBalance'] ?? 0).toDouble();
            bd[rep.sourceOwner] = (bd[rep.sourceOwner] ?? 0) + rep.amount;
            tx.update(srcRef, {'breakdown': bd, 'totalBalance': tot + rep.amount});
          }
        }
        if (rep.destAccountId != null) {
          final dstRef = _db.collection('accounts').doc(rep.destAccountId);
          final dstSnap = await tx.get(dstRef);
          if (dstSnap.exists) {
            final data = dstSnap.data() as Map<String, dynamic>;
            Map<String, double> bd = Map<String, double>.from((data['breakdown'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())));
            double tot = (data['totalBalance'] ?? 0).toDouble();
            bd[rep.destOwner ?? 'Other'] = (bd[rep.destOwner ?? 'Other'] ?? 0) - rep.amount;
            tx.update(dstRef, {'breakdown': bd, 'totalBalance': tot - rep.amount});
          }
        }
      }

      final transQuery = await _db.collection('transactions').where('loanId', isEqualTo: loan.id).get();
      for (var doc in transQuery.docs) {
        tx.delete(doc.reference);
      }

      tx.delete(_db.collection('loans').doc(loan.id));
    });
  }

  // DELETE A SINGLE REPAYMENT
  Future<void> deleteRepayment(String loanId, RepaymentModel repayment) async {
    await _db.runTransaction((tx) async {
      final loanRef = _db.collection('loans').doc(loanId);
      final loanSnap = await tx.get(loanRef);
      if (!loanSnap.exists) return;
      
      final loan = LoanModel.fromFirestore(loanSnap);
      
      if (repayment.sourceAccountId != null) {
        final srcRef = _db.collection('accounts').doc(repayment.sourceAccountId);
        final srcSnap = await tx.get(srcRef);
        if (srcSnap.exists) {
          final data = srcSnap.data() as Map<String, dynamic>;
          Map<String, double> bd = Map<String, double>.from((data['breakdown'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())));
          double tot = (data['totalBalance'] ?? 0).toDouble();
          bd[repayment.sourceOwner] = (bd[repayment.sourceOwner] ?? 0) + repayment.amount;
          tx.update(srcRef, {'breakdown': bd, 'totalBalance': tot + repayment.amount});
        }
      }

      if (repayment.destAccountId != null) {
        final dstRef = _db.collection('accounts').doc(repayment.destAccountId);
        final dstSnap = await tx.get(dstRef);
        if (dstSnap.exists) {
          final data = dstSnap.data() as Map<String, dynamic>;
          Map<String, double> bd = Map<String, double>.from((data['breakdown'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())));
          double tot = (data['totalBalance'] ?? 0).toDouble();
          bd[repayment.destOwner ?? 'Other'] = (bd[repayment.destOwner ?? 'Other'] ?? 0) - repayment.amount;
          tx.update(dstRef, {'breakdown': bd, 'totalBalance': tot - repayment.amount});
        }
      }

      List<RepaymentModel> reps = List.from(loan.repayments);
      reps.removeWhere((r) => r.id == repayment.id);
      double newRemaining = loan.remainingAmount + repayment.amount;
      
      tx.update(loanRef, {
        'repayments': reps.map((r) => r.toMap()).toList(),
        'remainingAmount': newRemaining,
        'status': newRemaining <= 0 ? 'paid' : 'pending',
      });

      final transQuery = await _db.collection('transactions').where('repaymentId', isEqualTo: repayment.id).get();
      for (var doc in transQuery.docs) {
        tx.delete(doc.reference);
      }
    });
  }
}
