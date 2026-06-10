import 'package:cloud_firestore/cloud_firestore.dart';

enum LoanType { given, taken }
enum LoanStatus { pending, paid }

class RepaymentModel {
  final String id;
  final double amount;
  final DateTime date;
  final String note;
  final String? sourceAccountId;
  final String? sourceAccountName;
  final String sourceOwner;
  final String? destAccountId;
  final String? destAccountName;
  final String? destOwner;

  RepaymentModel({
    required this.id,
    required this.amount,
    required this.date,
    this.note = '',
    this.sourceAccountId,
    this.sourceAccountName,
    this.sourceOwner = 'Self',
    this.destAccountId,
    this.destAccountName,
    this.destOwner,
  });

  factory RepaymentModel.fromMap(Map<String, dynamic> data) {
    return RepaymentModel(
      id: data['id'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] ?? '',
      sourceAccountId: data['sourceAccountId'],
      sourceAccountName: data['sourceAccountName'],
      sourceOwner: data['sourceOwner'] ?? 'Self',
      destAccountId: data['destAccountId'],
      destAccountName: data['destAccountName'],
      destOwner: data['destOwner'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'note': note,
      'sourceAccountId': sourceAccountId,
      'sourceAccountName': sourceAccountName,
      'sourceOwner': sourceOwner,
      'destAccountId': destAccountId,
      'destAccountName': destAccountName,
      'destOwner': destOwner,
    };
  }
}

class InstallmentModel {
  final String id;
  final double amount;
  final DateTime dueDate;
  final bool isPaid;
  final String? repaymentId;

  InstallmentModel({
    required this.id,
    required this.amount,
    required this.dueDate,
    this.isPaid = false,
    this.repaymentId,
  });

  factory InstallmentModel.fromMap(Map<String, dynamic> data) {
    return InstallmentModel(
      id: data['id'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      dueDate: (data['dueDate'] as Timestamp).toDate(),
      isPaid: data['isPaid'] ?? false,
      repaymentId: data['repaymentId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      'isPaid': isPaid,
      'repaymentId': repaymentId,
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
  final String? linkedAccountName;
  final String owner;
  final DateTime date;
  final String note;
  final String userId;
  final List<RepaymentModel> repayments;
  final List<InstallmentModel> installments;
  final double interestAmount;
  final double interestRate;
  final DateTime? dueDate;
  final String? personPhone;
  final List<String> attachmentUrls;
  final double penaltyRate;
  final bool isPenaltyActive;

  LoanModel({
    required this.id,
    required this.personName,
    required this.amount,
    required this.remainingAmount,
    required this.type,
    required this.status,
    this.linkedAccountId,
    this.linkedAccountName,
    this.owner = 'Self',
    required this.date,
    required this.note,
    required this.userId,
    this.repayments = const [],
    this.installments = const [],
    this.interestAmount = 0.0,
    this.interestRate = 0.0,
    this.dueDate,
    this.personPhone,
    this.attachmentUrls = const [],
    this.penaltyRate = 0.0,
    this.isPenaltyActive = false,
  });

  double get currentPenalty {
    if (!isPenaltyActive || dueDate == null || remainingAmount <= 0) return 0.0;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final due = DateTime(dueDate!.year, dueDate!.month, dueDate!.day);
    if (today.isAfter(due)) {
      return penaltyRate; // Flat fee penalty
    }
    return 0.0;
  }

  factory LoanModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    
    List<RepaymentModel> reps = [];
    if (data['repayments'] != null) {
      reps = (data['repayments'] as List).map((r) => RepaymentModel.fromMap(r)).toList();
    }

    List<InstallmentModel> insts = [];
    if (data['installments'] != null) {
      insts = (data['installments'] as List).map((i) => InstallmentModel.fromMap(i)).toList();
    }

    List<String> attachments = [];
    if (data['attachmentUrls'] != null) {
      attachments = List<String>.from(data['attachmentUrls']);
    }

    return LoanModel(
      id: doc.id,
      personName: data['personName'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      remainingAmount: (data['remainingAmount'] ?? 0).toDouble(),
      type: data['type'] == 'taken' ? LoanType.taken : LoanType.given,
      status: data['status'] == 'paid' ? LoanStatus.paid : LoanStatus.pending,
      linkedAccountId: data['linkedAccountId'],
      linkedAccountName: data['linkedAccountName'],
      owner: data['owner'] ?? 'Self',
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] ?? '',
      userId: data['userId'] ?? '',
      repayments: reps,
      installments: insts,
      interestAmount: (data['interestAmount'] ?? 0).toDouble(),
      interestRate: (data['interestRate'] ?? 0).toDouble(),
      dueDate: data['dueDate'] != null ? (data['dueDate'] as Timestamp).toDate() : null,
      personPhone: data['personPhone'],
      attachmentUrls: attachments,
      penaltyRate: (data['penaltyRate'] ?? 0).toDouble(),
      isPenaltyActive: data['isPenaltyActive'] ?? false,
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
      'linkedAccountName': linkedAccountName,
      'owner': owner,
      'date': Timestamp.fromDate(date),
      'note': note,
      'userId': userId,
      'repayments': repayments.map((r) => r.toMap()).toList(),
      'installments': installments.map((i) => i.toMap()).toList(),
      'interestAmount': interestAmount,
      'interestRate': interestRate,
      if (dueDate != null) 'dueDate': Timestamp.fromDate(dueDate!),
      'personPhone': personPhone,
      'attachmentUrls': attachmentUrls,
      'penaltyRate': penaltyRate,
      'isPenaltyActive': isPenaltyActive,
    };
  }
}
