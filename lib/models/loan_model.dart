import 'package:cloud_firestore/cloud_firestore.dart';

enum LoanType { given, taken }
enum LoanStatus { pending, paid }

class RepaymentModel {
  final String id;
  final double amount;
  final DateTime date;
  final String note;

  RepaymentModel({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
  });

  factory RepaymentModel.fromMap(Map<String, dynamic> data) {
    return RepaymentModel(
      id: data['id'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
    };
  }
}

class LoanModel {
  final String id;
  final String personName;
  final double amount;
  final double remainingAmount;
  final LoanType type;
  final LoanStatus status;
  final String? linkedAccountId;
  final DateTime date;
  final String note;
  final String userId;
  final List<RepaymentModel> repayments;

  LoanModel({
    required this.id,
    required this.personName,
    required this.amount,
    required this.remainingAmount,
    required this.type,
    required this.status,
    this.linkedAccountId,
    required this.date,
    required this.note,
    required this.userId,
    this.repayments = const [],
  });

  factory LoanModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    List<RepaymentModel> reps = [];
    if (data['repayments'] != null) {
      reps = (data['repayments'] as List).map((r) => RepaymentModel.fromMap(r)).toList();
    }

    return LoanModel(
      id: doc.id,
      personName: data['personName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      remainingAmount: (data['remainingAmount'] ?? 0).toDouble(),
      type: data['type'] == 'taken' ? LoanType.taken : LoanType.given,
      status: data['status'] == 'paid' ? LoanStatus.paid : LoanStatus.pending,
      linkedAccountId: data['linkedAccountId'],
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] ?? '',
      userId: data['userId'] ?? '',
      repayments: reps,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'personName': personName,
      'amount': amount,
      'remainingAmount': remainingAmount,
      'type': type == LoanType.taken ? 'taken' : 'given',
      'status': status == LoanStatus.paid ? 'paid' : 'pending',
      'linkedAccountId': linkedAccountId,
      'date': Timestamp.fromDate(date),
      'note': note,
      'userId': userId,
      'repayments': repayments.map((r) => r.toMap()).toList(),
    };
  }
}
