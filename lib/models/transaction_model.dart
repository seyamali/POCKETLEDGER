import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pocketledger/core/constants/app_constants.dart';

enum TransactionType { income, expense, transfer, others }

class TransactionModel {
  final String id;
  final String accountId;
  final String accountName;
  final String owner; // Self, Father, Mother, Others
  final double amount;
  final TransactionType type;
  final String category;
  final String note;
  final DateTime date;
  final String userId;

  // For transfers
  final String? toAccountId;
  final String? toAccountName;
  final String? toOwner;

  // For loans
  final String? loanId;
  final String? repaymentId;

  TransactionModel({
    required this.id,
    required this.accountId,
    required this.accountName,
    required this.owner,
    required this.amount,
    required this.type,
    required this.category,
    required this.note,
    required this.date,
    required this.userId,
    this.toAccountId,
    this.toAccountName,
    this.toOwner,
    this.loanId,
    this.repaymentId,
  });

  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      accountId: data['accountId'] ?? '',
      accountName: data['accountName'] ?? '',
      owner: data['owner'] ?? AppConstants.ownerSelf,
      amount: (data['amount'] ?? 0).toDouble(),
      type: TransactionType.values.firstWhere(
        (e) => e.toString() == 'TransactionType.${data['type']}',
        orElse: () => TransactionType.expense,
      ),
      category: data['category'] ?? '',
      note: data['note'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      toAccountId: data['toAccountId'],
      toAccountName: data['toAccountName'],
      toOwner: data['toOwner'],
      loanId: data['loanId'],
      repaymentId: data['repaymentId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'accountId': accountId,
      'accountName': accountName,
      'owner': owner,
      'amount': amount,
      'type': type.toString().split('.').last,
      'category': category,
      'note': note,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'involvedAccountIds': [
        accountId,
        if (toAccountId != null) toAccountId,
      ],
      if (toAccountId != null) 'toAccountId': toAccountId,
      if (toAccountName != null) 'toAccountName': toAccountName,
      if (toOwner != null) 'toOwner': toOwner,
      if (loanId != null) 'loanId': loanId,
      if (repaymentId != null) 'repaymentId': repaymentId,
    };
  }
}
