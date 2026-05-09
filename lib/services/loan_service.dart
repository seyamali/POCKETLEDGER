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

      // To handle cases where source and destination might be the same account,
      // we track changes in memory first.
      Map<String, _AccountUpdate> accountUpdates = {};

      // 2. PREPARE SOURCE ACCOUNT UPDATE (Deduction)
      if (sourceAccountId != null && sourceAccountName != null) {
        accountUpdates[sourceAccountId] = _AccountUpdate(
          accountId: sourceAccountId,
          accountName: sourceAccountName,
          amountChange: -paymentAmount,
          owner: sourceOwner,
          isExpense: true,
          category: 'Loan Repayment (Sent)',
          note: 'Paid to ${loan.personName} from $sourceOwner portion',
        );
      }

      // 3. PREPARE DESTINATION ACCOUNT UPDATE (Addition)
      if (destAccountId != null && destAccountName != null) {
        String owner = destOwner ?? loan.personName;
        if (accountUpdates.containsKey(destAccountId)) {
          // Same account! Merge updates
          var existing = accountUpdates[destAccountId]!;
          accountUpdates[destAccountId] = _AccountUpdate(
            accountId: destAccountId,
            accountName: destAccountName,
            amountChange: existing.amountChange + paymentAmount,
            ownerChanges: {
              existing.owner ?? 'Other': existing.amountChange,
              owner: (accountUpdates[destAccountId]?.ownerChanges?[owner] ?? 0) + paymentAmount,
            },
            isExpense: false,
            category: 'Loan Repayment (Received)',
            note: 'Received back into $owner portion',
          );
        } else {
          accountUpdates[destAccountId] = _AccountUpdate(
            accountId: destAccountId,
            accountName: destAccountName,
            amountChange: paymentAmount,
            owner: owner,
            isExpense: false,
            category: 'Loan Repayment (Received)',
            note: 'Received back into $owner portion',
          );
        }
      }

      // 4. APPLY CONSOLIDATED UPDATES
      for (var entry in accountUpdates.entries) {
        final accId = entry.key;
        final update = entry.value;
        final accRef = _db.collection('accounts').doc(accId);
        final accDoc = await tx.get(accRef);
        
        if (accDoc.exists) {
          final data = accDoc.data() as Map<String, dynamic>;
          double totalBalance = (data['totalBalance'] ?? 0).toDouble();
          Map<String, double> breakdown = Map<String, double>.from(
            (data['breakdown'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
          );

          // Apply changes to total
          totalBalance += update.amountChange;

          // Apply changes to owners
          if (update.ownerChanges != null) {
            update.ownerChanges!.forEach((owner, change) {
              breakdown[owner] = (breakdown[owner] ?? 0) + change;
            });
          } else if (update.owner != null) {
            breakdown[update.owner!] = (breakdown[update.owner!] ?? 0) + update.amountChange;
          }

          tx.update(accRef, {
            'totalBalance': totalBalance,
            'breakdown': breakdown,
          });
        }
      }

      // 5. RECORD SEPARATE TRANSACTIONS
      if (sourceAccountId != null && sourceAccountName != null) {
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

      if (destAccountId != null && destAccountName != null) {
        final transRef = _db.collection('transactions').doc();
        tx.set(transRef, TransactionModel(
          id: transRef.id,
          accountId: destAccountId,
          accountName: destAccountName,
          owner: destOwner ?? loan.personName,
          amount: paymentAmount,
          type: TransactionType.income,
          category: 'Loan Repayment (Received)',
          note: 'Received back into ${destOwner ?? loan.personName} portion',
          date: DateTime.now(),
          userId: _uid!,
          loanId: loanId,
          repaymentId: repaymentId,
        ).toFirestore());
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
    if (_uid == null) return;

    // 1. Fetch transactions OUTSIDE the transaction (Queries not allowed inside)
    final transQuery = await _db.collection('transactions')
        .where('userId', isEqualTo: _uid)
        .where('loanId', isEqualTo: loan.id)
        .get();
    final transDocRefs = transQuery.docs.map((d) => d.reference).toList();

    await _db.runTransaction((tx) async {
      // Track consolidated changes for accounts
      Map<String, double> totalChanges = {};
      Map<String, Map<String, double>> ownerChanges = {};

      // 1. Revert Initial Loan Balance
      if (loan.linkedAccountId != null) {
        final id = loan.linkedAccountId!;
        double change = 0;
        if (loan.type == LoanType.taken) {
          change = -loan.amount; 
        } else {
          change = loan.amount; 
        }
        
        totalChanges[id] = (totalChanges[id] ?? 0) + change;
        ownerChanges[id] ??= {};
        ownerChanges[id]![loan.owner] = (ownerChanges[id]![loan.owner] ?? 0) + change;
      }

      // 2. Revert All Repayments
      for (var rep in loan.repayments) {
        if (rep.sourceAccountId != null) {
          final id = rep.sourceAccountId!;
          totalChanges[id] = (totalChanges[id] ?? 0) + rep.amount; 
          ownerChanges[id] ??= {};
          ownerChanges[id]![rep.sourceOwner] = (ownerChanges[id]![rep.sourceOwner] ?? 0) + rep.amount;
        }
        if (rep.destAccountId != null) {
          final id = rep.destAccountId!;
          totalChanges[id] = (totalChanges[id] ?? 0) - rep.amount; 
          ownerChanges[id] ??= {};
          String owner = rep.destOwner ?? 'Other';
          ownerChanges[id]![owner] = (ownerChanges[id]![owner] ?? 0) - rep.amount;
        }
      }

      // 3. Apply consolidated updates to accounts
      for (var accId in totalChanges.keys) {
        final accRef = _db.collection('accounts').doc(accId);
        final accSnap = await tx.get(accRef);
        if (accSnap.exists) {
          final data = accSnap.data() as Map<String, dynamic>;
          double tot = (data['totalBalance'] ?? 0).toDouble();
          Map<String, double> bd = Map<String, double>.from(
            (data['breakdown'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
          );

          tot += totalChanges[accId]!;
          ownerChanges[accId]!.forEach((owner, change) {
            bd[owner] = (bd[owner] ?? 0) + change;
          });

          tx.update(accRef, {'breakdown': bd, 'totalBalance': tot});
        }
      }

      // 4. Delete associated transactions (using pre-fetched refs)
      for (var ref in transDocRefs) {
        tx.delete(ref);
      }

      // 5. Delete the Loan itself
      tx.delete(_db.collection('loans').doc(loan.id));
    });
  }

  // DELETE A SINGLE REPAYMENT
  Future<void> deleteRepayment(String loanId, RepaymentModel repayment) async {
    if (_uid == null) return;

    // 1. Fetch transactions OUTSIDE the transaction (Queries not allowed inside)
    final transQuery = await _db.collection('transactions')
        .where('userId', isEqualTo: _uid)
        .where('repaymentId', isEqualTo: repayment.id)
        .get();
    final transDocRefs = transQuery.docs.map((d) => d.reference).toList();

    await _db.runTransaction((tx) async {
      final loanRef = _db.collection('loans').doc(loanId);
      final loanSnap = await tx.get(loanRef);
      if (!loanSnap.exists) return;
      
      final loan = LoanModel.fromFirestore(loanSnap);
      
      // Track consolidated changes for accounts
      Map<String, double> totalChanges = {};
      Map<String, Map<String, double>> ownerChanges = {};

      if (repayment.sourceAccountId != null) {
        final id = repayment.sourceAccountId!;
        totalChanges[id] = (totalChanges[id] ?? 0) + repayment.amount;
        ownerChanges[id] ??= {};
        ownerChanges[id]![repayment.sourceOwner] = (ownerChanges[id]![repayment.sourceOwner] ?? 0) + repayment.amount;
      }

      if (repayment.destAccountId != null) {
        final id = repayment.destAccountId!;
        totalChanges[id] = (totalChanges[id] ?? 0) - repayment.amount;
        ownerChanges[id] ??= {};
        String owner = repayment.destOwner ?? 'Other';
        ownerChanges[id]![owner] = (ownerChanges[id]![owner] ?? 0) - repayment.amount;
      }

      // Apply consolidated updates to accounts
      for (var accId in totalChanges.keys) {
        final accRef = _db.collection('accounts').doc(accId);
        final accSnap = await tx.get(accRef);
        if (accSnap.exists) {
          final data = accSnap.data() as Map<String, dynamic>;
          double tot = (data['totalBalance'] ?? 0).toDouble();
          Map<String, double> bd = Map<String, double>.from(
            (data['breakdown'] ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
          );

          tot += totalChanges[accId]!;
          ownerChanges[accId]!.forEach((owner, change) {
            bd[owner] = (bd[owner] ?? 0) + change;
          });

          tx.update(accRef, {'breakdown': bd, 'totalBalance': tot});
        }
      }

      // Update Loan record
      List<RepaymentModel> reps = List.from(loan.repayments);
      reps.removeWhere((r) => r.id == repayment.id);
      double newRemaining = loan.remainingAmount + repayment.amount;
      
      tx.update(loanRef, {
        'repayments': reps.map((r) => r.toMap()).toList(),
        'remainingAmount': newRemaining,
        'status': newRemaining <= 0 ? 'paid' : 'pending',
      });

      // Delete associated transactions (using pre-fetched refs)
      for (var ref in transDocRefs) {
        tx.delete(ref);
      }
    });
  }

  // Update a loan's person name to fix typos/merge
  Future<void> updateLoanPersonName(String loanId, String newName) async {
    await _db.collection('loans').doc(loanId).update({'personName': newName});
  }
}

// Internal helper for consolidated updates
class _AccountUpdate {
  final String accountId;
  final String accountName;
  final double amountChange;
  final String? owner;
  final Map<String, double>? ownerChanges;
  final bool isExpense;
  final String category;
  final String note;

  _AccountUpdate({
    required this.accountId,
    required this.accountName,
    required this.amountChange,
    this.owner,
    this.ownerChanges,
    required this.isExpense,
    required this.category,
    required this.note,
  });
}
